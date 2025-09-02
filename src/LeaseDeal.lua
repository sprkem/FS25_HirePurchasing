LeaseDeal = {}
local LeaseDeal_mt = Class(LeaseDeal)

LeaseDeal.TYPE = {
    HIRE_PURCHASE = 1
}

LeaseDeal.GET_VEHICLE_METHOD = {
    UNIQUE_ID = 1,
    OBJECT_ID = 2
}

LeaseDeal.MAX_MISSED_PAYMENTS = 3

function LeaseDeal.new(dealType, baseCost, deposit, durationMonths, finalFee, monthsPaid)
    local self = {}
    setmetatable(self, LeaseDeal_mt)

    self.id = g_currentMission.LeasingOptions:generateId()
    self.dealType = dealType
    self.baseCost = baseCost
    self.deposit = deposit
    self.durationMonths = durationMonths
    self.finalFee = finalFee
    self.monthsPaid = monthsPaid
    self.vehicle = "" -- used on the server to identify vehicles
    self.farmId = -1
    self.objectId = -1 -- used on the client to identify vehicles

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

function LeaseDeal:getObjectId()
    -- Lazy load the objectId
    if self.objectId == -1 then
        -- Should only happen on the server or in singleplayer
        for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
            if vehicle.uniqueId == self.vehicle then
                self.objectId = NetworkUtil.getObjectId(vehicle)
                break
            end
        end
    end
    return self.objectId
end

function LeaseDeal:getVehicle()
    local getMethod = LeaseDeal.GET_VEHICLE_METHOD.OBJECT_ID
    if g_currentMission:getIsServer() then
        getMethod = LeaseDeal.GET_VEHICLE_METHOD.UNIQUE_ID
        if self.vehicle == "" then
            local object = NetworkUtil.getObject(self:getObjectId())
            if object == nil then
                return nil
            end
            self.vehicle = object.uniqueId
        end
    end

    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if getMethod == LeaseDeal.GET_VEHICLE_METHOD.UNIQUE_ID then
            if vehicle.uniqueId == self.vehicle then
                return vehicle
            end
        elseif getMethod == LeaseDeal.GET_VEHICLE_METHOD.OBJECT_ID then
            if NetworkUtil.getObjectId(vehicle) == self:getObjectId() then
                return vehicle
            end
        end
    end

    return nil
end

function LeaseDeal:getInterestRate()
    local depositRatio = self.deposit / self.baseCost
    local interestRate

    if depositRatio <= 0.051 then
        interestRate = 0.05
    elseif depositRatio <= 0.11 then
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
    local pv = amountFinanced
    local fv = self.finalFee
    local n = self.durationMonths
    local r = monthlyInterest
    monthlyPayment = (pv - fv / ((1 + r) ^ n)) * (r * (1 + r) ^ n) / ((1 + r) ^ n - 1)

    return monthlyPayment
end

function LeaseDeal:getMonthlyAmountForSettlement()
    local amountFinanced = self.baseCost - self.deposit - self.finalFee
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
    return (self:getMonthlyAmountForSettlement() * remainingMonths) + self.finalFee
end

-- Should only be called on the server by the SettleEarlyEvent
function LeaseDeal:paySettlementCost()
    if (not g_currentMission:getIsServer()) then return end
    local settlementCost = self:getSettlementCost()
    local farm = g_farmManager:getFarmById(self.farmId)

    g_currentMission:addMoneyChange(-settlementCost, self.farmId, MoneyType.LEASING_COSTS, true)
    farm:changeBalance(-settlementCost, MoneyType.LEASING_COSTS)
end

function LeaseDeal:writeStream(streamId, connection)
    streamWriteString(streamId, self.id)
    streamWriteInt32(streamId, self.dealType)
    streamWriteInt32(streamId, self.baseCost)
    streamWriteInt32(streamId, self.deposit)
    streamWriteInt32(streamId, self.durationMonths)
    streamWriteInt32(streamId, self.finalFee)
    streamWriteInt32(streamId, self.monthsPaid)
    streamWriteInt32(streamId, self.farmId)
    streamWriteInt32(streamId, self:getObjectId())
    streamWriteString(streamId, self.vehicle)
end

function LeaseDeal:readStream(streamId, connection)
    self.id = streamReadString(streamId)
    self.dealType = streamReadInt32(streamId)
    self.baseCost = streamReadInt32(streamId)
    self.deposit = streamReadInt32(streamId)
    self.durationMonths = streamReadInt32(streamId)
    self.finalFee = streamReadInt32(streamId)
    self.monthsPaid = streamReadInt32(streamId)
    self.farmId = streamReadInt32(streamId)
    self.objectId = streamReadInt32(streamId)
    self.vehicle = streamReadString(streamId)
end

function LeaseDeal:saveToXmlFile(xmlFile, key)
    setXMLString(xmlFile, key .. "#id", self.id)
    setXMLInt(xmlFile, key .. "#dealType", self.dealType)
    setXMLInt(xmlFile, key .. "#baseCost", self.baseCost)
    setXMLInt(xmlFile, key .. "#deposit", self.deposit)
    setXMLInt(xmlFile, key .. "#durationMonths", self.durationMonths)
    setXMLInt(xmlFile, key .. "#finalFee", self.finalFee)
    setXMLInt(xmlFile, key .. "#monthsPaid", self.monthsPaid)
    setXMLString(xmlFile, key .. "#vehicle", NetworkUtil.getObject(self:getObjectId()).uniqueId)
    setXMLInt(xmlFile, key .. "#farmId", self.farmId)
end

function LeaseDeal:loadFromXMLFile(xmlFile, key)
    self.id = getXMLString(xmlFile, key .. "#id") or g_currentMission.LeasingOptions:generateId()
    self.dealType = getXMLInt(xmlFile, key .. "#dealType")
    self.baseCost = getXMLInt(xmlFile, key .. "#baseCost")
    self.deposit = getXMLInt(xmlFile, key .. "#deposit")
    self.durationMonths = getXMLInt(xmlFile, key .. "#durationMonths")
    self.finalFee = getXMLInt(xmlFile, key .. "#finalFee")
    self.monthsPaid = getXMLInt(xmlFile, key .. "#monthsPaid")
    self.vehicle = getXMLString(xmlFile, key .. "#vehicle")
    self.farmId = getXMLInt(xmlFile, key .. "#farmId")
end
