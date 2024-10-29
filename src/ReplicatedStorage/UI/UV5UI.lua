local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local NRadioUtil = require(ReplicatedStorage.NRadio.NRadioUtil)
---@type UV5UI
local UV5UI = {}
UV5UI.__index = UV5UI

local PRESET_UI = game.StarterGui.BaofengUI

local EDITABLE_SETTINGS = {
    {Setting="Squelch", ValueType= "number", Increment=0.2, Min=0, Max=20},
    {Setting="Gain", ValueType= "number", Increment=0.2, Min=0, Max=3},
    {Setting="Roger", ValueType= "boolean", DisplayTrue="On", DisplayFalse="Off"},
}

---@param Radio NRadio
function UV5UI.new(Radio)
    ---@class UV5UI
    local self = setmetatable({}, UV5UI)

    self.Connections = {}

    self.Radio = Radio
    self.RadioView = self.Radio.View

    self.InMenu = false
    self.MenuSelection = 1
    self.MenuSelectionSetting = nil

    self.EditingSetting = nil
    self.EditingSettingValue = nil

    self.VFOMode = "Channel"


    self.UI = PRESET_UI:Clone()
    self.UI.Parent = game.Players.LocalPlayer.PlayerGui

    self.MainFrame = self.UI.ImageLabel
    self.TextMain = self.MainFrame.TextMain

    self.TransceiverLED = self.MainFrame.TransceiverLED

    self.BtnOne = self.MainFrame["1"] :: TextButton
    self.BtnTwo = self.MainFrame["2"] :: TextButton
    self.BtnThree = self.MainFrame["3"] :: TextButton
    self.BtnFour = self.MainFrame["4"] :: TextButton
    self.BtnFive = self.MainFrame["5"] :: TextButton
    self.BtnSix = self.MainFrame["6"] :: TextButton
    self.BtnSeven = self.MainFrame["7"] :: TextButton
    self.BtnEight = self.MainFrame["8"] :: TextButton
    self.BtnNine = self.MainFrame["9"] :: TextButton
    self.BtnZero = self.MainFrame["0"] :: TextButton
    self.BtnStar = self.MainFrame["*"] :: TextButton
    self.BtnHash = self.MainFrame["#"] :: TextButton

    self.BtnMenu = self.MainFrame.Menu :: TextButton
    self.BtnUp = self.MainFrame.Up :: TextButton
    self.BtnDown = self.MainFrame.Down :: TextButton
    self.BtnExit = self.MainFrame.Exit :: TextButton

    self:BindConnections()

    self:DisplayChannel(self.RadioView.Channel)

    return self
end

function UV5UI:BindConnections()
    table.insert(self.Connections, self.BtnUp.MouseButton1Click:Connect(function() self:BtnUp_Click() end))
    table.insert(self.Connections, self.BtnDown.MouseButton1Click:Connect(function() self:BtnDown_Click() end))
    table.insert(self.Connections, self.BtnMenu.MouseButton1Click:Connect(function() self:BtnMenu_Click() end))
    table.insert(self.Connections, self.BtnExit.MouseButton1Click:Connect(function() self:BtnExit_Click() end))

    table.insert(self.Connections, RunService.Heartbeat:Connect(function(dt) self:Update(dt) end))
end

function UV5UI:Update(dt)
    local isReceiving = self.Radio.OutputFader.Volume > 0 and self.Radio.SquelchFader.Bypass == true
    local isTransmitting = self.RadioView.Transmitting

    if isReceiving then
        self.TransceiverLED.BackgroundColor3 = Color3.fromRGB(125, 255,125)
    elseif isTransmitting then
        self.TransceiverLED.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    else
        self.TransceiverLED.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end
end

function UV5UI:OnEquipped()
    self.UI.Enabled = true
end

function UV5UI:OnUnequipped()
    self.UI.Enabled = false
end

function UV5UI:NextChannel()
    local channels = self.RadioView.Channels
    local currentChannel = self.RadioView.Channel

    local nextChannel = channels[currentChannel + 1] and currentChannel + 1 or 1

    self.Radio:SetChannel(nextChannel)

    self:DisplayChannel(nextChannel)
end

function UV5UI:PreviousChannel()
    local channels = self.RadioView.Channels
    local currentChannel = self.RadioView.Channel

    local nextChannel = channels[currentChannel - 1] and currentChannel - 1 or #channels

    self.Radio:SetChannel(nextChannel)

    self:DisplayChannel(nextChannel)
end

function UV5UI:DisplayChannel(channel)
    local realChannel = self.RadioView.Channels[channel]

    --We use rich text to display the channel name and frequency
    self.TextMain.Text = "<font size='30'>" .. realChannel.Name .. "</font>\n<font size='15'>" .. NRadioUtil.FrequencyStringBeautify(realChannel.Frequency, true) .. "</font>"
