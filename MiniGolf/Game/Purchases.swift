import Foundation
import Observation
import StoreKit

/// All Courses: the one purchase, a non-consumable that opens every hole past the free ones (`Levels.freeHoles`),
/// courses added later included. Family Sharing is on for it in App Store Connect. Xcode builds buy it from
/// DoublePutt.storekit, TestFlight builds in the sandbox (free), and the App Store for real. Modeled on Bigger
/// Fish's `ArcadePurchases`.
@MainActor
@Observable
final class Purchases {
    /// Permanent once created in App Store Connect.
    static let productID = "com.kraigstrong.doubleputt.fullgame"

    enum Outcome { case bought, pending, cancelled, failed }

    /// Cached, so the menus draw right at launch and offline; StoreKit confirms it.
    private(set) var ownsAllCourses: Bool
    private(set) var product: Product?

    /// The localized price, e.g. "$4.99", once the product has loaded.
    var displayPrice: String? { product?.displayPrice }

    private static let ownedKey = "ownsAllCourses"
    /// A Debug launch with `-owned YES` (or `NO`), or a store capture, which plays every hole: what it says stands,
    /// and StoreKit isn't asked.
    @ObservationIgnored private let pinned: Bool
    @ObservationIgnored private var updates: Task<Void, Never>?

    init() {
        #if DEBUG
        let pin: Bool? = StoreCapture.isActive ? true : Self.launchPin
        #else
        let pin: Bool? = nil
        #endif
        pinned = pin != nil
        ownsAllCourses = pin ?? UserDefaults.standard.bool(forKey: Self.ownedKey)
    }

    #if DEBUG
    private static var launchPin: Bool? {
        guard UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)["owned"] != nil else { return nil }
        return UserDefaults.standard.bool(forKey: "owned")
    }
    #endif

    /// Starts listening for transactions (a purchase approved later through Ask to Buy, one made on another device or
    /// by family, a refund) and checks what's owned. Call once at launch.
    func start() {
        guard !pinned, updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result, transaction.productID == Self.productID {
                    await transaction.finish()
                    await self?.refresh()
                }
            }
        }
        Task { [weak self] in
            await self?.refresh()
            await self?.loadProduct()
        }
    }

    /// Re-reads the current entitlements. A refunded or revoked purchase drops out of them.
    func refresh() async {
        guard !pinned else { return }
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        setOwned(owned)
    }

    func loadProduct() async {
        guard product == nil else { return }
        product = try? await Product.products(for: [Self.productID]).first
    }

    func purchase() async -> Outcome {
        await loadProduct()
        guard let product else { return .failed }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                setOwned(true)
                return .bought
            case .success(.unverified):
                return .failed
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    /// Syncs with the App Store (it may ask to sign in), then checks again. True if All Courses is owned.
    func restore() async -> Bool {
        try? await AppStore.sync()
        await refresh()
        return ownsAllCourses
    }

    private func setOwned(_ owned: Bool) {
        guard !pinned, owned != ownsAllCourses else { return }
        ownsAllCourses = owned
        UserDefaults.standard.set(owned, forKey: Self.ownedKey)
    }
}
