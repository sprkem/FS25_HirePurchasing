LeasingOptions = {}
LeasingOptions.dir = g_currentModDirectory

function LeasingOptions:loadMap()
    local newFinanceDialog = NewFinanceFrame.new(g_i18n)
    self.leaseDeals = {}

    g_gui:loadProfiles(LeasingOptions.dir .. "src/gui/guiProfiles.xml")

    g_gui:loadGui(LeasingOptions.dir .. "src/gui/NewFinanceFrame.xml", "newFinanceFrame", newFinanceDialog)
    g_currentMission.LeasingOptions = self
end

function LeasingOptions:onStartMission()
    print("LeasingOptions:onStartMission called")
end

function LeasingOptions:registerLeaseDeal(leaseDeal)
    -- Note currently used by load xml and on new leaseDeals
    table.insert(self.leaseDeals, leaseDeal)
end

function LeasingOptions:saveToXmlFile()
    if (not g_currentMission:getIsServer()) then return end

    local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory .. "/"
    if savegameFolderPath == nil then
        savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(),
            g_currentMission.missionInfo.savegameIndex .. "/")
    end

    local key = "leaseDeals";
    local xmlFile = createXMLFile(key, savegameFolderPath .. "leaseDeals.xml", key);

    local i = 0
    for _, deal in pairs(g_currentMission.LeasingOptions.leaseDeals) do
        local dealKey = string.format("%s.leaseDeals.deal(%d)", key, i)
        deal:saveToXmlFile(xmlFile, dealKey)
        i = i + 1
    end

    saveXMLFile(xmlFile);
    delete(xmlFile);
end

function LeasingOptions:loadFromXMLFile()
    if (not g_currentMission:getIsServer()) then return end

    local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory .. "/"
    if savegameFolderPath == nil then
        savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(),
            g_currentMission.missionInfo.savegameIndex .. "/")
    end

    local key = "leaseDeals";

    if fileExists(savegameFolderPath .. "tasklist.xml") then
        local xmlFile = loadXMLFile(key, savegameFolderPath .. "tasklist.xml");

        local i = 0
        while true do
            local groupKey = string.format(key .. ".leaseDeals.deal(%d)", i)
            if not hasXMLProperty(xmlFile, groupKey) then
                break
            end

            local deal = LeaseDeal.new()
            deal:loadFromXMLFile(xmlFile, groupKey)
            g_currentMission.LeasingOptions:registerLeaseDeal(deal)
            i = i + 1
        end
        delete(xmlFile)
    end
end

function LeasingOptions.periodChanged()
    local leaseDeals = g_currentMission.LeasingOptions.leaseDeals
    local completedDeals = {}
    for i, deal in ipairs(leaseDeals) do
        local ended = deal:processMonthly()
        if ended then table.insert(completedDeals, i) end
    end

    for _, index in pairs(completedDeals) do
        leaseDeals[index] = nil
    end
end

function LeasingOptions.onVehicleSellEvent()
    if g_currentMission.isExitingGame then
        return
    end

    local leaseDeals = g_currentMission.LeasingOptions.leaseDeals
    local removed = {}
    for i, deal in ipairs(leaseDeals) do
        if deal:getVehicle() == nil then
            deal:paySettlemenCost()
            table.insert(removed, i)
        end
    end

    for _, index in pairs(removed) do
        table.remove(leaseDeals, index)
    end
end

g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, LeasingOptions.periodChanged)
g_messageCenter:subscribe(MessageType.VEHICLE_REMOVED, LeasingOptions.onVehicleSellEvent)
FSBaseMission.onStartMission = Utils.prependedFunction(FSBaseMission.onStartMission, LeasingOptions.onStartMission)
addModEventListener(LeasingOptions)
