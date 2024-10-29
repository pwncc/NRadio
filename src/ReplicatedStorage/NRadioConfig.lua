--[[
    NRadioConfig.lua
    All rights reserved, including unlawful distribution.
    Copyright Universe Games 2024
]]--

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