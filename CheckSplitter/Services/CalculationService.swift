import Foundation

struct CalculationService {
    func calculate(
        subtotal: Decimal,
        tax: Decimal,
        tipInput: Decimal,
        tipMode: TipMode,
        people: Int,
        isRoundUpEnabled: Bool = false,
        isExtraPayerEnabled: Bool = false,
        extraAmount: Decimal = 0
    ) -> CalculationResult? {
        guard people > 0 else { return nil }
        if isExtraPayerEnabled { guard people >= 2 else { return nil } }

        let tip: Decimal
        switch tipMode {
        case .amount:
            tip = tipInput
        case .percentage:
            tip = subtotal * (tipInput / 100)
        }
        let total = subtotal + tax + tip

        var eachPersonPays: Decimal? = nil
        var extraPayerPays: Decimal? = nil
        var otherPersonPays: Decimal? = nil

        if isExtraPayerEnabled {
            // 1. extra payer calculation
            let baseShare = total / Decimal(people)
            let epRaw = baseShare + extraAmount
            let remaining = total - epRaw
            let opRaw = remaining / Decimal(people - 1)
            // 2. round up applied to results
            extraPayerPays = isRoundUpEnabled ? ceilDecimal(epRaw) : epRaw
            otherPersonPays = isRoundUpEnabled ? ceilDecimal(opRaw) : opRaw
        } else {
            let share = total / Decimal(people)
            eachPersonPays = isRoundUpEnabled ? ceilDecimal(share) : share
        }

        return CalculationResult(
            subtotal: subtotal,
            tax: tax,
            tip: tip,
            total: total,
            people: people,
            eachPersonPays: eachPersonPays,
            extraPayerPays: extraPayerPays,
            otherPersonPays: otherPersonPays,
            isRounded: isRoundUpEnabled
        )
    }

    private func ceilDecimal(_ value: Decimal) -> Decimal {
        var result = Decimal()
        var v = value
        NSDecimalRound(&result, &v, 0, .up)
        return result
    }
}
