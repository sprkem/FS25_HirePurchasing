LeasingOptions = {}
LeasingOptions.dir = g_currentModDirectory

source(LeasingOptions.dir .. "src/gui/MenuFinanceList.lua")

function LeasingOptions:loadMap()
    local newFinanceDialog = NewFinanceFrame.new(g_i18n)
    self.leaseDeals = {}
    self.forceDeletes = {}

    g_gui:loadProfiles(LeasingOptions.dir .. "src/gui/guiProfiles.xml")

    g_gui:loadGui(LeasingOptions.dir .. "src/gui/NewFinanceFrame.xml", "newFinanceFrame", newFinanceDialog)

    local guiFinanceList = MenuFinanceList.new(g_i18n)
    g_gui:loadGui(LeasingOptions.dir .. "src/gui/MenuFinanceList.xml", "menuHirePurchasing", guiFinanceList, true)

    LeasingOptions.addIngameMenuPage(guiFinanceList, "menuHirePurchasing", { 0, 0, 1024, 1024 },
        LeasingOptions:makeCheckEnabledPredicate(), "pageSettings")


    g_currentMission.LeasingOptions = self

    self:loadFromXMLFile()
end

function LeasingOptions:makeCheckEnabledPredicate()
    return function() return true end
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

    local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory;
    if savegameFolderPath == nil then
        savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex)
    end
    savegameFolderPath = savegameFolderPath .. "/"

    local key = "leaseDeals";

    if fileExists(savegameFolderPath .. "leaseDeals.xml") then
        local xmlFile = loadXMLFile(key, savegameFolderPath .. "leaseDeals.xml");

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
    print("LeasingOptions.onVehicleSellEvent")
    if g_currentMission.isExitingGame then
        return
    end

    local leaseDeals = g_currentMission.LeasingOptions.leaseDeals
    local removed = {}
    for i, deal in ipairs(leaseDeals) do
        if deal:getVehicle() == nil then
            deal:paySettlemenCost()
            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL,
                g_i18n:getText("fl_deal_complete_early"))
            table.insert(removed, i)
        end
    end

    for _, index in pairs(removed) do
        table.remove(leaseDeals, index)
    end
end

-- from Courseplay
function LeasingOptions.addIngameMenuPage(frame, pageName, uvs, predicateFunc, insertAfter)
    local targetPosition = 0

    -- remove all to avoid warnings
    for k, v in pairs({ pageName }) do
        g_inGameMenu.controlIDs[v] = nil
    end

    for i = 1, #g_inGameMenu.pagingElement.elements do
        local child = g_inGameMenu.pagingElement.elements[i]
        if child == g_inGameMenu[insertAfter] then
            targetPosition = i + 1;
            break
        end
    end

    g_inGameMenu[pageName] = frame
    g_inGameMenu.pagingElement:addElement(g_inGameMenu[pageName])

    g_inGameMenu:exposeControlsAsFields(pageName)

    for i = 1, #g_inGameMenu.pagingElement.elements do
        local child = g_inGameMenu.pagingElement.elements[i]
        if child == g_inGameMenu[pageName] then
            table.remove(g_inGameMenu.pagingElement.elements, i)
            table.insert(g_inGameMenu.pagingElement.elements, targetPosition, child)
            break
        end
    end

    for i = 1, #g_inGameMenu.pagingElement.pages do
        local child = g_inGameMenu.pagingElement.pages[i]
        if child.element == g_inGameMenu[pageName] then
            table.remove(g_inGameMenu.pagingElement.pages, i)
            table.insert(g_inGameMenu.pagingElement.pages, targetPosition, child)
            break
        end
    end

    g_inGameMenu.pagingElement:updateAbsolutePosition()
    g_inGameMenu.pagingElement:updatePageMapping()

    g_inGameMenu:registerPage(g_inGameMenu[pageName], nil, predicateFunc)

    local iconFileName = Utils.getFilename('images/menuIcon.dds', LeasingOptions.dir)
    g_inGameMenu:addPageTab(g_inGameMenu[pageName], iconFileName, GuiUtils.getUVs(uvs))

    for i = 1, #g_inGameMenu.pageFrames do
        local child = g_inGameMenu.pageFrames[i]
        if child == g_inGameMenu[pageName] then
            table.remove(g_inGameMenu.pageFrames, i)
            table.insert(g_inGameMenu.pageFrames, targetPosition, child)
            break
        end
    end

    g_inGameMenu:rebuildTabList()
end

g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, LeasingOptions.periodChanged)
g_messageCenter:subscribe(MessageType.VEHICLE_REMOVED, LeasingOptions.onVehicleSellEvent)
FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, LeasingOptions.saveToXmlFile)
addModEventListener(LeasingOptions)
