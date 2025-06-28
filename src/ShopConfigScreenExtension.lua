function ShopConfigScreen:onClickFinance()
end

ShopConfigScreen.setStoreItem = Utils.overwrittenFunction(ShopConfigScreen.setStoreItem,
    function(self, superFunc, storeItem, ...)
        superFunc(self, storeItem, ...)

        local buyButton = self.buyButton
        local financeButton = self.financeButton

        if not financeButton and buyButton then
            local parent = buyButton.parent
            financeButton = buyButton:clone(parent)
            financeButton.name = "financeButton"
            -- financeButton.text = g_i18n:getText("fl_btn_finance")
            financeButton.inputActionName = "MENU_EXTRA_1"
            self.financeButton = financeButton
        end

        if financeButton ~= nil then
            financeButton:setDisabled(false)

            financeButton.onClick = "onClickFinance"
            financeButton.text = g_i18n:getText("fl_btn_finance")

            self.onClickFinance = function()
                print("onClickFinance called")
                local dialog = g_gui:showDialog("newFinanceFrame")
                if dialog ~= nil then
                    dialog.target:setData(self, storeItem, self.configurations)
                end
            end

            financeButton.onClickCallback = self.onClickFinance
        end
    end)
