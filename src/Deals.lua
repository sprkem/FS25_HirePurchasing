Deals = {}


-- BuyUsedEquipment:createSearchAssignment

function Deals:calculateLeaseAgreement(durationMonths, deposit, baseCost, remainingValuePercent)
    -- Set target residual value to a percentage of base cost
    local finalFee = baseCost * remainingValuePercent
    -- Amount to finance (baseCost minus deposit)
    local amountFinanced = baseCost - deposit
    local depositRatio = deposit / baseCost
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

    if depositRatio >= 0.5 then
        interestRate = 0.02 -- 2% annual
    elseif depositRatio >= 0.2 then
        interestRate = 0.04 -- 4% annual
    else
        interestRate = 0.06 -- 6% annual
    end

    -- Monthly interest rate
    local monthlyInterest = interestRate / 12

    -- Calculate monthly payment (amortizing loan formula with balloon payment)
    local monthlyPayment
    if monthlyInterest > 0 then
        local pv = amountFinanced
        local fv = finalFee
        local n = durationMonths
        local r = monthlyInterest
        monthlyPayment = (pv - fv / ((1 + r) ^ n)) * (r * (1 + r) ^ n) / ((1 + r) ^ n - 1)
    end

    local totalPurchaseCost = deposit + (monthlyPayment * durationMonths) + finalFee

    -- Calculate total interest paid over the lease term
    local totalPayments = monthlyPayment * durationMonths
    local totalInterest = totalPayments - (amountFinanced - finalFee)

    -- Calculate earned equity (deposit + principal paid)
    local principalPaid = totalPayments - totalInterest

    local equityEarned = deposit + principalPaid

    -- Define end-of-lease options
    -- local endOptions = {
    --     purchase = {
    --         purchasePrice = residualValue
    --     },
    --     returnItem = {
    --         fee = 0 -- No fee for returning
    --     },
    --     renew = {
    --         equityTransferred = equityEarned * (1 - 0.05 * math.floor(durationMonths / 12))
    --     }
    -- }

    -- Lease agreement details
    local leaseAgreement = {
        durationMonths = durationMonths,
        deposit = deposit,
        baseCost = baseCost,
        interestRate = interestRate,
        monthlyPayment = monthlyPayment,
        totalPurchaseCost = totalPurchaseCost,
        finalFee = finalFee,
        -- endOfLeaseOptions = endOptions,
        equity = equityEarned * (1 - 0.05 * math.floor(durationMonths / 12)),
    }

    return leaseAgreement
end

function Deals:getLeaseAgreementOptions(durationMonths, deposit, baseCost)
    local remainingValueOptions  = {0, 0.1, 0.2, 0.3}
    -- for each option, get a lease agreement
    local agreements = {}
    for _, remainingValuePercent in ipairs(remainingValueOptions) do
        local agreement = self:calculateLeaseAgreement(durationMonths, deposit, baseCost, remainingValuePercent)
        table.insert(agreements, agreement)
    end
    return agreements
end

function Deals:printLeaseAgreement(agreement)
    print("\n")
    print("Duration (months):", agreement.durationMonths)
    print("Deposit:", agreement.deposit)
    print("Base Cost:", agreement.baseCost)
    print("Interest Rate:", agreement.interestRate * 100 .. "%")
    print("Monthly Payment:", string.format("%.2f", agreement.monthlyPayment))
    print("Final payment:", string.format("%.2f", agreement.residualValue))
    print("Total Purchase Cost:", string.format("%.2f", agreement.totalPurchaseCost))
    print("Equity Earned:", string.format("%.2f", agreement.endOfLeaseOptions.renew.equityTransferred or 0))
end

