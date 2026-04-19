import Foundation

enum ValidationError {
    case missingSubtotal
    case missingPeople
    case invalidSubtotal
    case invalidTax
    case invalidTip
    case invalidPeople
    case invalidExtraAmount
    case peopleMustBeAtLeastOne
    case extraAmountExceedsTotal
}
