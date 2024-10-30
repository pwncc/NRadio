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

--CONFIG

local settings = {}

settings.CreateCameraListener = true;
settings.CreateCharacterSpeaker = true;

local settingsAllowed = {
    ["NoiseCancellation"] = false;
    ["Frequency"] = true;
}

local DefaultSettings = {
    ["Channel"] = 1;
    ["Gain"] = 1;
    ["NoiseCancellation"] = false;
    ["Squelch"] = 2;
    ["SquelchDelay"] = 0.05;
    ["Bandwidth"] = 12; -- kHz Affects audio quality.
    ["MaxDistance"] = 2500; -- studs affects radio's transmit range
    
    ["PTTKey"] = nil;
    ["PTTMouseKey"] = Enum.UserInputType.MouseButton1;
    ["HoldToTalk"] = true;
    ["IsTool"] = true;
    ["AllowDirectMicInput"] = true;

    ["Roger"] = true;
    ["RogerTone"] = "rbxassetid://18824040574";

    --Welding settings
    ["WeldOnUnequip"] = true;
    ["WeldUpperChestCFrameOffset"] = CFrame.new(0.454007149, -0.0891740322, -0.583068371, -0.17373541, 0.370353967, -0.912502408, -3.58452112e-08, 0.926590443, 0.376074344, 0.984796047, 0.065337114, -0.160981596)
}

local DefaultChannels = {
    [1] = {
        ["Name"] = "Comms";
        ["Frequency"] = 124651; -- 124.651 MHz
    },
    [2] = {
        ["Name"] = "CommsOffset";
        ["Frequency"] = 124653; -- 124.651 MHz
    },
    [3] = {
        ["Name"] = "Private";
        ["Frequency"] = 124751; -- 124.751 MHz
    }
}

settings.settingsAllowed = settingsAllowed;
settings.DefaultSettings = DefaultSettings;
settings.DefaultChannels = DefaultChannels;

return settings;