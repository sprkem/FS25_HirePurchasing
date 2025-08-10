-- Event announcing the deal to clients
ObjectIdChangedEvent = {}
local ObjectIdChangedEvent_mt = Class(ObjectIdChangedEvent, Event)

InitEventClass(ObjectIdChangedEvent, "ObjectIdChangedEvent")

function ObjectIdChangedEvent.emptyNew()
    local self = Event.new(ObjectIdChangedEvent_mt)

    return self
end

function ObjectIdChangedEvent.new(oldId, newId)
    local self = ObjectIdChangedEvent.emptyNew()
    self.oldId = oldId
    self.newId = newId
    return self
end

function ObjectIdChangedEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.oldId)
    streamWriteInt32(streamId, self.newId)
end

function ObjectIdChangedEvent:readStream(streamId, connection)
    self.oldId = streamReadInt32(streamId)
    self.newId = streamReadInt32(streamId)
    self:run(connection)
end

function ObjectIdChangedEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(ObjectIdChangedEvent.new(self.oldId, self.newId))
    end

    for _, deal in g_currentMission.LeasingOptions.leaseDeals do
        if deal.objectId == self.oldId then
            deal.objectId = self.newId
        end
    end
end
