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