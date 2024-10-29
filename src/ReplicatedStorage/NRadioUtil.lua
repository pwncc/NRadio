local NRadioUtil = {}

function NRadioUtil.FrequencyStringBeautify(frequency, addUnit)
    local unit = "KHz"
    local lowerUnit = ""
    local convertedFrequency = frequency

    if frequency >= 1000000 then
        convertedFrequency = frequency / 1000000
        unit = "GHz"
    elseif frequency >= 1000 then
        convertedFrequency = frequency / 1000
        unit = "MHz"
    end

    local frequencyString = string.format("%.3f", convertedFrequency)
    if addUnit then
        frequencyString = frequencyString .. " " .. unit
    end

    return frequencyString
end

return NRadioUtil