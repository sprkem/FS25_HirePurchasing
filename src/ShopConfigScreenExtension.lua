function ShopConfigScreen:onClickFinance()
end

ShopConfigScreen.setStoreItem = Utils.overwrittenFunction(ShopConfigScreen.setStoreItem,
    function(self, superFunc, storeItem, ...)
        superFunc(self, storeItem, ...)


        local buyButton = self.buyButton
        local dealsButton = self.dealsButton

        if not dealsButton and buyButton then
            local parent = buyButton.parent
            dealsButton = buyButton:clone(parent)
            dealsButton.name = "dealsButton"
            -- dealsButton.text = g_i18n:getText("fl_btn_finance")
            dealsButton.inputActionName = "MENU_EXTRA_1"
            self.dealsButton = dealsButton
        end

        if dealsButton ~= nil then
            if not StoreItemUtil.getIsLeasable(storeItem) then
                dealsButton:setDisabled(true)
            else
                dealsButton:setDisabled(false)
            end

            dealsButton.onClick = "onClickFinance"
            dealsButton.text = g_i18n:getText("fl_btn_finance")

            self.onClickFinance = function()
                print("onClickFinance called")
                local dialog = g_gui:showDialog("newFinanceFrame")
                if dialog ~= nil then
                    dialog.target:setData(storeItem, self.configurations, self.licensePlateData, self.totalPrice)
                end
            end

            dealsButton.onClickCallback = self.onClickFinance
        end
    end)
