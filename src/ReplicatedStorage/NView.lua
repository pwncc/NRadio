local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
--[[
    Nview

    Nview is a class that allows for easy non-remote replication of data.
    Nview classes are created on the server and client, and are synced automatically.

]]

local IsServer = RunService:IsServer()
local DataLocation = game.ReplicatedStorage:FindFirstChild("NViews") or Instance.new("Folder", game.ReplicatedStorage)
DataLocation.Name = "NViews"

local NexusInstance = require(game.ReplicatedStorage.NRadio.NexusInstance.NexusInstance)
local NexusEvent = require(game.ReplicatedStorage.NRadio.NexusInstance.Event.NexusEvent)

---@class NView
local NView = NexusInstance:Extend()
NView:SetClassName("NView")

local IgnoreIndexTypes = {
    ["_viewdata"] = true;
    ["_indexTypes"] = true;
    ["_viewInstance"] = true;
    ["_dataChangedConnection"] = true;
    ["_destroyedConnection"] = true;
    ["OnViewDestroying"] = true;
    ["ValueChanged"] = true;
    ["Get"] = true;
}

local NViewCache = {} --Cache nviews so we dont make 2 on the same object

local function fromFullPath(path)
    local current = game
    for name in path:gmatch("[^%.]+") do
        current = current:WaitForChild(name)
    end
    return current
end


function NView.Get(dataInstance)
    if NViewCache[dataInstance] then
        return NViewCache[dataInstance]
    end

    return NView.new(dataInstance)
end

function NView:__new(dataInstance)
    NexusInstance.__new(self)

    self._viewdata = {}
    self._indexTypes = {}

    self.OnViewDestroying = NexusEvent.new()
    self.ValueChanged = NexusEvent.new()

    self._viewInstance = dataInstance

    local NViewID
    local setParent = false
    if not dataInstance or typeof(dataInstance) == "string" then
        NViewID = HttpService:GenerateGUID(false)
        dataInstance = Instance.new("Folder")
        dataInstance.Name = NViewID
        setParent = true

        if not IsServer then
            self._locallyCreated = true
        end
        self._viewInstance = dataInstance
    else
        if IsServer then
            for name in dataInstance:GetAttributes() do
                self:__PropertyValidator(name, dataInstance:GetAttribute(name))
            end

            if not dataInstance:GetAttribute("ViewID") then
                NViewID = HttpService:GenerateGUID(false)
            end
        else
            for name in dataInstance:GetAttributes() do
                self:__AttributeChanged(name)
            end
        end
    end

    if not IsServer and not self._locallyCreated then
        self._dataChangedConnection = self._viewInstance.AttributeChanged:Connect(function(attribute)
            self:__AttributeChanged(attribute)
        end)
    end

    self:AddGenericPropertyValidator(function(...) return self:__PropertyValidator(...) end)
    self:AddGenericPropertyGetter(function(...) return self:__PropertyGetter(...) end)

    if IsServer then
        self.ViewID = NViewID

        if setParent then
            dataInstance.Parent = game.ReplicatedStorage.NViews
        end
    end

    self._destroyedConnection = dataInstance.Destroying:Connect(function()
        self:Dispose()
    end)

    if NViewCache[dataInstance] then
        warn("Duplicate NView of "..dataInstance:GetFullName(), debug.traceback(nil, 2))
    else
        NViewCache[dataInstance] = self
    end
end

function NView:__PropertyValidator(Index, Value)
    if IgnoreIndexTypes[Index] then
        return Value
    end

    assert(IsServer or self.__InternalProperties._locallyCreated, "Cannot set properties on the client.")

    local viewdata = self.__InternalProperties._viewdata

    self.__InternalProperties._indexTypes[Index] = typeof(Value)
    self.__InternalProperties._viewInstance:SetAttribute("Types", HttpService:JSONEncode(self._indexTypes))

    if typeof(Value) == "table" then
        self.__InternalProperties._viewInstance:SetAttribute(Index, HttpService:JSONEncode(Value))
    elseif typeof(Value) == "Instance" then
        self.__InternalProperties._viewInstance:SetAttribute(Index, Value:GetFullName())
    else
        self.__InternalProperties._viewInstance:SetAttribute(Index, Value)
    end

    viewdata[Index] = Value

    return Value
end

function NView:__PropertyGetter(Index, Value)
    if IgnoreIndexTypes[Index] then
        return Value
    end
    local viewdata = self.__InternalProperties._viewdata

    Value = viewdata[Index]

    return Value
end

function NView:__AttributeChanged(AttribName)
    local viewdata = self.__InternalProperties._viewdata
    if AttribName == "Types" or self.__InternalProperties._indexTypes[AttribName] == nil then
        local types = self.__InternalProperties._viewInstance:GetAttribute("Types")
        if types then
            self.__InternalProperties._indexTypes = HttpService:JSONDecode(types)
        end
    end

    local lastValue = viewdata[AttribName]
    
    if AttribName ~= "Types" then
        if self.__InternalProperties._indexTypes[AttribName] == "table" then
            viewdata[AttribName] = HttpService:JSONDecode(self._viewInstance:GetAttribute(AttribName))
        elseif self.__InternalProperties._indexTypes[AttribName] == "Instance" then
            viewdata[AttribName] = fromFullPath(self._viewInstance:GetAttribute(AttribName))
        else
            viewdata[AttribName] = self._viewInstance:GetAttribute(AttribName)
        end
    end
    self.__InternalProperties.ValueChanged:Fire(AttribName, viewdata[AttribName], lastValue)
end

function NView:Dispose()
    self.OnViewDestroying:Fire()

    if self._dataChangedConnection then
        self._dataChangedConnection:Disconnect()
    end

    if self._destroyedConnection then
        self._destroyedConnection:Disconnect()
    end

    if self._viewInstance and self._viewInstance.Parent == DataLocation and IsServer then
        self._viewInstance:Destroy()
    end

    self:Destroy()
end

return NView
