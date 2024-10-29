local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local NRadioConfig = require(ReplicatedStorage.NRadio.NRadioConfig)
local Comm = require(ReplicatedStorage.NRadio.Packages.Comm)
local Signal = require(ReplicatedStorage.NRadio.Packages.Signal)
local NRadioFrequency = require(ReplicatedStorage.NRadio.NRadioFrequency)
local NView = require(ReplicatedStorage.NRadio.NView)

local defaultSettings = NRadioConfig.DefaultSettings
local defaultChannels = NRadioConfig.DefaultChannels

---@type NRadioServer
local NRadioServer = {}
NRadioServer.__index = NRadioServer

---@param RadioManager NRadioManager
function NRadioServer.new(RadioManager, Radio: Model | Tool)
    
    ---@class NRadioServer
    local self = setmetatable({}, NRadioServer)

    self.RadioManager = RadioManager
    self.Frequencies = {}

    self.IsTool = Radio:IsA("Tool")

    self.Destroying = Signal.new()

    self.Radio = Radio

    local Settings = Radio:WaitForChild("Settings") :: BasePart
    self.SpeakerPart = Radio:WaitForChild("SpeakerPart") :: BasePart
    self.MicrophonePart = Radio:WaitForChild("MicrophonePart") :: BasePart

    assert(Settings, "Settings not found")
    assert(self.SpeakerPart, "SpeakerPart not found")
    assert(self.MicrophonePart, "MicrophonePart not found")

    self.Settings = require(Settings)

    self.Comm = Comm.ServerComm.new(Radio)
    self.Comm:WrapMethod(self, "TogglePTT")
    self.Comm:WrapMethod(self, "SetChannelClient")
    self.Comm:WrapMethod(self, "SetProperty")
    self.View = NView.Get(Radio)

    self:SetupInstance()

    for _, radio in RadioManager.Radios do
        if radio ~= self then
            self:OnRadioAdded(radio)
        end
    end
    
    self.RadioManager.OnRadioAdded:Connect(function(radio)
        if radio ~= self then
            self:OnRadioAdded(radio)
        end
    end)

    return self
end

