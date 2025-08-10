InitialClientStateEvent = {}
local InitialClientStateEvent_mt = Class(InitialClientStateEvent, Event)

InitEventClass(InitialClientStateEvent, "InitialClientStateEvent")

function InitialClientStateEvent.emptyNew()
    return Event.new(InitialClientStateEvent_mt)
end

function InitialClientStateEvent.new()
    return InitialClientStateEvent.emptyNew()
end

function InitialClientStateEvent:writeStream(streamId, connection)
    local dealCount = 0
    for _ in pairs(g_currentMission.LeasingOptions.leaseDeals) do dealCount = dealCount + 1 end
    streamWriteInt32(streamId, dealCount)

    for _, deal in pairs(g_currentMission.LeasingOptions.leaseDeals) do
        deal:writeStream(streamId, connection)
    end
end

function InitialClientStateEvent:readStream(streamId, connection)
    local dealCount = streamReadInt32(streamId)
    for i = 1, dealCount do
        local deal = LeaseDeal.new()
        deal:readStream(streamId, connection)
        g_currentMission.LeasingOptions:registerLeaseDeal(deal)
    end

    self:run(connection)
end

function InitialClientStateEvent:run(connection)
end
