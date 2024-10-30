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