function NRadioServer:SetupInstance()
    for index, setting in defaultSettings do
        self.View[index] = setting
    end

    for index, setting in self.Settings do
        if index == "Channels" then
            continue
        end

        self.View[index] = setting
    end

    self.View.Channels = defaultChannels
    for index, channel in self.Settings.Channels do
        self.View.Channels[index] = channel
    end

    self.View.Transmitting = false

    --Setup listener
    self.Listener = Instance.new("AudioListener", self.MicrophonePart)
    self.InputFader = Instance.new("AudioFader", self.MicrophonePart)
    self.InputFader.Volume = self.View.Gain

    self.InternalInWire = Instance.new("Wire", self.MicrophonePart)
    self.InternalInWire.Name = "InternalIn"
    self.InternalInWire.SourceInstance = self.Listener
    self.InternalInWire.TargetInstance = self.InputFader

    self.Output = Instance.new("AudioEmitter", self.SpeakerPart)
    self.Output.Name = "Output"
    self.Output:SetDistanceAttenuation({[0]=1, [30]=0})
    self.Output.AudioInteractionGroup = "Radio"

    self.OutputFader = Instance.new("AudioFader", self.SpeakerPart)
    self.OutputFader.Volume = 1
    self.OutputFader.Name = "OutputFader"
    
    self.SquelchFader = Instance.new("AudioFader", self.SpeakerPart)
    self.SquelchFader.Volume = 0
    self.SquelchFader.Bypass = true

    self.SquelchFader.Name = "SquelchFader"

    self.InternalOutWire = Instance.new("Wire", self.SpeakerPart)
    self.InternalOutWire.Name = "InternalOut"
    self.InternalOutWire.SourceInstance = self.OutputFader
    self.InternalOutWire.TargetInstance = self.SquelchFader

    self:SetupStaticNoise()

    self.InternalStaticWire = Instance.new("Wire", self.SpeakerPart)
    self.InternalStaticWire.Name = "InternalStatic"
    self.InternalStaticWire.SourceInstance = self.StaticVolumePass
    self.InternalStaticWire.TargetInstance = self.OutputFader


    self.SquelchWire = Instance.new("Wire", self.SquelchFader)
    self.SquelchWire.Name = "SquelchWire"
    self.SquelchWire.SourceInstance = self.SquelchFader
    self.SquelchWire.TargetInstance = self.Output

    self.OutputFaderAnalyzer = Instance.new("AudioAnalyzer", self.SpeakerPart)
    self.AnalyzerWire = Instance.new("Wire", self.OutputFader)
    self.AnalyzerWire.Name = "AnalyzerWire"
    self.AnalyzerWire.SourceInstance = self.OutputFader
    self.AnalyzerWire.TargetInstance = self.OutputFaderAnalyzer

    self.RogerPlayer = Instance.new("AudioPlayer", self.SpeakerPart)
    self.RogerPlayer.Name = "Roger"
    self.RogerPlayer.AssetId = self.View.RogerTone
    self.RogerPlayer.Volume = 0.2
    self.RogerEmitter = Instance.new("AudioEmitter", self.SpeakerPart)
    self.RogerEmitter.Name = "RogerEmitter"
    self.RogerEmitter:SetDistanceAttenuation({[0]=1, [30]=0})

    if self.View.AllowDirectMicInput then
        self.DirectMicWire = Instance.new("Wire", self.MicrophonePart)
        self.DirectMicWire.Name = "DirectMicWire"
        self.DirectMicWire.SourceInstance = nil
        self.DirectMicWire.TargetInstance = self.InputFader
    end

    self.RogerWire = Instance.new("Wire", self.RogerEmitter)
    self.RogerWire.Name = "RogerWire"
    self.RogerWire.SourceInstance = nil
    self.RogerWire.TargetInstance = self.InputFader


    if self.IsTool then
        self.Radio.Equipped:Connect(function()
            self:OnEquipped()
        end)
        self.Radio.Unequipped:Connect(function()
            self:OnUnequipped()
        end)
    end

    self:SetChannel(1)

    RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end)
end

function NRadioServer:Update(dt)
    local minFrequency = math.huge
    local maxFrequency = 0
    local staticGain = 0
    
    if self.IsTool then
        self.View.Owner = game.Players:GetPlayerFromCharacter(self.Radio.Parent) or self.Radio.Parent.Parent
    end

    for _, frequency in pairs(self.Frequencies) do
        if not frequency.TransmittingRadio.View.Transmitting or not frequency.CanHear then
            continue
        end

        minFrequency = math.min(minFrequency, frequency.MinFrequency)
        maxFrequency = math.max(maxFrequency, frequency.MaxFrequency)

        if frequency.StaticGain < staticGain then
            staticGain = frequency.StaticGain
        end
    end
    
    if minFrequency == math.huge then
        minFrequency = 0
    end

    local midFrequency = (minFrequency + maxFrequency) / 2
    local bandwidth = midFrequency / (maxFrequency - minFrequency)

    self.StaticPeakFilter.Frequency = midFrequency
    self.StaticPeakFilter.Q = bandwidth

    self.StaticPeakFilter.Bypass = minFrequency == 0 and maxFrequency == 0

    local staticVolume = 1
    for _, frequency in pairs(self.Frequencies) do
        if not frequency.TransmittingRadio.View.Transmitting or not frequency.CanHear then
            continue
        end

        if staticVolume > frequency.StaticVolume then
            staticVolume = frequency.StaticVolume
        end
    end

    if self.View.AllowDirectMicInput then
        local micSource = self.View.Owner and self.View.Owner:FindFirstChild("AudioDeviceInput")
        if micSource ~= self.DirectMicWire.SourceInstance then
            self.DirectMicWire.SourceInstance = micSource
        end
    end

    self.StaticVolumePass.Volume = staticVolume
    self.OutputFader.Volume = self.View.Gain
