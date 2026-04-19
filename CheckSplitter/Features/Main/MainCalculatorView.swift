import SwiftUI

struct MainCalculatorView: View {
    @StateObject private var vm = MainCalculatorViewModel()

    private enum Field { case subtotal, tax, tip, people, extraAmount }
    @FocusState private var focusedField: Field?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                billInputCard
                optionsSection
                if let message = vm.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                if vm.validationError == nil {
                    resultCard
                }
                if vm.hasLoadedPurchaseState && !vm.isProUnlocked {
                    upgradeCard
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeOut(duration: 0.35), value: vm.hasLoadedPurchaseState)
                }
                resetButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
            .contentShape(Rectangle())
            .onTapGesture { focusedField = nil }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $vm.showPaywall) {
            paywallSheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Check Splitter")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Split one restaurant bill fast.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Bill Input Card

    private var billInputCard: some View {
        VStack(spacing: 0) {
            currencyInputRow(label: "Subtotal", text: $vm.subtotalText, field: .subtotal)
            Divider().padding(.leading, 16)
            currencyInputRow(label: "Tax", text: $vm.taxText, field: .tax)
            Divider().padding(.leading, 16)
            tipInputRow
            Divider().padding(.leading, 16)
            peopleInputRow
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func currencyInputRow(label: String, text: Binding<String>, field: Field) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("$")
                .foregroundStyle(.secondary)
            TextField("0.00", text: text)
                .font(.system(size: 18))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .focused($focusedField, equals: field)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var tipInputRow: some View {
        HStack {
            Text("Tip")
            Spacer()
            if vm.tipMode == .amount {
                Text("$").foregroundStyle(.secondary)
            }
            TextField(vm.tipMode == .amount ? "0.00" : "15", text: $vm.tipText)
                .font(.system(size: 18))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: vm.tipMode == .amount ? 90 : 60)
                .focused($focusedField, equals: .tip)
            if vm.tipMode == .percentage {
                Text("%").foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var peopleInputRow: some View {
        HStack {
            Text("People")
            Spacer()
            TextField("2", text: $vm.peopleText)
                .font(.system(size: 18))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .focused($focusedField, equals: .people)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Options")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                tipModeRow
                Divider().padding(.leading, 16)
                roundUpRow
                Divider().padding(.leading, 16)
                extraPersonRow
                if vm.isProUnlocked && vm.isExtraPayerEnabled {
                    Divider().padding(.leading, 16)
                    extraAmountRow
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }

    private var tipModeRow: some View {
        HStack {
            Text("Tip Mode")
            Spacer()
            Picker("Tip Mode", selection: $vm.tipMode) {
                Text("Amount").tag(TipMode.amount)
                Text("Percentage").tag(TipMode.percentage)
            }
            .pickerStyle(.segmented)
            .frame(width: 176)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var roundUpRow: some View {
        HStack {
            Text("Round Up")
            proBadge
            Spacer()
            if vm.isProUnlocked {
                Toggle("", isOn: $vm.isRoundUpEnabled)
                    .tint(.blue)
                    .labelsHidden()
            } else {
                Button { vm.toggleRoundUp() } label: {
                    HStack(spacing: 6) {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .frame(width: 51, height: 31)
                                .foregroundStyle(Color(.systemGray4))
                            Circle()
                                .frame(width: 27, height: 27)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                                .padding(.leading, 2)
                        }
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var extraPersonRow: some View {
        HStack {
            Text("Extra Person Pays")
            proBadge
            Spacer()
            if vm.isProUnlocked {
                Toggle("", isOn: $vm.isExtraPayerEnabled)
                    .tint(.blue)
                    .labelsHidden()
            } else {
                Button { vm.toggleExtraPayer() } label: {
                    HStack(spacing: 6) {
                        Text("$0.00").foregroundStyle(.secondary)
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var extraAmountRow: some View {
        HStack {
            Text("Extra Amount")
            Spacer()
            Text("$").foregroundStyle(.secondary)
            TextField("0.00", text: $vm.extraAmountText)
                .font(.system(size: 18))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .focused($focusedField, equals: .extraAmount)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var proBadge: some View {
        Text("Pro")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue)
            .clipShape(Capsule())
    }

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(spacing: 6) {
            Text("Total Bill")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Text(vm.result.map { CurrencyFormatter.format($0.total) } ?? "$0.00")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 1)
                .padding(.vertical, 6)

            if let result = vm.result, let epPays = result.extraPayerPays {
                Text("Extra Payer Pays")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text(CurrencyFormatter.format(epPays))
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
                if let opPays = result.otherPersonPays {
                    VStack(spacing: 2) {
                        Text("Others Pay")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                        Text(CurrencyFormatter.format(opPays))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("Each Person Pays")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text(vm.result.flatMap(\.eachPersonPays).map(CurrencyFormatter.format) ?? "$0.00")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
            }

            if vm.result?.isRounded == true {
                Text("Rounded up for simplicity")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.70))
                    .padding(.top, 4)
            }

            if vm.tipMode == .percentage, let result = vm.result {
                Text("Calculated tip: \(CurrencyFormatter.format(result.tip))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.70))
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.27, green: 0.50, blue: 0.87),
                    Color(red: 0.17, green: 0.34, blue: 0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.blue.opacity(0.28), radius: 10, y: 5)
    }

    // MARK: - Upgrade Card

    private var upgradeCard: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Unlock Pro Features")
                    .font(.headline)
                Text("Get Round Up & Extra Payer!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button { vm.showPaywall = true } label: {
                Text("Upgrade to Pro")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - Paywall Sheet

    private var paywallSheet: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.open.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.blue)
            Text("Unlock Pro Features")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Get Round Up & Extra Payer!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                Task { await vm.purchase() }
            } label: {
                HStack {
                    if vm.isPurchasing {
                        ProgressView().tint(.white)
                    }
                    Text(vm.isPurchasing ? "Processing…" : "Upgrade to Pro")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(vm.isPurchasing)
            Button {
                Task { await vm.restore() }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .disabled(vm.isPurchasing)
            Button { vm.showPaywall = false } label: {
                Text("Not Now")
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button {
            vm.reset()
        } label: {
            Text("Reset")
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.horizontal, 28)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                )
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    MainCalculatorView()
}