end

--Buttons

function UV5UI:BtnMenu_Click()
    if self.EditingSetting then
        self.Radio.Server:SetProperty(self.EditingSetting.Setting, self.EditingSettingValue)
        self.EditingSetting = nil
        self.EditingSettingValue = nil

        self:DisplaySetting()
    elseif self.InMenu then
        self.EditingSetting = EDITABLE_SETTINGS[self.MenuSelection]
        self.EditingSettingValue = self.RadioView[self.EditingSetting.Setting]

        self:DisplayEditingSetting()
    else
        self.InMenu = true
        self.MenuSelection = 1
        self.MenuSelectionSetting = EDITABLE_SETTINGS[self.MenuSelection]

        self:DisplaySetting()
    end
end

function UV5UI:BtnExit_Click()
    if self.InMenu and not self.EditingSetting then
        self.InMenu = false
        self.MenuSelection = 1
        self.MenuSelectionSetting = EDITABLE_SETTINGS[self.MenuSelection]

        self:DisplayChannel(self.RadioView.Channel)
    elseif self.EditingSetting then
        self.EditingSetting = nil
        self.EditingSettingValue = nil

        self:DisplaySetting()
    end
end

function UV5UI:DisplaySetting()
    self.TextMain.Text = self.MenuSelectionSetting.Setting
end

function UV5UI:DisplayEditingSetting()
    if self.EditingSetting.ValueType == "number" then
        local incrementDigits = tostring(self.EditingSetting.Increment):match("%.(%d+)$")
        if incrementDigits then
            local formatString = "%." .. #incrementDigits .. "f"
            self.TextMain.Text = string.format(formatString, self.EditingSettingValue)
        else
            self.TextMain.Text = tostring(self.EditingSettingValue)
        end
    elseif self.EditingSetting.ValueType == "boolean" then
        self.TextMain.Text = self.EditingSettingValue and self.EditingSetting.DisplayTrue or self.EditingSetting.DisplayFalse
    else
        self.TextMain.Text = self.EditingSettingValue
    end
end

function UV5UI:NextMenuSelection()
    if self.InMenu then
        self.MenuSelection = EDITABLE_SETTINGS[self.MenuSelection + 1] and self.MenuSelection + 1 or 1
        self.MenuSelectionSetting = EDITABLE_SETTINGS[self.MenuSelection]

        self.TextMain.Text = self.MenuSelectionSetting.Setting
    end
end

function UV5UI:PreviousMenuSelection()
    if self.InMenu then
        self.MenuSelection = EDITABLE_SETTINGS[self.MenuSelection - 1] and self.MenuSelection - 1 or #EDITABLE_SETTINGS
        self.MenuSelectionSetting = EDITABLE_SETTINGS[self.MenuSelection]

        self.TextMain.Text = self.MenuSelectionSetting.Setting
    end
end

function UV5UI:IncrementSetting()
    if self.EditingSetting.ValueType == "number" then
        self.EditingSettingValue = self.EditingSettingValue + self.EditingSetting.Increment
        if self.EditingSettingValue > self.EditingSetting.Max then
            self.EditingSettingValue = self.EditingSetting.Min
        end
    elseif self.EditingSetting.ValueType == "boolean" then
        self.EditingSettingValue = not self.EditingSettingValue
    end

    self:DisplayEditingSetting()
end

function UV5UI:DecrementSetting()
    if self.EditingSetting.ValueType == "number" then
        self.EditingSettingValue = self.EditingSettingValue - self.EditingSetting.Increment
        if self.EditingSettingValue < self.EditingSetting.Min then
            self.EditingSettingValue = self.EditingSetting.Max
        end
    elseif self.EditingSetting.ValueType == "boolean" then
        self.EditingSettingValue = not self.EditingSettingValue
    end

    self:DisplayEditingSetting()
end

function UV5UI:BtnUp_Click()
    if self.VFOMode == "Channel" and not self.InMenu then
        self:NextChannel()
    elseif self.InMenu and not self.EditingSetting then
        self:NextMenuSelection()
    elseif self.EditingSetting then
        self:IncrementSetting()
    end
end

function UV5UI:BtnDown_Click()
    if self.VFOMode == "Channel" and not self.InMenu then
        self:PreviousChannel()
    elseif self.InMenu and not self.EditingSetting then
        self:PreviousMenuSelection()
    elseif self.EditingSetting then
        self:DecrementSetting()
    end
end

function UV5UI:Destroy()
    self.UI:Destroy()
end

return UV5UI