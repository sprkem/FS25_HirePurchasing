VehicleExtension = {}

function VehicleExtension:showInfo(box)
    local playerFarm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
    if playerFarm == nil then return end

    for _, leaseDeal in pairs(g_currentMission.LeasingOptions.leaseDeals) do
        if leaseDeal.farmId == playerFarm.farmId and leaseDeal:getObjectId() == NetworkUtil.getObjectId(self) then
            box:addLine(g_i18n:getText("fl_header_monthly"),
                g_i18n:formatMoney(leaseDeal:getMonthlyPayment(), 0, true, true))
            box:addLine(g_i18n:getText("fl_header_months_left"), tostring(leaseDeal.durationMonths - leaseDeal.monthsPaid))
            box:addLine(g_i18n:getText("fl_header_final_fee"), g_i18n:formatMoney(leaseDeal.finalFee, 0, true, true))
            box:addLine(g_i18n:getText("fl_header_settlement_cost"),
                g_i18n:formatMoney(leaseDeal:getSettlementCost(), 0, true, true))
            return
        end
    end
end

Vehicle.showInfo = Utils.appendedFunction(Vehicle.showInfo, VehicleExtension.showInfo)
