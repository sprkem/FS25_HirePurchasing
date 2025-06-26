FinanceLeasing = {}
FinanceLeasing.dir = g_currentModDirectory

function FinanceLeasing:loadMap()
    local newFinanceDialog = NewFinanceFrame.new(g_i18n)

    g_gui:loadProfiles(FinanceLeasing.dir .. "src/gui/guiProfiles.xml")

    g_gui:loadGui(FinanceLeasing.dir .. "src/gui/NewFinanceFrame.xml", "newFinanceFrame", newFinanceDialog)
    g_currentMission.financeLeasing = self
end

function FinanceLeasing:onStartMission()
    print("FinanceLeasing:onStartMission called")
end

FSBaseMission.onStartMission = Utils.prependedFunction(FSBaseMission.onStartMission, FinanceLeasing.onStartMission)
addModEventListener(FinanceLeasing)
