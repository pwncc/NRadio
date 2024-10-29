local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NRadioConfig = require(ReplicatedStorage.NRadio.NRadioConfig)
local NRadio = require(ReplicatedStorage.NRadio.NRadio)

local NRadioManager = {}
NRadioManager.__index = NRadioManager

local RADIO_TAG = "NRadio"

function NRadioManager.new()
    local self = setmetatable({}, NRadioManager)

    self.Radios = {}
    setmetatable(self.Radios, {__mode = "kv"})

    if NRadioConfig.CreateCameraListener then
        self.CameraListener = Instance.new("AudioListener", workspace.CurrentCamera)
        self.RadioListener = Instance.new("AudioListener", workspace.CurrentCamera)

        self.CameraListener.Name = "NRadioDefaultListener"
        self.RadioListener.Name = "NRadioRadioListener"

        self.RadioListener.AudioInteractionGroup = "Radio"

        self.AudioOut = Instance.new("AudioDeviceOutput", workspace.CurrentCamera)
        self.AudioOut.Player = game.Players.LocalPlayer

        self.OutputWire = Instance.new("Wire", workspace.CurrentCamera)
        self.OutputWire.TargetInstance = self.AudioOut
        self.OutputWire.SourceInstance = self.CameraListener

        self.RadioWire = Instance.new("Wire", workspace.CurrentCamera)
        self.RadioWire.TargetInstance = self.AudioOut
        self.RadioWire.SourceInstance = self.RadioListener
    end

    CollectionService:GetInstanceAddedSignal(RADIO_TAG):Connect(function(Radio)
        if Radio.Parent == game.StarterPack then
            return
        end

        self:OnRadioAdded(Radio)
    end)
    for _, Radio in CollectionService:GetTagged(RADIO_TAG) do
        if Radio.Parent == game.StarterPack then
            continue
        end

        self:OnRadioAdded(Radio)
    end

    return self
end

function NRadioManager:OnRadioAdded(Radio: Instance)
    self.Radios[Radio] = NRadio.new(self, Radio)
end

function NRadioManager:BindConnections()

end

function NRadioManager:OnCharacterAdded(Player: Player, Character: Model)
    
end

function NRadioManager:OnPlayerAdded(Player: Player)
    
end

return NRadioManager;