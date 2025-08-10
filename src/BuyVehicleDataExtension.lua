BuyVehicleDataExtension = {}

function BuyVehicleDataExtension:setLeaseDeal(leaseDeal)
    self.leaseDeal = leaseDeal
end

function BuyVehicleDataExtension:writeStream(streamId, connection)
    streamWriteBool(streamId, self.leaseDeal ~= nil)
    if self.leaseDeal then
        self.leaseDeal:writeStream(streamId, connection)
    end
end

function BuyVehicleDataExtension:readStream(streamId, connection)
    if streamReadBool(streamId) then
        self.leaseDeal = LeaseDeal.new()
        self.leaseDeal:readStream(streamId, connection)
    else
        self.leaseDeal = nil
    end
end

function BuyVehicleDataExtension.onBought(buyVehicleData, loadedVehicles, loadingState, callbackArguments)
    if loadingState == VehicleLoadingState.OK then
        for _, vehicle in loadedVehicles do
            if buyVehicleData.leaseDeal ~= nil then
                buyVehicleData.leaseDeal.objectId = NetworkUtil.getObjectId(vehicle)
                buyVehicleData.leaseDeal.vehicle = vehicle.uniqueId
                g_client:getServerConnection():sendEvent(NewLeaseDealEvent.new(buyVehicleData.leaseDeal))
                break
            end
        end
    end
end

function BuyVehicleDataExtension:updatePrice()
    if self.leaseDeal == nil then
        return
    end

    self.price = self.leaseDeal.deposit
end

function BuyVehicleDataExtension:buy()
    if self.leaseDeal ~= nil then self:updatePrice() end
end

BuyVehicleData.setLeaseDeal = BuyVehicleDataExtension.setLeaseDeal
BuyVehicleData.writeStream = Utils.appendedFunction(BuyVehicleData.writeStream, BuyVehicleDataExtension.writeStream)
BuyVehicleData.readStream = Utils.appendedFunction(BuyVehicleData.readStream, BuyVehicleDataExtension.readStream)
BuyVehicleData.onBought = Utils.prependedFunction(BuyVehicleData.onBought, BuyVehicleDataExtension.onBought)
BuyVehicleData.updatePrice = Utils.appendedFunction(BuyVehicleData.updatePrice, BuyVehicleDataExtension.updatePrice)
BuyVehicleData.buy = Utils.prependedFunction(BuyVehicleData.buy, BuyVehicleDataExtension.buy)
