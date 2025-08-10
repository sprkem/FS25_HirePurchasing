-- Event announcing the deal to clients
NewLeaseDealEvent = {}
local NewLeaseDealEvent_mt = Class(NewLeaseDealEvent, Event)

InitEventClass(NewLeaseDealEvent, "NewLeaseDealEvent")

function NewLeaseDealEvent.emptyNew()
    local self = Event.new(NewLeaseDealEvent_mt)

    return self
end

function NewLeaseDealEvent.new(leaseDeal)
    local self = NewLeaseDealEvent.emptyNew()
    self.leaseDeal = leaseDeal
    return self
end

function NewLeaseDealEvent:writeStream(streamId, connection)
    self.leaseDeal:writeStream(streamId, connection)
end

function NewLeaseDealEvent:readStream(streamId, connection)
    self.leaseDeal = LeaseDeal.new()
    self.leaseDeal:readStream(streamId, connection)
    self:run(connection)
end

function NewLeaseDealEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(NewLeaseDealEvent.new(self.leaseDeal))
    end

    g_currentMission.LeasingOptions:registerLeaseDeal(self.leaseDeal)
    g_currentMission.LeasingOptions:checkObjectIds()
end
