import Foundation
import Combine

@MainActor
class PartnerService: ObservableObject {
    static let shared = PartnerService()
    
    // MARK: - Published Properties
    @Published var partnerOffers: [PartnerOffer] = []
    @Published var userOffers: [UserOffer] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedCategory: String = "all"
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Service Dependencies
    private let firestoreService = FirestoreService.shared
    private let analyticsService = AnalyticsService.shared
    private let userService = UserService.shared
    
    private init() {
        loadPartnerOffers()
        loadUserOffers()
    }
    
    // MARK: - Partner Offers Management
    func loadPartnerOffers() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let offers = try await firestoreService.fetchPartnerOffers()
                await MainActor.run {
                    self.partnerOffers = offers
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
    
    func loadUserOffers() {
        guard let userId = userService.currentProfile?.id else { return }
        
        Task {
            do {
                let offers = try await firestoreService.fetchUserOffers(userId: userId)
                await MainActor.run {
                    self.userOffers = offers
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Offer Activation
    func activateOffer(_ offer: PartnerOffer) async {
        guard let userId = userService.currentProfile?.id else {
            error = "Пользователь не авторизован"
            return
        }
        
        guard offer.isAvailable else {
            error = "Предложение недоступно"
            return
        }
        
        do {
            // Создаем пользовательское предложение
            let userOffer = UserOffer(
                id: UUID().uuidString,
                offerId: offer.id,
                userId: userId,
                activatedAt: Date(),
                usedAt: nil,
                status: .active,
                partnerOffer: offer
            )
            
            // Сохраняем в Firestore
            try await firestoreService.saveUserOffer(userOffer)
            
            // Обновляем счетчик использования
            try await firestoreService.updatePartnerOfferUsage(offer.id)
            
            // Отслеживаем в аналитике
            await analyticsService.trackOfferActivation(offer)
            
            // Обновляем локальные данные
            await MainActor.run {
                self.userOffers.append(userOffer)
                self.loadPartnerOffers() // Обновляем счетчики
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    func useOffer(_ userOffer: UserOffer) async {
        guard let userId = userService.currentProfile?.id else {
            error = "Пользователь не авторизован"
            return
        }
        
        guard userOffer.isActive else {
            error = "Предложение уже использовано или истекло"
            return
        }
        
        do {
            // Обновляем статус предложения
            var updatedOffer = userOffer
            updatedOffer = UserOffer(
                id: userOffer.id,
                offerId: userOffer.offerId,
                userId: userOffer.userId,
                activatedAt: userOffer.activatedAt,
                usedAt: Date(),
                status: .used,
                partnerOffer: userOffer.partnerOffer
            )
            
            // Сохраняем в Firestore
            try await firestoreService.updateUserOffer(updatedOffer)
            
            // Отслеживаем использование в аналитике
            if let partnerOffer = userOffer.partnerOffer {
                await analyticsService.trackOfferUsage(partnerOffer)
            }
            
            // Обновляем локальные данные
            await MainActor.run {
                if let index = self.userOffers.firstIndex(where: { $0.id == userOffer.id }) {
                    self.userOffers[index] = updatedOffer
                }
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    // MARK: - Filtering and Search
    var filteredOffers: [PartnerOffer] {
        guard selectedCategory != "all" else {
            return partnerOffers.filter { $0.isAvailable }
        }
        return partnerOffers.filter { $0.isAvailable && $0.category == selectedCategory }
    }
    
    var availableCategories: [String] {
        let categories = Set(partnerOffers.map { $0.category })
        return ["all"] + Array(categories).sorted()
    }
    
    func getOffersByCategory(_ category: String) -> [PartnerOffer] {
        if category == "all" {
            return partnerOffers.filter { $0.isAvailable }
        }
        return partnerOffers.filter { $0.isAvailable && $0.category == category }
    }
    
    func getOffersByPartner(_ partnerId: String) -> [PartnerOffer] {
        return partnerOffers.filter { $0.isAvailable && $0.partnerId == partnerId }
    }
    
    // MARK: - User Offers Management
    var activeUserOffers: [UserOffer] {
        return userOffers.filter { $0.isActive }
    }
    
    var usedUserOffers: [UserOffer] {
        return userOffers.filter { $0.status == .used }
    }
    
    var expiredUserOffers: [UserOffer] {
        return userOffers.filter { $0.status == .expired }
    }
    
    func getUserOffer(for partnerOfferId: String) -> UserOffer? {
        return userOffers.first { $0.offerId == partnerOfferId }
    }
    
    func hasActiveOffer(for partnerOfferId: String) -> Bool {
        return userOffers.contains { $0.offerId == partnerOfferId && $0.isActive }
    }
    
    // MARK: - Analytics and Tracking
    func trackOfferView(_ offer: PartnerOffer) {
        analyticsService.trackEvent("offer_viewed", parameters: [
            "offer_id": offer.id,
            "partner_id": offer.partnerId,
            "category": offer.category,
            "discount": String(offer.discount)
        ])
    }
    
    func trackOfferClick(_ offer: PartnerOffer) {
        analyticsService.trackEvent("offer_clicked", parameters: [
            "offer_id": offer.id,
            "partner_id": offer.partnerId,
            "category": offer.category
        ])
    }
    
    // MARK: - Revenue Tracking
    func calculateTotalRevenue() -> Double {
        return userOffers
            .filter { $0.status == .used }
            .compactMap { $0.partnerOffer?.commission }
            .reduce(0, +)
    }
    
    func calculateRevenueByPartner(_ partnerId: String) -> Double {
        return userOffers
            .filter { $0.status == .used && $0.partnerOffer?.partnerId == partnerId }
            .compactMap { $0.partnerOffer?.commission }
            .reduce(0, +)
    }
    
    func calculateRevenueByCategory(_ category: String) -> Double {
        return userOffers
            .filter { $0.status == .used && $0.partnerOffer?.category == category }
            .compactMap { $0.partnerOffer?.commission }
            .reduce(0, +)
    }
    
    // MARK: - Partner Statistics
    func getPartnerStatistics() -> [String: PartnerStatistics] {
        var statistics: [String: PartnerStatistics] = [:]
        
        for offer in partnerOffers {
            let partnerId = offer.partnerId
            let partnerName = offer.partnerName
            
            if statistics[partnerId] == nil {
                statistics[partnerId] = PartnerStatistics(
                    partnerId: partnerId,
                    partnerName: partnerName,
                    totalOffers: 0,
                    activeOffers: 0,
                    totalUses: 0,
                    totalRevenue: 0
                )
            }
            
            statistics[partnerId]?.totalOffers += 1
            if offer.isAvailable {
                statistics[partnerId]?.activeOffers += 1
            }
            statistics[partnerId]?.totalUses += offer.currentUses
            statistics[partnerId]?.totalRevenue += Double(offer.currentUses) * offer.commission
        }
        
        return statistics
    }
    
    // MARK: - Refresh Data
    func refreshData() {
        loadPartnerOffers()
        loadUserOffers()
    }
}

// MARK: - Partner Statistics
struct PartnerStatistics {
    let partnerId: String
    let partnerName: String
    var totalOffers: Int
    var activeOffers: Int
    var totalUses: Int
    var totalRevenue: Double
    
    var conversionRate: Double {
        guard totalOffers > 0 else { return 0 }
        return Double(activeOffers) / Double(totalOffers)
    }
    
    var averageRevenuePerOffer: Double {
        guard totalOffers > 0 else { return 0 }
        return totalRevenue / Double(totalOffers)
    }
}

// MARK: - Mock Data for Development
extension PartnerService {
    func loadMockData() {
        let mockOffers = [
            PartnerOffer(
                id: "offer_1",
                partnerId: "partner_1",
                partnerName: "Ресторан 'Саранск'",
                title: "Скидка 20% на ужин",
                description: "Скидка 20% на ужин в ресторане 'Саранск' при предъявлении купона",
                discount: 0.2,
                validUntil: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                category: "Рестораны",
                imageURL: nil,
                terms: "Купон действует только на ужин с 18:00 до 23:00",
                commission: 100,
                isActive: true,
                maxUses: 100,
                currentUses: 25
            ),
            PartnerOffer(
                id: "offer_2",
                partnerId: "partner_2",
                partnerName: "Отель 'Центральный'",
                title: "Скидка 15% на проживание",
                description: "Скидка 15% на проживание в отеле 'Центральный'",
                discount: 0.15,
                validUntil: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(),
                category: "Отели",
                imageURL: nil,
                terms: "Минимальное проживание 2 ночи",
                commission: 500,
                isActive: true,
                maxUses: 50,
                currentUses: 10
            ),
            PartnerOffer(
                id: "offer_3",
                partnerId: "partner_3",
                partnerName: "Музей истории",
                title: "Бесплатный вход",
                description: "Бесплатный вход в музей истории для туристов",
                discount: 1.0,
                validUntil: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                category: "Музеи",
                imageURL: nil,
                terms: "Только для туристов с приложением",
                commission: 50,
                isActive: true,
                maxUses: 200,
                currentUses: 75
            )
        ]
        
        self.partnerOffers = mockOffers
        self.isLoading = false
    }
}