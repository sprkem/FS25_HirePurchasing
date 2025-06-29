NewFinanceFrame = {}
NewFinanceFrame.currentGroups = {}
local NewFinanceFrame_mt = Class(NewFinanceFrame, MessageDialog)

NewFinanceFrame.DEFAULT_DURATION_MONTHS = 12
NewFinanceFrame.MAX_DURATION_YEARS = 10

function NewFinanceFrame.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or NewFinanceFrame_mt)
    self.i18n = g_i18n
    self:init()
    return self
end

function NewFinanceFrame:init()
    self.parent = nil
    self.storeItem = nil
    self.depositIndex = 1
    self.offerings = nil
    self.durationMonths = NewFinanceFrame.DEFAULT_DURATION_MONTHS
    self.depositOptions = nil
    self.offeringIndex = 1
    self.configurations = nil
    self.licensePlateData = nil
    self.totalPrice = 0
    self.saleItem = nil
end

function NewFinanceFrame:setData(storeItem, configurations, licensePlateData, totalPrice, saleItem)
    -- local xmlFile = loadXMLFile("Temp", "dataS/gui/dialogs/OptionDialog.xml")
    -- saveXMLFileTo(xmlFile, g_currentMission.missionInfo.savegameDirectory .. "/tempUI.xml")
    -- delete(xmlFile);

    local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)

    if farm == nil then
        return
    end

    local potentialDepositOptions = {
        totalPrice * 0.1,
        totalPrice * 0.2,
        totalPrice * 0.3,
        totalPrice * 0.4,
    }
    self.depositOptions = {}
    for _, amount in pairs(potentialDepositOptions) do
        if amount <= farm.money then
            table.insert(self.depositOptions, amount)
        end
    end

    if #self.depositOptions == 0 then
        InfoDialog.show(string.format(g_i18n:getText("fl_not_enough_money"),
            g_i18n:formatMoney(potentialDepositOptions[1], 0, true, true)))
        self:close()
        return
    end

    self.totalPrice = totalPrice
    self.storeItem = storeItem
    self.configurations = configurations
    self.licensePlateData = licensePlateData
    self.saleItem = saleItem

    local depositTexts = {}
    for _, deposit in pairs(self.depositOptions) do
        local percentage = math.floor(deposit / totalPrice * 100)
        table.insert(depositTexts, string.format("%s [%s%%]", g_i18n:formatMoney(deposit, 0, true, true), percentage))
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
end

function NewFinanceFrame:onClose()
    NewFinanceFrame:superClass().onClose(self)
    self:init()
end

function NewFinanceFrame:onClickBack(sender)
    self:close()
end

function NewFinanceFrame:updateView()
    self:refreshOfferings()

    local offerOne = self.offerings[1]
    local offerTwo = self.offerings[2]
    local offerThree = self.offerings[3]
    local offerFour = self.offerings[4]

    self.offerOneInterest:setText(string.format("%.2f%%", offerOne:getInterestRate() * 100))
    self.offerOneMonthly:setText(g_i18n:formatMoney(offerOne:getMonthlyPayment(), 0, true, true))
    self.offerOneFinal:setText(g_i18n:formatMoney(offerOne.finalFee, 0, true, true))
    self.offerOneTotal:setText(g_i18n:formatMoney(offerOne:getTotalCost(), 0, true, true))

    self.offerTwoInterest:setText(string.format("%.2f%%", offerTwo:getInterestRate() * 100))
    self.offerTwoMonthly:setText(g_i18n:formatMoney(offerTwo:getMonthlyPayment(), 0, true, true))
    self.offerTwoFinal:setText(g_i18n:formatMoney(offerTwo.finalFee, 0, true, true))
    self.offerTwoTotal:setText(g_i18n:formatMoney(offerTwo:getTotalCost(), 0, true, true))

    self.offerThreeInterest:setText(string.format("%.2f%%", offerThree:getInterestRate() * 100))
    self.offerThreeMonthly:setText(g_i18n:formatMoney(offerThree:getMonthlyPayment(), 0, true, true))
    self.offerThreeFinal:setText(g_i18n:formatMoney(offerThree.finalFee, 0, true, true))
    self.offerThreeTotal:setText(g_i18n:formatMoney(offerThree:getTotalCost(), 0, true, true))

    self.offerFourInterest:setText(string.format("%.2f%%", offerFour:getInterestRate() * 100))
    self.offerFourMonthly:setText(g_i18n:formatMoney(offerFour:getMonthlyPayment(), 0, true, true))
    self.offerFourFinal:setText(g_i18n:formatMoney(offerFour.finalFee, 0, true, true))
    self.offerFourTotal:setText(g_i18n:formatMoney(offerFour:getTotalCost(), 0, true, true))
end

function NewFinanceFrame:refreshOfferings()
    local deposit = self.depositOptions[self.depositIndex]
    self.offerings = self:getLeaseAgreementOptions(self.durationMonths, deposit, self.totalPrice)
end

function NewFinanceFrame:getLeaseAgreementOptions(durationMonths, deposit, baseCost)
    local remainingValueOptions = { 0, 0.1, 0.2, 0.3 }
    local agreements            = {}
    for _, remainingValuePercent in ipairs(remainingValueOptions) do
        table.insert(agreements, LeaseDeal.new(
            LeaseDeal.TYPE.HIRE_PURCHASE,
            baseCost,
            deposit,
            durationMonths,
            baseCost * remainingValuePercent,
            0
        ))
    end
    return agreements
end

function NewFinanceFrame:onClickDepositLevel(index)
    self.depositIndex = index
    self:updateView()
end

function NewFinanceFrame:onClickDuration(index)
    self.durationMonths = index * 12
    self:updateView()
end

function NewFinanceFrame:onClickOfferSelection(index)
    self.offeringIndex = index
end

function NewFinanceFrame:onClickPurchase(sender)
    local leaseDeal = self.offerings[self.offeringIndex]
    local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
    leaseDeal.farmId = farm.farmId

    local event = BuyVehicleData.new()
    event:setOwnerFarmId(farm.farmId)
    event:setPrice(leaseDeal.deposit)
    event:setStoreItem(self.storeItem)
    event:setConfigurations(self.configurations)
    event:setLicensePlateData(self.licensePlateData)
    event:setLeaseDeal(leaseDeal)
    event:setSaleItem(self.saleItem)

    g_client:getServerConnection():sendEvent(BuyVehicleEvent.new(event))

    self:close()
end
