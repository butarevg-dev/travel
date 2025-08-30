import Foundation
import StoreKit
import Combine

@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()
    
    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var purchasedProducts: [Product] = []
    @Published var subscriptionStatus: SubscriptionStatus = .none
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentSubscription: SubscriptionProduct?
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    private var productsLoaded = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Service Dependencies
    private let userService = UserService.shared
    private let firestoreService = FirestoreService.shared
    private let analyticsService = AnalyticsService.shared
    
    // MARK: - Product IDs
    private let productIDs = [
        "com.saransk.tourist.premium.monthly",
        "com.saransk.tourist.premium.yearly",
        "com.saransk.tourist.premium.lifetime"
    ]
    
    private init() {
        setupStoreKitListener()
        loadProducts()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - StoreKit Setup
    private func setupStoreKitListener() {
        updateListenerTask = listenForTransactions()
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handleTransactionUpdate(result)
            }
        }
    }
    
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try result.payloadValue
            
            await self.updateSubscriptionStatus(for: transaction)
            await self.analyticsService.trackPurchase(
                productId: transaction.productID,
                price: transaction.price,
                currency: transaction.currencyCode ?? "USD"
            )
            
            await transaction.finish()
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    // MARK: - Product Loading
    func loadProducts() {
        guard !productsLoaded else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let storeProducts = try await Product.products(for: productIDs)
                await MainActor.run {
                    self.products = storeProducts
                    self.productsLoaded = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Purchase Methods
    func purchase(_ product: Product) async throws {
        isLoading = true
        error = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus(for: transaction)
                await analyticsService.trackPurchase(
                    productId: transaction.productID,
                    price: transaction.price,
                    currency: transaction.currencyCode ?? "USD"
                )
                await transaction.finish()
                
            case .userCancelled:
                error = "Покупка отменена пользователем"
                
            case .pending:
                error = "Покупка ожидает подтверждения"
                
            @unknown default:
                error = "Неизвестная ошибка покупки"
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func purchaseSubscription(_ product: SubscriptionProduct) async throws {
        guard let storeProduct = products.first(where: { $0.id == product.id }) else {
            throw StoreKitError.productNotFound
        }
        
        try await purchase(storeProduct)
    }
    
    // MARK: - Subscription Management
    func checkSubscriptionStatus() async {
        do {
            var hasActiveSubscription = false
            
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    
                    if transaction.productType == .autoRenewable {
                        hasActiveSubscription = true
                        await updateSubscriptionStatus(for: transaction)
                        break
                    }
                } catch {
                    continue
                }
            }
            
            if !hasActiveSubscription {
                await MainActor.run {
                    self.subscriptionStatus = .none
                    self.currentSubscription = nil
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    private func updateSubscriptionStatus(for transaction: Transaction) async {
        let productId = transaction.productID
        
        // Определяем тип подписки по ID продукта
        let newStatus: SubscriptionStatus
        let subscriptionProduct: SubscriptionProduct?
        
        switch productId {
        case "com.saransk.tourist.premium.monthly":
            newStatus = .basic
            subscriptionProduct = createSubscriptionProduct(
                id: productId,
                title: "Базовая подписка",
                description: "Ежемесячная подписка",
                price: transaction.price,
                currency: transaction.currencyCode ?? "RUB",
                period: .monthly,
                features: [.exclusiveRoutes, .extendedOffline]
            )
            
        case "com.saransk.tourist.premium.yearly":
            newStatus = .premium
            subscriptionProduct = createSubscriptionProduct(
                id: productId,
                title: "Премиум подписка",
                description: "Годовая подписка (экономия 40%)",
                price: transaction.price,
                currency: transaction.currencyCode ?? "RUB",
                period: .yearly,
                features: PremiumFeature.allCases,
                isPopular: true,
                savings: 40
            )
            
        case "com.saransk.tourist.premium.lifetime":
            newStatus = .premium
            subscriptionProduct = createSubscriptionProduct(
                id: productId,
                title: "Пожизненный доступ",
                description: "Пожизненный доступ ко всем функциям",
                price: transaction.price,
                currency: transaction.currencyCode ?? "RUB",
                period: .lifetime,
                features: PremiumFeature.allCases
            )
            
        default:
            newStatus = .none
            subscriptionProduct = nil
        }
        
        await MainActor.run {
            self.subscriptionStatus = newStatus
            self.currentSubscription = subscriptionProduct
        }
        
        // Обновляем профиль пользователя
        if let user = userService.currentProfile {
            let premiumUntil: Date
            switch productId {
            case "com.saransk.tourist.premium.lifetime":
                premiumUntil = Date.distantFuture
            case "com.saransk.tourist.premium.yearly":
                premiumUntil = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            default:
                premiumUntil = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            }
            
            await userService.setPremiumUntil(premiumUntil)
        }
    }
    
    private func createSubscriptionProduct(
        id: String,
        title: String,
        description: String,
        price: Decimal,
        currency: String,
        period: SubscriptionPeriod,
        features: [PremiumFeature],
        isPopular: Bool = false,
        savings: Int? = nil
    ) -> SubscriptionProduct {
        return SubscriptionProduct(
            id: id,
            title: title,
            description: description,
            price: price,
            currency: currency,
            period: period,
            features: features,
            isPopular: isPopular,
            savings: savings
        )
    }
    
    // MARK: - Utility Methods
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    func getProduct(by id: String) -> Product? {
        return products.first { $0.id == id }
    }
    
    func isProductPurchased(_ product: Product) -> Bool {
        return purchasedProducts.contains { $0.id == product.id }
    }
    
    func restorePurchases() async {
        isLoading = true
        error = nil
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Premium Feature Checks
    func hasPremiumFeature(_ feature: PremiumFeature) -> Bool {
        return subscriptionStatus.features.contains(feature)
    }
    
    func getAvailableFeatures() -> [PremiumFeature] {
        return subscriptionStatus.features
    }
    
    // MARK: - Analytics Integration
    func trackSubscriptionEvent(_ event: String, product: Product? = nil) {
        var parameters: [String: String] = [
            "subscription_status": subscriptionStatus.rawValue
        ]
        
        if let product = product {
            parameters["product_id"] = product.id
            parameters["product_price"] = product.price.description
        }
        
        analyticsService.trackEvent(event, parameters: parameters)
    }
}

// MARK: - StoreKit Errors
enum StoreKitError: LocalizedError {
    case productNotFound
    case verificationFailed
    case purchaseFailed
    case subscriptionExpired
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Продукт не найден"
        case .verificationFailed:
            return "Ошибка верификации покупки"
        case .purchaseFailed:
            return "Ошибка покупки"
        case .subscriptionExpired:
            return "Подписка истекла"
        }
    }
}

// MARK: - Mock Data for Development
extension StoreKitService {
    func loadMockProducts() {
        let mockProducts = [
            createSubscriptionProduct(
                id: "com.saransk.tourist.premium.monthly",
                title: "Базовая подписка",
                description: "Ежемесячная подписка",
                price: 299,
                currency: "RUB",
                period: .monthly,
                features: [.exclusiveRoutes, .extendedOffline]
            ),
            createSubscriptionProduct(
                id: "com.saransk.tourist.premium.yearly",
                title: "Премиум подписка",
                description: "Годовая подписка (экономия 40%)",
                price: 1999,
                currency: "RUB",
                period: .yearly,
                features: PremiumFeature.allCases,
                isPopular: true,
                savings: 40
            ),
            createSubscriptionProduct(
                id: "com.saransk.tourist.premium.lifetime",
                title: "Пожизненный доступ",
                description: "Пожизненный доступ ко всем функциям",
                price: 4999,
                currency: "RUB",
                period: .lifetime,
                features: PremiumFeature.allCases
            )
        ]
        
        self.currentSubscription = mockProducts[1] // Премиум как популярный
        self.subscriptionStatus = .premium
    }
}