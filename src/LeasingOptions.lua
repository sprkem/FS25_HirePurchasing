LeasingOptions = {}
LeasingOptions.dir = g_currentModDirectory

function LeasingOptions:loadMap()
    local newFinanceDialog = NewFinanceFrame.new(g_i18n)

    g_gui:loadProfiles(LeasingOptions.dir .. "src/gui/guiProfiles.xml")

    g_gui:loadGui(LeasingOptions.dir .. "src/gui/NewFinanceFrame.xml", "newFinanceFrame", newFinanceDialog)
    g_currentMission.LeasingOptions = self
end

function LeasingOptions:onStartMission()
    print("LeasingOptions:onStartMission called")
end

FSBaseMission.onStartMission = Utils.prependedFunction(FSBaseMission.onStartMission, LeasingOptions.onStartMission)
addModEventListener(LeasingOptions)
