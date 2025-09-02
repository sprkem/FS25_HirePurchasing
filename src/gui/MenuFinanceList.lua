MenuFinanceList = {}
MenuFinanceList._mt = Class(MenuFinanceList, TabbedMenuFrameElement)

function MenuFinanceList.new(i18n, messageCenter)
    local self = MenuFinanceList:superClass().new(nil, MenuFinanceList._mt)
    self.name = "menuHirePurchasing"
    self.i18n = i18n
    self.messageCenter = messageCenter
    self.selectedIndex = -1
    self.currentDeals = {}

    self.btnBack = {
        inputAction = InputAction.MENU_BACK
    }

    self.btnSettle = {
        text = g_i18n:getText("fl_btn_settle_early"),
        inputAction = InputAction.MENU_ACCEPT,
        callback = function()
            self:settleEarly()
        end
    }

    self:setMenuButtonInfo({
        self.btnBack,
        self.btnSettle
    })
    return self
end

function MenuFinanceList:delete()
    MenuFinanceList:superClass().delete(self)
end

function MenuFinanceList:onGuiSetupFinished()
    MenuFinanceList:superClass().onGuiSetupFinished(self)
    self.currentDealsTable:setDataSource(self)
    self.currentDealsTable:setDelegate(self)
end

function MenuFinanceList:onFrameOpen()
    MenuFinanceList:superClass().onFrameOpen(self)

    self:updateContent()
end

function MenuFinanceList:onFrameClose()
    MenuFinanceList:superClass().onFrameClose(self)
end

function MenuFinanceList:updateContent()
    self.currentDeals = {}
    local playerFarm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)

    for _, leaseDeal in pairs(g_currentMission.LeasingOptions.leaseDeals) do
        if leaseDeal.farmId == playerFarm.farmId and leaseDeal:getVehicle() ~= nil then
            table.insert(self.currentDeals, leaseDeal)
        end
    end

    self.currentBalanceText:setText(g_i18n:formatMoney(playerFarm:getBalance(), 0, true, true))
    if next(self.currentDeals) == nil then
        self.tableContainer:setVisible(false)
        self.noDataContainer:setVisible(true)
        return
    end

    -- insert dummy record where we can display totals
    local totalMonthlyCost = 0
    local totalSettlement = 0
    local totalRemainingCost = 0
    local totalFinalFee = 0
    for _, deal in ipairs(self.currentDeals) do
        totalMonthlyCost = totalMonthlyCost + deal:getMonthlyPayment()
        totalSettlement = totalSettlement + deal:getSettlementCost()
        totalRemainingCost = totalRemainingCost + deal:getRemainingCost()
        totalFinalFee = totalFinalFee + deal.finalFee
    end
    table.insert(self.currentDeals, {
        item_name = "TOTAL",
        monthly_cost = totalMonthlyCost,
        final_fee = totalFinalFee,
        remaining_cost = totalRemainingCost,
        settlement_cost = totalSettlement
    })

    self.tableContainer:setVisible(true)
    self.noDataContainer:setVisible(false)
    self.currentDealsTable:reloadData()
end

function MenuFinanceList:getNumberOfSections()
    return 1
end

function MenuFinanceList:getNumberOfItemsInSection(list, section)
    return #self.currentDeals
end

function MenuFinanceList:getTitleForSectionHeader(list, section)
    return ""
end

function MenuFinanceList:populateCellForItemInSection(list, section, index, cell)
    if index == #self.currentDeals then
        local totals = self.currentDeals[index]
        -- This is the dummy record for totals
        cell:getAttribute("item_name"):setText(g_i18n:getText("ui_total"))
        cell:getAttribute("monthly_cost"):setText(g_i18n:formatMoney(totals.monthly_cost, 0, true, true))
        cell:getAttribute("interest"):setText("")
        cell:getAttribute("remaining_months"):setText("")
        cell:getAttribute("final_fee"):setText(g_i18n:formatMoney(totals.final_fee, 0, true, true))
        cell:getAttribute("remaining_cost"):setText(g_i18n:formatMoney(totals.remaining_cost, 0, true, true))
        cell:getAttribute("settlement_cost"):setText(g_i18n:formatMoney(totals.settlement_cost, 0, true, true))
        return
    end


    local deal = self.currentDeals[index]
    cell:getAttribute("item_name"):setText(deal:getVehicle():getName())
    cell:getAttribute("monthly_cost"):setText(g_i18n:formatMoney(deal:getMonthlyPayment(), 0, true, true))
    cell:getAttribute("interest"):setText(string.format("%.2f%%", deal:getInterestRate() * 100))
    cell:getAttribute("remaining_months"):setText(tostring(deal.durationMonths - deal.monthsPaid))
    cell:getAttribute("final_fee"):setText(g_i18n:formatMoney(deal.finalFee, 0, true, true))
    cell:getAttribute("remaining_cost"):setText(g_i18n:formatMoney(deal:getRemainingCost(), 0, true, true))
    cell:getAttribute("settlement_cost"):setText(g_i18n:formatMoney(deal:getSettlementCost(), 0, true, true))
end

function MenuFinanceList:onListSelectionChanged(list, section, index)
    self.selectedIndex = index
end

function MenuFinanceList:settleEarly()
    if self.selectedIndex == #self.currentDeals then
        return
    end

    local deal = self.currentDeals[self.selectedIndex]
    if deal == nil then
        return
    end
    local settlementCost = deal:getSettlementCost()
    local farm = g_farmManager:getFarmById(deal.farmId)
    if farm:getBalance() < settlementCost then
        InfoDialog.show(g_i18n:getText("fl_not_enough_money_settlement"))
        return
    end

    YesNoDialog.show(
        function(self, clickOk)
            if clickOk then
                local leaseDeals = g_currentMission.LeasingOptions.leaseDeals
                local found = false
                for i, d in ipairs(leaseDeals) do
                    if d == deal then
                        found = true
                        break
                    end
                end

                if not found then
                    InfoDialog.show(g_i18n:getText("fl_deal_not_found"))
                    return
                end

                g_client:getServerConnection():sendEvent(SettleEarlyEvent.new(deal.id))

                InfoDialog.show(g_i18n:getText("fl_settle_early_complete"))
                self:updateContent()
            end
        end, self,
        string.format(g_i18n:getText("fl_confirm_settle_early"),
            g_i18n:formatMoney(deal:getSettlementCost(), 0, true, true)))
end
