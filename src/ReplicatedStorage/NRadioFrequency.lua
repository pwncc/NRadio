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

local RunService = game:GetService("RunService")

---@type NRadioFrequency
local NRadioFrequency = {}

NRadioFrequency.__index = NRadioFrequency

local MAX_BANDWIDTH = 20000

---@param receivingRadio NRadioServer
---@param transmittingRadio NRadioServer
function NRadioFrequency.new(receivingRadio, transmittingRadio)
    ---@class NRadioFrequency
    local self = setmetatable({}, NRadioFrequency)

    self.ReceivingRadio = receivingRadio
    self.TransmittingRadio = transmittingRadio
    self.Frequency = transmittingRadio.View.Frequency
    self.MinFrequency = 0
    self.MaxFrequency = 0
    self.StaticVolume = 0
    self.StaticGain = 0

    self.CanHear = false

    self:SetupConnections()

    ---@type NRadioFrequency
    return self
end

function NRadioFrequency:SetupConnections()
    self.ChannelFolder = Instance.new("Folder", self.ReceivingRadio.SpeakerPart)
    self.ChannelFolder.Name = "Channel"

    self.InputFilter = Instance.new("AudioFilter", self.ChannelFolder)
    self.InputFilter.FilterType = Enum.AudioFilterType.Bandpass
    self.InputFilter.Name = "InputFilter"
    self.InputFilter.Bypass = true -- Temporarily disabled until we get a lower Q value or a new inputfilter

    self.BandwidthFilter = Instance.new("AudioFilter", self.ChannelFolder)
    self.BandwidthFilter.FilterType = Enum.AudioFilterType.LowShelf
    self.BandwidthFilter.Name = "BandwidthFilter"

    self.BandwidthFilter.Gain = -80

    self.PitchShifter = Instance.new("AudioPitchShifter", self.ChannelFolder)

    self.OutputFader = Instance.new("AudioFader", self.ChannelFolder)
    self.OutputFader.Volume = 0

    self.Wire = Instance.new("Wire", self.ChannelFolder)
    self.Wire.SourceInstance = self.BandwidthFilter
    self.Wire.TargetInstance = self.PitchShifter
    self.Wire.Name = "BandwidthPitch"

    self.PitchWire = Instance.new("Wire", self.ChannelFolder)
    self.PitchWire.SourceInstance = self.PitchShifter
    self.PitchWire.TargetInstance = self.OutputFader
    self.PitchWire.Name = "Pitch"

    self.InternalOutWire = Instance.new("Wire", self.ChannelFolder)
    self.InternalOutWire.SourceInstance = self.OutputFader
    self.InternalOutWire.TargetInstance = self.ReceivingRadio.OutputFader
    self.InternalOutWire.Name = "InternalOut"

    self.TransmittingWire = Instance.new("Wire", self.ChannelFolder)
    self.TransmittingWire.SourceInstance = self.TransmittingRadio.InputFader
    self.TransmittingWire.TargetInstance = self.InputFilter
    self.TransmittingWire.Name = "Transmitting"

    self.BandwidthWire = Instance.new("Wire", self.ChannelFolder)
    self.BandwidthWire.SourceInstance = self.InputFilter
    self.BandwidthWire.TargetInstance = self.BandwidthFilter
    self.BandwidthWire.Name = "Bandwidth"

    self.UpdateConnection = RunService.Heartbeat:Connect(function(dt)
        self:UpdateFrequency(self.ReceivingRadio.View.Frequency)
        self:UpdateMinMaxFrequency()
        self:UpdateVolume((self.ReceivingRadio.SpeakerPart.Position - self.TransmittingRadio.MicrophonePart.Position).Magnitude)
        self:HandleTransmission()
        self:UpdateBandwidth()
    end)

    self.ReceivingRadio.Destroying:Connect(function()
        self:Destroy()
    end)

    self.TransmittingRadio.Destroying:Connect(function()
        self:Destroy()
    end)
end

function NRadioFrequency:UpdateFrequency(newFrequency)
    self.Frequency = newFrequency
end

function NRadioFrequency:UpdateMinMaxFrequency()
    local offset = math.abs(self.TransmittingRadio.View.Frequency - self.Frequency)
    self.MinFrequency = self.Frequency - offset
    self.MaxFrequency = self.Frequency + offset
end

function NRadioFrequency:UpdateVolume(distance)
    local maxDistance = math.min(self.ReceivingRadio.View.MaxDistance, self.TransmittingRadio.View.MaxDistance)
    local volume = math.clamp(1 - (distance / maxDistance), 0, 1)
    self.OutputFader.Volume = volume * 2
    self.StaticVolume =  0.8 - (volume)

    self.StaticGain = -math.log10(1 + (9 * volume)) * 3
    
    if distance < 5 then
        self.StaticVolume = 0
    end
end

function NRadioFrequency:UpdateBandwidth()
    local bandwidth = self.ReceivingRadio.View.Bandwidth * 1000
    local lowestSoundHz = MAX_BANDWIDTH - bandwidth
    self.BandwidthFilter.Frequency = lowestSoundHz
end

function NRadioFrequency:HandleTransmission()
    local offset = math.abs(self.Frequency - self.TransmittingRadio.View.Frequency)
    if offset > self.ReceivingRadio.View.Bandwidth then
        self.OutputFader.Volume = 0
        self.CanHear = false
        return
    end

    self.CanHear = true

    local pitchShift = offset / self.ReceivingRadio.View.Bandwidth
    
    --Have the bandpass go in the middle of the frequency, offset by the frequency difference between the Radio.
    local frequencyOffset = self.TransmittingRadio.View.Frequency - self.Frequency
    local minFrequency = math.max(0, frequencyOffset)
    local maxFrequency = math.min(MAX_BANDWIDTH, MAX_BANDWIDTH + frequencyOffset)

    local midFrequency = (minFrequency + maxFrequency) / 2
    local bandwidth = midFrequency / (maxFrequency - minFrequency)

    self.InputFilter.Frequency = midFrequency
    self.InputFilter.Q = bandwidth

    self.PitchShifter.Pitch = 1 + pitchShift
end

function NRadioFrequency:Destroy()
    if self.UpdateConnection then
        self.UpdateConnection:Disconnect()
    end
    self.Wire:Destroy()
    self.PitchWire:Destroy()
    self.TransmittingWire:Destroy()
    self.InputFilter:Destroy()
    self.PitchShifter:Destroy()
    self.OutputFader:Destroy()
end

return NRadioFrequency