local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NRadioConfig = require(ReplicatedStorage.NRadio.NRadioConfig)
local NRadioServer = require(ServerScriptService.NRadio.NRadioServer)
local Signal = require(ReplicatedStorage.NRadio.Packages.Signal)

---@class NRadioManager
local NRadioManager = {}
NRadioManager.__index = NRadioManager

local RADIO_TAG = "NRadio"

function NRadioManager.new()
    local self = setmetatable({}, NRadioManager)
    self.Radios = {}
    self.AudioInputDevices = {}
    self.InputSpeakers = {}

    setmetatable(self.Radios, {__mode = "kv"})
    setmetatable(self.AudioInputDevices, {__mode = "kv"})

    self:BindConnections()

    self.OnRadioAdded = Signal.new()

    for _, Radio in CollectionService:GetTagged(RADIO_TAG) do
        self:RadioAdded(Radio)
    end

    CollectionService:GetInstanceAddedSignal(RADIO_TAG):Connect(function(Radio)
        self:RadioAdded(Radio)
    end)

    ReplicatedStorage.NRadio.Static:Play()
    ReplicatedStorage.NRadio.Static.Looping = true

    return self
end

function NRadioManager:BindConnections()
    game.Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    for _, Player in game.Players:GetPlayers() do
        self:OnPlayerAdded(Player)
    end
end

function NRadioManager:RadioAdded(RadioInstance: Instance)
    if self.Radios[RadioInstance] then
        return
    end

    if RadioInstance.Parent == game.StarterPack then
        return
    end

    local newRadio = NRadioServer.new(self, RadioInstance)
    self.Radios[RadioInstance] = newRadio
    self.OnRadioAdded:Fire(newRadio)
end

function NRadioManager:OnCharacterAdded(Player: Player, Character: Character)
    if NRadioConfig.CreateCharacterSpeaker then
        local InputDevice = Player:FindFirstChild("AudioDeviceInput") or Instance.new("AudioDeviceInput", Player)
        InputDevice.Player = Player
        InputDevice:SetUserIdAccessList({Player})
        
        self.AudioInputDevices[Player] = InputDevice
        -- local Wire = InputDevice:FindFirstChild("Wire") or Instance.new("Wire", InputDevice)

        -- local Speaker = Instance.new("AudioEmitter", Character:WaitForChild("Head"))
        -- self.InputSpeakers[Player] = Speaker
        -- Speaker:SetDistanceAttenuation({[0]=1, [100]=0})
        

        -- Wire.TargetInstance = Speaker
        -- Wire.SourceInstance = InputDevice
    end
end

function NRadioManager:OnPlayerAdded(Player: Player)
    Player.CharacterAdded:Connect(function(Character)
        self:OnCharacterAdded(Player, Character)
    end)

    if Player.Character then
        self:OnCharacterAdded(Player, Player.Character)
    end
end


function NRadioManager:UpdateRadios(dt)
    
end

return NRadioManager;