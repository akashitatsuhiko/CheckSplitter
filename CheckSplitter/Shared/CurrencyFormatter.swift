import Foundation

enum CurrencyFormatter {
    static func format(_ value: Decimal) -> String {
        value.formatted(
            .currency(code: "USD")
                .precision(.fractionLength(2))
        )
    }
}
