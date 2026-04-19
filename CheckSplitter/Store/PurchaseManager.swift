import Combine
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let proProductID = "com.checksplitter.pro"

    @Published private(set) var isProUnlocked = false
    @Published private(set) var hasLoadedPurchaseState = false
    private(set) var proProduct: Product?
    private var listenTask: Task<Void, Never>?

    init() {
        listenTask = Task { await listenForTransactions() }
        Task {
            await loadProduct()
            await refreshStatus()
        }
    }

    deinit {
        listenTask?.cancel()
    }

    private func loadProduct() async {
        guard let products = try? await Product.products(for: [Self.proProductID]) else { return }
        proProduct = products.first
    }

    private func refreshStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.productID == Self.proProductID { isProUnlocked = true }
        }
        hasLoadedPurchaseState = true
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let tx) = result else { continue }
            if tx.productID == Self.proProductID { isProUnlocked = true }
            await tx.finish()
        }
    }

    func purchase() async throws {
        if proProduct == nil { await loadProduct() }
        guard let proProduct else { return }
        let result = try await proProduct.purchase()
        if case .success(let verification) = result,
           case .verified(let tx) = verification {
            isProUnlocked = true
            await tx.finish()
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshStatus()
    }
}
