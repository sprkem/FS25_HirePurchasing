NewFinanceFrame = {}
NewFinanceFrame.currentGroups = {}
local NewFinanceFrame_mt = Class(NewFinanceFrame, MessageDialog)

NewFinanceFrame.DEFAULT_DURATION_MONTHS = 24
NewFinanceFrame.MAX_DURATION_YEARS = 10

function NewFinanceFrame.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or NewFinanceFrame_mt)
    self.i18n = g_i18n
    self.parent = nil
    self.storeItem = nil
    self.depositIndex = 1
    self.offerings = nil
    self.durationMonths = NewFinanceFrame.DEFAULT_DURATION_MONTHS
    self.depositOptions = nil
    return self
end

function NewFinanceFrame:setData(parent, storeItem)
    -- NewFinanceFrame:superClass().setData(self, parent, storeItem)
    print("NewFinanceFrame:setData called")

    local xmlFile = loadXMLFile("Temp", "dataS/gui/dialogs/OptionDialog.xml")
    saveXMLFileTo(xmlFile, g_currentMission.missionInfo.savegameDirectory .. "/tempUI.xml")
    delete(xmlFile);

    self.storeItem = storeItem
    self.depositOptions = {
        storeItem.price * 0.1,
        storeItem.price * 0.2,
        storeItem.price * 0.3,
        storeItem.price * 0.4,
    }

    local depositTexts = {}
    for _, deposit in pairs(self.depositOptions) do
        table.insert(depositTexts, g_i18n:formatMoney(deposit))
    end

    self.depositOption:setTexts(depositTexts)

    self.durationMonths = NewFinanceFrame.DEFAULT_DURATION_MONTHS

    local durationTexts = {}
    for years = 1, NewFinanceFrame.MAX_DURATION_YEARS do
        table.insert(durationTexts, tostring(years))
    end
    self.durationOption:setTexts(durationTexts)

    self:updateView()
end

function NewFinanceFrame:onCreate()
    NewFinanceFrame:superClass().onCreate(self)
end

function NewFinanceFrame:onGuiSetupFinished()
    NewFinanceFrame:superClass().onGuiSetupFinished(self)
end

function NewFinanceFrame:onOpen()
    NewFinanceFrame:superClass().onOpen(self)
    print("NewFinanceFrame:onOpen called")
    -- self:updateContent()
end

function NewFinanceFrame:onClose()
    NewFinanceFrame:superClass().onClose(self)
    print("NewFinanceFrame:onClose called")
    self.parent = nil
    self.storeItem = nil
    self.depositIndex = 1
    self.offerings = nil
    self.durationMonths = NewFinanceFrame.DEFAULT_DURATION_MONTHS
    self.depositOptions = nil
end

function NewFinanceFrame:onClickBack(sender)
    self:close()
end

function NewFinanceFrame:onClickPurchase(sender)
    print("NewFinanceFrame:onClickPurchase called")
end

function NewFinanceFrame:updateView()
    self:refreshOfferings()

    local offerOne = self.offerings[1]
    local offerTwo = self.offerings[2]
    local offerThree = self.offerings[3]
    local offerFour = self.offerings[4]

    self.offerOneMonthly:setText(g_i18n:formatMoney(offerOne.monthlyPayment))
    self.offerOneFinal:setText(g_i18n:formatMoney(offerOne.residualValue))
    self.offerOneTotal:setText(g_i18n:formatMoney(offerOne.totalPurchaseCost))

    self.offerTwoMonthly:setText(g_i18n:formatMoney(offerTwo.monthlyPayment))
    self.offerTwoFinal:setText(g_i18n:formatMoney(offerTwo.residualValue))
    self.offerTwoTotal:setText(g_i18n:formatMoney(offerTwo.totalPurchaseCost))

    self.offerThreeMonthly:setText(g_i18n:formatMoney(offerThree.monthlyPayment))
    self.offerThreeFinal:setText(g_i18n:formatMoney(offerThree.residualValue))
    self.offerThreeTotal:setText(g_i18n:formatMoney(offerThree.totalPurchaseCost))

    self.offerFourMonthly:setText(g_i18n:formatMoney(offerFour.monthlyPayment))
    self.offerFourFinal:setText(g_i18n:formatMoney(offerFour.residualValue))
    self.offerFourTotal:setText(g_i18n:formatMoney(offerFour.totalPurchaseCost))
end

function NewFinanceFrame:refreshOfferings()
    local deposit = self.depositOptions[self.depositIndex]
    self.offerings = Deals:getLeaseAgreementOptions(self.durationMonths, deposit, self.storeItem.price)
    DebugUtil.printTableRecursively(self.offerings)
end

function NewFinanceFrame:onClickDepositLevel(state)
    self.depositIndex = state
    self:updateView()
end

function NewFinanceFrame:onClickDuration(state)
    self.durationMonths = state * 12
    self:updateView()
end

function NewFinanceFrame:onClickOfferSelection(state)
    print(state)
end