end

function NRadioServer:SetupStaticNoise()
    self.StaticStream = ReplicatedStorage.NRadio.Static
    self.StaticPeakFilter = Instance.new("AudioFilter", self.Output)
    self.StaticPeakFilter.FilterType = Enum.AudioFilterType.Peak
    self.StaticVolumePass = Instance.new("AudioFader", self.Output)
    self.StaticVolumePass.Name = "StaticVolumePass"

    self.StaticInWire = Instance.new("Wire", self.Output)
    self.StaticInWire.SourceInstance = self.StaticStream
    self.StaticInWire.TargetInstance = self.StaticPeakFilter

    self.FilterWire = Instance.new("Wire", self.Output)
    self.FilterWire.SourceInstance = self.StaticPeakFilter
    self.FilterWire.TargetInstance = self.StaticVolumePass
end

function NRadioServer:OnEquipped()
    self.PlayerOwner = game.Players:GetPlayerFromCharacter(self.Radio.Parent)
    if not self.TorsoModel then
        return
    end
    
    self.TorsoWeld:Destroy()
    for _, item in self.TorsoModel:GetChildren() do
        if item.Name == "Handle" then
            continue
        end
        
        item.Parent = self.Radio
    end
end

function NRadioServer:OnUnequipped()
    if self.PlayerOwner then
        self.BodyHandle = self.BodyHandle or self.Radio:FindFirstChild("BodyHandle")

        self.TorsoModel = self.TorsoModel or Instance.new("Model", self.PlayerOwner.Character)
        self.TorsoModel.Name = "Radio"

        for _, item in self.Radio:GetChildren() do
            if item.Name == "Handle" then
                continue
            end

            item.Parent = self.TorsoModel
        end

        self.TorsoModel.PrimaryPart = self.BodyHandle

        local CFOffset = self.View.WeldUpperChestCFrameOffset

        self.TorsoModel.BodyHandle.CFrame = self.PlayerOwner.Character.UpperTorso.CFrame:ToWorldSpace(CFOffset)

        self.TorsoWeld = Instance.new("WeldConstraint", self.TorsoModel.BodyHandle)
        self.TorsoWeld.Part0 = self.TorsoModel.BodyHandle
        self.TorsoWeld.Part1 = self.PlayerOwner.Character.UpperTorso
    end
end

function NRadioServer:SetChannelClient(player, channelNumber)
    self:SetChannel(channelNumber)
end

function NRadioServer:SetProperty(player, property, value)
    self.View[property] = value
end

function NRadioServer:SetChannel(channelNumber)
    self.View.Channel = channelNumber
    local channel = self.View.Channels[channelNumber]
    if channel then
        self.View.Frequency = channel.Frequency
    end
end

function NRadioServer:TogglePTT(player, state)
    if self.View.Roger and state == false then
        if self.waitRoutine then
            task.cancel(self.waitRoutine)
        end
        self.waitRoutine = task.spawn(function()
            self.RogerPlayer:Play()
            self.RogerPlayer.Ended:Wait()
            self.View.Transmitting = state
            self.InputFader.Volume = state and 1 or 0
            self.OutputFader.Volume = state and 0 or 1
        end)
        return
    elseif self.View.Roger and state == true then
        if self.waitRoutine then
            task.cancel(self.waitRoutine)
        end
        self.RogerPlayer:Stop()
    end
    self.View.Transmitting = state
    self.InputFader.Volume = state and 1 or 0
    self.OutputFader.Volume = state and 0 or 1
end

function NRadioServer:SetFrequency(frequency)
    self.View.Frequency = frequency
end

---Frequency logic

function NRadioServer:OnRadioAdded(Radio)
    local frequency = NRadioFrequency.new(self, Radio)
    self.Frequencies[Radio] = frequency
end

return NRadioServer