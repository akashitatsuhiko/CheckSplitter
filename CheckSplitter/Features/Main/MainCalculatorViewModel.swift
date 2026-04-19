import Combine
import Foundation

@MainActor
final class MainCalculatorViewModel: ObservableObject {
    // MARK: - Input
    @Published var subtotalText = ""
    @Published var taxText = ""
    @Published var tipText = ""
    @Published var peopleText = "2"
    @Published var tipMode: TipMode = .amount

    // MARK: - Pro Options
    @Published var isRoundUpEnabled = false
    @Published var isExtraPayerEnabled = false
    @Published var extraAmountText = ""

    // MARK: - Purchase State
    @Published var isProUnlocked = false
    @Published var hasLoadedPurchaseState = false
    @Published var showPaywall = false
    @Published var isPurchasing = false

    let purchaseManager = PurchaseManager()
    private let service = CalculationService()
    @Published private var hasInteracted = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        purchaseManager.$isProUnlocked
            .assign(to: &$isProUnlocked)
        purchaseManager.$hasLoadedPurchaseState
            .assign(to: &$hasLoadedPurchaseState)
        $subtotalText
            .dropFirst()
            .filter { !$0.isEmpty }
            .first()
            .sink { [weak self] _ in self?.hasInteracted = true }
            .store(in: &cancellables)
    }

    // MARK: - Validation

    var validationError: ValidationError? {
        if subtotalText.isEmpty { return .missingSubtotal }
        guard let s = Decimal(string: subtotalText), s >= 0 else { return .invalidSubtotal }
        if !taxText.isEmpty {
            guard let t = Decimal(string: taxText), t >= 0 else { return .invalidTax }
        }
        if !tipText.isEmpty {
            guard let t = Decimal(string: tipText), t >= 0 else { return .invalidTip }
        }
        if peopleText.isEmpty { return .missingPeople }
        guard let p = Int(peopleText) else { return .invalidPeople }
        guard p >= 1 else { return .peopleMustBeAtLeastOne }
        if isExtraPayerEnabled, !extraAmountText.isEmpty {
            guard let ea = Decimal(string: extraAmountText), ea >= 0 else { return .invalidExtraAmount }
            let sub = Decimal(string: subtotalText) ?? 0
            let t = taxText.isEmpty ? 0 : (Decimal(string: taxText) ?? 0)
            let ti = tipText.isEmpty ? 0 : (Decimal(string: tipText) ?? 0)
            let tipAmt: Decimal = tipMode == .amount ? ti : sub * (ti / 100)
            if ea > sub + t + tipAmt { return .extraAmountExceedsTotal }
        }
        return nil
    }

    var errorMessage: String? {
        guard let error = validationError else { return nil }
        switch error {
        case .invalidSubtotal:         return "Enter a valid subtotal."
        case .invalidTax:              return "Enter a valid tax amount."
        case .invalidTip:              return "Enter a valid tip amount."
        case .invalidPeople:           return "Enter a valid number of people."
        case .peopleMustBeAtLeastOne:  return "People must be at least 1."
        case .missingSubtotal:         return hasInteracted ? "Enter a subtotal." : nil
        case .missingPeople:           return "Enter a number of people."
        case .invalidExtraAmount:      return "Enter a valid extra amount."
        case .extraAmountExceedsTotal: return "Extra amount cannot exceed the total."
        }
    }

    // MARK: - Result

    var result: CalculationResult? {
        guard validationError == nil else { return nil }
        guard !subtotalText.isEmpty,
              let subtotal = Decimal(string: subtotalText), subtotal >= 0,
              let people = Int(peopleText), people >= 1 else { return nil }
        let tax = Decimal(string: taxText) ?? 0
        let tipInput = Decimal(string: tipText) ?? 0
        let extraAmount = extraAmountText.isEmpty ? 0 : (Decimal(string: extraAmountText) ?? 0)
        return service.calculate(
            subtotal: subtotal,
            tax: tax,
            tipInput: tipInput,
            tipMode: tipMode,
            people: people,
            isRoundUpEnabled: isRoundUpEnabled && isProUnlocked,
            isExtraPayerEnabled: isExtraPayerEnabled && isProUnlocked,
            extraAmount: extraAmount
        )
    }

    // MARK: - Actions

    func toggleRoundUp() {
        guard isProUnlocked else { showPaywall = true; return }
        isRoundUpEnabled.toggle()
    }

    func toggleExtraPayer() {
        guard isProUnlocked else { showPaywall = true; return }
        isExtraPayerEnabled.toggle()
        if !isExtraPayerEnabled { extraAmountText = "" }
    }

    func purchase() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        try? await purchaseManager.purchase()
        if purchaseManager.isProUnlocked { showPaywall = false }
    }

    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        await purchaseManager.restore()
        if purchaseManager.isProUnlocked { showPaywall = false }
    }

    func reset() {
        subtotalText = ""
        taxText = ""
        tipText = ""
        peopleText = "2"
        tipMode = .amount
        isRoundUpEnabled = false
        isExtraPayerEnabled = false
        extraAmountText = ""
        hasInteracted = false
        // isProUnlocked is intentionally not reset
    }
}
