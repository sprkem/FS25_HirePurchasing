ShopConfigScreen.setStoreItem = Utils.overwrittenFunction(ShopConfigScreen.setStoreItem,
    function(self, superFunc, storeItem, ...)
        superFunc(self, storeItem, ...)


        local sourceButton = self.buyButton
        local dealsButton = self.dealsButton

        if not dealsButton and sourceButton then
            local parent = sourceButton.parent
            dealsButton = sourceButton:clone(parent)
            dealsButton.name = "dealsButton"
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
            dealsButton:setText(g_i18n:getText("fl_btn_finance"))

            self.onClickFinance = function()
                local dialog = g_gui:showDialog("newFinanceFrame")
                if dialog ~= nil then
                    dialog.target:setData(storeItem, self.configurations, self.licensePlateData, self.totalPrice)
                end
            end

            dealsButton.onClickCallback = self.onClickFinance
        end
    end)
