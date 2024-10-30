--[[
    NRadio System
    Copyright (C) 2023 Universe Games

    This program is free software: you can redistribute it and/or modify
    it under the terms of the following conditions:

    1. Redistributions of source code must retain the above copyright notice,
       this list of conditions and the following disclaimer.
    
    2. Redistributions in binary form must reproduce the above copyright notice, 
       this list of conditions and the following disclaimer in the documentation 
       and/or other materials provided with the distribution.

    3. Neither the name of Universe Games nor the names of its contributors may 
       be used to endorse or promote products derived from this software without
       specific prior written permission.

    4. Commercial use of this software, in whole or in part, is strictly prohibited
       without explicit written permission from Universe Games.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
    IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
    OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
    ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]


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