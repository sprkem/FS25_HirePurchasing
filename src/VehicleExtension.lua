VehicleExtension = {}

function VehicleExtension:showInfo(box)
    local playerFarm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
    if playerFarm == nil then return end

    for _, leaseDeal in pairs(g_currentMission.LeasingOptions.leaseDeals) do
        if leaseDeal.farmId == playerFarm.farmId and leaseDeal.vehicle == self.uniqueId then
            box:addLine(g_i18n:getText("fl_header_monthly"),
                g_i18n:formatMoney(leaseDeal:getMonthlyPayment(), 0, true, true))
            box:addLine(g_i18n:getText("fl_header_months_left"),
                tostring(leaseDeal.durationMonths - leaseDeal.monthsPaid))
            box:addLine(g_i18n:getText("fl_header_final_fee"), g_i18n:formatMoney(leaseDeal.finalFee, 0, true, true))
            box:addLine(g_i18n:getText("fl_header_settlement_cost"),
                g_i18n:formatMoney(leaseDeal:getSettlementCost(), 0, true, true))
            return
        end
    end
end

function VehicleExtension:reset(forceDelete, callback)
    if forceDelete then
        for _, leaseDeal in pairs(g_currentMission.LeasingOptions.leaseDeals) do
            if leaseDeal.vehicle == self.uniqueId then
                print("Detected force reset for hire purchased item" .. self:getName())
                table.insert(g_currentMission.LeasingOptions.forceDeletes, leaseDeal)
                break
            end
        end
    end
end

Vehicle.showInfo = Utils.appendedFunction(Vehicle.showInfo, VehicleExtension.showInfo)
Vehicle.reset = Utils.prependedFunction(Vehicle.reset, VehicleExtension.reset)
