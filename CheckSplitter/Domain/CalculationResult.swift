import Foundation

struct CalculationResult {
    let subtotal: Decimal
    let tax: Decimal
    let tip: Decimal
    let total: Decimal
    let people: Int
    let eachPersonPays: Decimal?
    let extraPayerPays: Decimal?
    let otherPersonPays: Decimal?
    let isRounded: Bool
}
