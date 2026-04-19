import Testing
@testable import CheckSplitter

struct CalculationServiceTests {
    let service = CalculationService()

    // MARK: - Amount mode

    @Test func equalSplitAmountMode() throws {
        let result = try #require(service.calculate(
            subtotal: 100,
            tax: 10,
            tipInput: 15,
            tipMode: .amount,
            people: 2
        ))
        #expect(result.tip == 15)
        #expect(result.total == 125)
        #expect(result.eachPersonPays == Decimal(string: "62.5")!)
        #expect(result.extraPayerPays == nil)
        #expect(result.otherPersonPays == nil)
        #expect(result.isRounded == false)
    }

    @Test func amountModeZeroTax() throws {
        let result = try #require(service.calculate(
            subtotal: 50,
            tax: 0,
            tipInput: 5,
            tipMode: .amount,
            people: 2
        ))
        #expect(result.tip == 5)
        #expect(result.total == 55)
        #expect(result.eachPersonPays == Decimal(string: "27.5")!)
    }

    @Test func amountModeZeroTip() throws {
        let result = try #require(service.calculate(
            subtotal: 100,
            tax: 8,
            tipInput: 0,
            tipMode: .amount,
            people: 4
        ))
        #expect(result.tip == 0)
        #expect(result.total == 108)
        #expect(result.eachPersonPays == 27)
    }

    @Test func amountModeSinglePerson() throws {
        let result = try #require(service.calculate(
            subtotal: 40,
            tax: 4,
            tipInput: 6,
            tipMode: .amount,
            people: 1
        ))
        #expect(result.total == 50)
        #expect(result.eachPersonPays == 50)
    }

    // MARK: - Percentage mode

    @Test func equalSplitPercentageMode() throws {
        let result = try #require(service.calculate(
            subtotal: 100,
            tax: 10,
            tipInput: 15,
            tipMode: .percentage,
            people: 2
        ))
        #expect(result.tip == 15)
        #expect(result.total == 125)
        #expect(result.eachPersonPays == Decimal(string: "62.5")!)
    }

    @Test func percentageModeZeroTip() throws {
        let result = try #require(service.calculate(
            subtotal: 100,
            tax: 0,
            tipInput: 0,
            tipMode: .percentage,
            people: 4
        ))
        #expect(result.tip == 0)
        #expect(result.total == 100)
        #expect(result.eachPersonPays == 25)
    }

    @Test func percentageModeTipCalculatedFromSubtotal() throws {
        // tip% is applied to subtotal only, not subtotal+tax
        let result = try #require(service.calculate(
            subtotal: 200,
            tax: 20,
            tipInput: 10,
            tipMode: .percentage,
            people: 4
        ))
        #expect(result.tip == 20)     // 200 * 10/100
        #expect(result.total == 240)  // 200 + 20 + 20
        #expect(result.eachPersonPays == 60)
    }

    // MARK: - Result fields

    @Test func resultPreservesInputFields() throws {
        let result = try #require(service.calculate(
            subtotal: 80,
            tax: 8,
            tipInput: 12,
            tipMode: .amount,
            people: 3
        ))
        #expect(result.subtotal == 80)
        #expect(result.tax == 8)
        #expect(result.people == 3)
    }

    // MARK: - Invalid people

    @Test func invalidPeopleZeroReturnsNil() {
        let result = service.calculate(
            subtotal: 100,
            tax: 10,
            tipInput: 15,
            tipMode: .amount,
            people: 0
        )
        #expect(result == nil)
    }

    @Test func invalidPeopleNegativeReturnsNil() {
        let result = service.calculate(
            subtotal: 100,
            tax: 10,
            tipInput: 15,
            tipMode: .amount,
            people: -1
        )
        #expect(result == nil)
    }

    // MARK: - Round up

    @Test func roundUpOn() throws {
        // total=100, people=3 → share=33.333... → ceil=34
        let result = try #require(service.calculate(
            subtotal: 100, tax: 0, tipInput: 0, tipMode: .amount, people: 3,
            isRoundUpEnabled: true
        ))
        #expect(result.eachPersonPays == 34)
        #expect(result.isRounded == true)
        #expect(result.extraPayerPays == nil)
    }

    @Test func roundUpAlreadyWhole() throws {
        // total=120, people=4 → share=30.00 → ceil=30
        let result = try #require(service.calculate(
            subtotal: 120, tax: 0, tipInput: 0, tipMode: .amount, people: 4,
            isRoundUpEnabled: true
        ))
        #expect(result.eachPersonPays == 30)
        #expect(result.isRounded == true)
    }

    // MARK: - Extra payer

    @Test func extraPayerOn() throws {
        // total=100, people=5, extra=20
        // baseShare=20, epPays=40, remaining=60, others=15
        let result = try #require(service.calculate(
            subtotal: 100, tax: 0, tipInput: 0, tipMode: .amount, people: 5,
            isExtraPayerEnabled: true, extraAmount: 20
        ))
        #expect(result.extraPayerPays == 40)
        #expect(result.otherPersonPays == 15)
        #expect(result.eachPersonPays == nil)
        #expect(result.isRounded == false)
    }

    @Test func extraPayerZeroExtraAmount() throws {
        // extra=0 → everyone pays equal
        let result = try #require(service.calculate(
            subtotal: 100, tax: 0, tipInput: 0, tipMode: .amount, people: 4,
            isExtraPayerEnabled: true, extraAmount: 0
        ))
        #expect(result.extraPayerPays == 25)
        #expect(result.otherPersonPays == 25)
    }

    @Test func extraPayerRequiresTwoPeople() {
        let result = service.calculate(
            subtotal: 100, tax: 0, tipInput: 0, tipMode: .amount, people: 1,
            isExtraPayerEnabled: true, extraAmount: 10
        )
        #expect(result == nil)
    }

    // MARK: - Extra payer + round up

    @Test func extraPayerPlusRoundUp() throws {
        // total=100, people=4, extra=10
        // baseShare=25, epRaw=35, remaining=65, opRaw=65/3=21.666...
        // ceil(35)=35, ceil(21.666...)=22
        let result = try #require(service.calculate(
            subtotal: 100, tax: 0, tipInput: 0, tipMode: .amount, people: 4,
            isRoundUpEnabled: true, isExtraPayerEnabled: true, extraAmount: 10
        ))
        #expect(result.extraPayerPays == 35)
        #expect(result.otherPersonPays == 22)
        #expect(result.isRounded == true)
    }
}

