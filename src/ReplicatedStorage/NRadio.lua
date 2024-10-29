local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local NRadioConfig = require(ReplicatedStorage.NRadio.NRadioConfig)
local Comm = require(ReplicatedStorage.NRadio.Packages.Comm)
local NView = require(ReplicatedStorage.NRadio.NView)
local Signal = require(ReplicatedStorage.NRadio.Packages.Signal)

local defaultSettings = NRadioConfig.DefaultSettings
local defaultChannels = NRadioConfig.DefaultChannels
---@type NRadio
local NRadio = {}
NRadio.__index = NRadio

function NRadio.new(RadioManager, Radio: Model|Tool)
    ---@class NRadio
    local self = setmetatable({}, NRadio)

    self.IsTool = Radio:IsA("Tool")

    self.RadioManager = RadioManager
    self.RadioModel = Radio
    
    self.lastSquelch = tick() - 5

    local Settings = Radio:WaitForChild("Settings")
    local SpeakerPart = Radio:WaitForChild("SpeakerPart")
    local MicrophonePart = Radio:WaitForChild("MicrophonePart")

    assert(Settings, "Settings not found")
    assert(SpeakerPart, "SpeakerPart not found")
    assert(MicrophonePart, "MicrophonePart not found")

    self.Settings = require(Settings)

    self.View = NView.Get(Radio)
    
    self.Comm = Comm.ClientComm.new(Radio)
    self.Server = self.Comm:BuildObject()

    self.Output = SpeakerPart:WaitForChild("Output")
    self.OutputFader = SpeakerPart:WaitForChild("OutputFader")

    self.SquelchFader = SpeakerPart:WaitForChild("SquelchFader")
    self.OutputFaderAnalyzer = SpeakerPart:WaitForChild("AudioAnalyzer") :: AudioAnalyzer
    self.StaticVolumePass = SpeakerPart.Output:WaitForChild("StaticVolumePass") :: AudioFader

    self:BindConnections()

    Radio.Destroying:Connect(function() self:Destroy() end)

    return self
end

function NRadio:CheckIsMine()
    return self.RadioModel.Parent == game.Players.LocalPlayer.Character or self.RadioModel.Parent.Parent == game.Players.LocalPlayer
end

function NRadio:BindConnections()
    self.inputBeganConn = UserInputService.InputBegan:Connect(function(...) self:InputBegan(...) end)
    self.inputEndedConn = UserInputService.InputEnded:Connect(function(...) self:InputEnded(...) end)

    self.UpdateConn = RunService.Heartbeat:Connect(function(...) self:Update(...) end)

    if self.IsTool then
        self.EquipConn = self.RadioModel.Equipped:Connect(function() self:Equip() end)
        self.UnequipConn = self.RadioModel.Unequipped:Connect(function() self:Unequip() end)
    end
end

function NRadio:Update(dt)
    self:UpdateSquelch(dt)
end

function NRadio:UpdateSquelch()
    if self.View.Squelch == 0 then
        self.SquelchFader.Bypass = true
        return
    end

    local peakLevel = self.OutputFaderAnalyzer.RmsLevel
    peakLevel += (1 - self.StaticVolumePass.Volume) * 3
    local threshold = self.View.Squelch / 20
    self.SquelchFader.Bypass = peakLevel > threshold or tick() - self.lastSquelch < self.View.SquelchDelay

    if peakLevel > threshold then
        self.lastSquelch = tick()
    end
end

function NRadio:Equip()
    print("equipped")
    if not self:CheckIsMine() then return end
    if self.Settings.UIModule and not self.UIInstance then
        print("ui instance setup")
        self.UIInstance = require(self.Settings.UIModule).new(self)
    end

    if self.UIInstance then
        self.UIInstance:OnEquipped()
    end
end

function NRadio:Unequip()
    if not self:CheckIsMine() then return end
    if self.UIInstance then
        self.UIInstance:OnUnequipped()
    end
end

function NRadio:SetChannel(Channel : number)
    self.Server:SetChannelClient(Channel)
end

function NRadio:InputBegan(Input : InputObject, GameProcessedEvent : boolean)
    if GameProcessedEvent or not self:CheckIsMine() then return end

    if Input.KeyCode == self.View.PTTKey then
        self.Server:TogglePTT(true)
    end

    if Input.UserInputType == self.View.PTTMouseKey then
        self.Server:TogglePTT(true)
    end
end

function NRadio:InputEnded(Input : InputObject, GameProcessedEvent : boolean)
    if GameProcessedEvent or not self:CheckIsMine() then return end

    if Input.KeyCode == self.View.PTTKey then
        self.Server:TogglePTT(false)
    end
    if Input.UserInputType == self.View.PTTMouseKey then
        self.Server:TogglePTT(false)
    end
end

function NRadio:Destroy()
    if self.UpdateConn then
        self.UpdateConn:Disconnect()
    end
    if self.inputBeganConn then
        self.inputBeganConn:Disconnect()
    end
    if self.inputEndedConn then
        self.inputEndedConn:Disconnect()
    end
end

return NRadio