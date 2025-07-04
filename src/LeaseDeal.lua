LeaseDeal = {}
local LeaseDeal_mt = Class(LeaseDeal)

LeaseDeal.TYPE = {
    HIRE_PURCHASE = 1
}

LeaseDeal.MAX_MISSED_PAYMENTS = 3

function LeaseDeal.new(dealType, baseCost, deposit, durationMonths, finalFee, monthsPaid)
    local self = {}
    setmetatable(self, LeaseDeal_mt)

    self.dealType = dealType
    self.baseCost = baseCost
    self.deposit = deposit
    self.durationMonths = durationMonths
    self.finalFee = finalFee
    self.monthsPaid = monthsPaid
    self.vehicle = ""
    self.farmId = -1

    return self
end

---Returns true if the deal has ended, false otherwise.
---@return boolean
function LeaseDeal:processMonthly()
    local farm = g_farmManager:getFarmById(self.farmId)

    if self.monthsPaid == self.durationMonths then
        if g_currentMission:getIsServer() then
            g_currentMission:addMoneyChange(-self.finalFee, self.farmId, MoneyType.LEASING_COSTS, true)
            farm:changeBalance(-self.finalFee, MoneyType.LEASING_COSTS)
            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL,
                string.format(g_i18n:getText("fl_deal_complete"), self:getVehicle():getName()))
        end
        return true
    end

    local amountDue = self:getMonthlyPayment()

    if g_currentMission:getIsServer() then
        g_currentMission:addMoneyChange(-amountDue, self.farmId, MoneyType.LEASING_COSTS, true)
        farm:changeBalance(-amountDue, MoneyType.LEASING_COSTS)
    end

    self.monthsPaid = self.monthsPaid + 1

    if self.monthsPaid == self.durationMonths and self.finalFee == 0 then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL,
            string.format(g_i18n:getText("fl_deal_complete"), self:getVehicle():getName()))
    end

    return false
end

function LeaseDeal:getVehicle()
    return g_currentMission:getObjectByUniqueId(self.vehicle)
end

function LeaseDeal:getInterestRate()
    local depositRatio = self.deposit / self.baseCost
    local interestRate

    if depositRatio <= 0.11 then
        interestRate = 0.04
    elseif depositRatio <= 0.21 then
        interestRate = 0.035
    elseif depositRatio <= 0.31 then
        interestRate = 0.0295
    else
        interestRate = 0.025
    end

    return interestRate
end

function LeaseDeal:getMonthlyPayment()
    local amountFinanced = self.baseCost - self.deposit
    local interestRate = self:getInterestRate()

    local monthlyInterest = interestRate / 12

    local monthlyPayment
    if monthlyInterest > 0 then
        local pv = amountFinanced
        local fv = self.finalFee
        local n = self.durationMonths
        local r = monthlyInterest
        monthlyPayment = (pv - fv / ((1 + r) ^ n)) * (r * (1 + r) ^ n) / ((1 + r) ^ n - 1)
    else
        monthlyPayment = (amountFinanced + self.finalFee) / self.durationMonths
    end

    return monthlyPayment
end

function LeaseDeal:getMonthlyPaymentNoInterest()
    local amountFinanced = self.baseCost - self.deposit
    return amountFinanced / self.durationMonths
end

function LeaseDeal:getTotalCost()
    local monthlyPayment = self:getMonthlyPayment()
    return (monthlyPayment * self.durationMonths) + self.finalFee + self.deposit
end

function LeaseDeal:getRemainingCost()
    local monthlyPayment = self:getMonthlyPayment()
    local remainingMonths = self.durationMonths - self.monthsPaid
    return (monthlyPayment * remainingMonths) + self.finalFee
end

function LeaseDeal:getSettlementCost()
    local remainingMonths = self.durationMonths - self.monthsPaid
    return (self:getMonthlyPaymentNoInterest() * remainingMonths) + self.finalFee
end

function LeaseDeal:paySettlemenCost()
    local settlementCost = self:getSettlementCost()
    local farm = g_farmManager:getFarmById(self.farmId)

    g_currentMission:addMoneyChange(-settlementCost, self.farmId, MoneyType.LEASING_COSTS, true)
    farm:changeBalance(-settlementCost, MoneyType.LEASING_COSTS)
end

function LeaseDeal:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.dealType)
    streamWriteInt32(streamId, self.baseCost)
    streamWriteInt32(streamId, self.deposit)
    streamWriteInt32(streamId, self.durationMonths)
    streamWriteInt32(streamId, self.finalFee)
    streamWriteInt32(streamId, self.monthsPaid)
    streamWriteString(streamId, self.vehicle)
    streamWriteInt32(streamId, self.farmId)
end

function LeaseDeal:readStream(streamId, connection)
    self.dealType = streamReadInt32(streamId)
    self.baseCost = streamReadInt32(streamId)
    self.deposit = streamReadInt32(streamId)
    self.durationMonths = streamReadInt32(streamId)
    self.finalFee = streamReadInt32(streamId)
    self.monthsPaid = streamReadInt32(streamId)
    self.vehicle = streamReadString(streamId)
    self.farmId = streamReadInt32(streamId)
end

function LeaseDeal:saveToXmlFile(xmlFile, key)
    setXMLInt(xmlFile, key .. "#dealType", self.dealType)
    setXMLInt(xmlFile, key .. "#baseCost", self.baseCost)
    setXMLInt(xmlFile, key .. "#deposit", self.deposit)
    setXMLInt(xmlFile, key .. "#durationMonths", self.durationMonths)
    setXMLInt(xmlFile, key .. "#finalFee", self.finalFee)
    setXMLInt(xmlFile, key .. "#monthsPaid", self.monthsPaid)
    setXMLString(xmlFile, key .. "#vehicle", self.vehicle)
    setXMLInt(xmlFile, key .. "#farmId", self.farmId)
end

function LeaseDeal:loadFromXMLFile(xmlFile, key)
    self.dealType = getXMLInt(xmlFile, key .. "#dealType")
    self.baseCost = getXMLInt(xmlFile, key .. "#baseCost")
    self.deposit = getXMLInt(xmlFile, key .. "#deposit")
    self.durationMonths = getXMLInt(xmlFile, key .. "#durationMonths")
    self.finalFee = getXMLInt(xmlFile, key .. "#finalFee")
    self.monthsPaid = getXMLInt(xmlFile, key .. "#monthsPaid")
    self.vehicle = getXMLString(xmlFile, key .. "#vehicle")
    self.farmId = getXMLInt(xmlFile, key .. "#farmId")
end
