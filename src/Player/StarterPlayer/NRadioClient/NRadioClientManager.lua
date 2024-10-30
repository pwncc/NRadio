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