@MainActor
struct MainCalculatorViewModelTests {
    @Test func emptySubtotalReturnsMissing() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = ""
        #expect(vm.validationError == .missingSubtotal)
        #expect(vm.result == nil)
    }

    @Test func emptyPeopleReturnsMissing() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.peopleText = ""
        #expect(vm.validationError == .missingPeople)
        #expect(vm.result == nil)
    }

    @Test func invalidSubtotalShowsError() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "abc"
        #expect(vm.validationError == .invalidSubtotal)
        #expect(vm.result == nil)
    }

    @Test func invalidTaxShowsError() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.taxText = "xyz"
        #expect(vm.validationError == .invalidTax)
        #expect(vm.result == nil)
    }

    @Test func invalidTipShowsError() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.tipText = "!"
        #expect(vm.validationError == .invalidTip)
        #expect(vm.result == nil)
    }

    @Test func invalidPeopleShowsError() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.peopleText = "abc"
        #expect(vm.validationError == .invalidPeople)
        #expect(vm.result == nil)
    }

    @Test func peopleLessThanOneShowsError() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.peopleText = "0"
        #expect(vm.validationError == .peopleMustBeAtLeastOne)
        #expect(vm.result == nil)
    }

    @Test func emptyTaxTreatedAsZero() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.taxText = ""
        #expect(vm.validationError == nil)
        #expect(vm.result != nil)
    }

    @Test func emptyTipTreatedAsZero() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.tipText = ""
        #expect(vm.validationError == nil)
        #expect(vm.result != nil)
    }

    // MARK: - Extra amount validation

    @Test func invalidExtraAmountShowsError() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.isExtraPayerEnabled = true
        vm.extraAmountText = "abc"
        #expect(vm.validationError == .invalidExtraAmount)
        #expect(vm.result == nil)
    }

    @Test func extraAmountExceedsTotalShowsError() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.isExtraPayerEnabled = true
        vm.extraAmountText = "150"
        #expect(vm.validationError == .extraAmountExceedsTotal)
        #expect(vm.result == nil)
    }

    @Test func emptyExtraAmountTreatedAsZero() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.isExtraPayerEnabled = true
        vm.extraAmountText = ""
        #expect(vm.validationError == nil)
    }

    @Test func missingSubtotalInPristineStateShowsNoErrorMessage() {
        let vm = MainCalculatorViewModel()
        // pristine: subtotal was never entered, no error message shown
        #expect(vm.validationError == .missingSubtotal)
        #expect(vm.errorMessage == nil)
        #expect(vm.result == nil)
    }

    @Test func missingSubtotalAfterInteractionShowsErrorMessage() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"   // triggers hasInteracted = true
        vm.subtotalText = ""      // user clears it
        #expect(vm.validationError == .missingSubtotal)
        #expect(vm.errorMessage == "Enter a subtotal.")
        #expect(vm.result == nil)
    }

    @Test func missingPeopleShowsErrorMessage() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "100"
        vm.peopleText = ""
        #expect(vm.validationError == .missingPeople)
        #expect(vm.errorMessage == "Enter a number of people.")
        #expect(vm.result == nil)
    }

    @Test func resetClearsInputsPreservesProState() {
        let vm = MainCalculatorViewModel()
        vm.subtotalText = "120"
        vm.taxText = "10"
        vm.tipText = "15"
        vm.peopleText = "4"
        vm.tipMode = .percentage
        vm.isRoundUpEnabled = true
        vm.isExtraPayerEnabled = true
        vm.extraAmountText = "5"
        vm.reset()
        #expect(vm.subtotalText == "")
        #expect(vm.taxText == "")
        #expect(vm.tipText == "")
        #expect(vm.peopleText == "2")
        #expect(vm.tipMode == .amount)
        #expect(vm.isRoundUpEnabled == false)
        #expect(vm.isExtraPayerEnabled == false)
        #expect(vm.extraAmountText == "")
        #expect(vm.isProUnlocked == false)
    }
}
