-- Event announcing the deal to clients
SettleEarlyEvent = {}
local SettleEarlyEvent_mt = Class(SettleEarlyEvent, Event)

InitEventClass(SettleEarlyEvent, "SettleEarlyEvent")

function SettleEarlyEvent.emptyNew()
    local self = Event.new(SettleEarlyEvent_mt)

    return self
end

function SettleEarlyEvent.new(id)
    local self = SettleEarlyEvent.emptyNew()
    self.id = id
    return self
end

function SettleEarlyEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.id)
end

function SettleEarlyEvent:readStream(streamId, connection)
    self.id = streamReadString(streamId)
    self:run(connection)
end

function SettleEarlyEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(SettleEarlyEvent.new(self.id))
    end

    -- Find matching lease deal and remove it from the list
    local leaseDeals = g_currentMission.LeasingOptions.leaseDeals
    for i, d in ipairs(leaseDeals) do
        if d.id == self.id then
            d:paySettlementCost()
            table.remove(leaseDeals, i)
            break
        end
    end
end
