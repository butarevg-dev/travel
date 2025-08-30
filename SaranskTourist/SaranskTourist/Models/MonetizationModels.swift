import Foundation
import StoreKit

// MARK: - Premium Features
enum PremiumFeature: String, CaseIterable, Codable {
    case exclusiveRoutes = "exclusive_routes"
    case extendedOffline = "extended_offline"
    case arQuests = "ar_quests"
    case advancedAnalytics = "advanced_analytics"
    case partnerOffers = "partner_offers"
    case eventAdvertising = "event_advertising"
    case prioritySupport = "priority_support"
    case customThemes = "custom_themes"
    
    var title: String {
        switch self {
        case .exclusiveRoutes:
            return "Эксклюзивные маршруты"
        case .extendedOffline:
            return "Расширенное офлайн использование"
        case .arQuests:
            return "AR квесты"
        case .advancedAnalytics:
            return "Расширенная аналитика"
        case .partnerOffers:
            return "Партнерские предложения"
        case .eventAdvertising:
            return "Реклама событий"
        case .prioritySupport:
            return "Приоритетная поддержка"
        case .customThemes:
            return "Пользовательские темы"
        }
    }
    
    var description: String {
        switch self {
        case .exclusiveRoutes:
            return "Доступ к эксклюзивным маршрутам, созданным экспертами"
        case .extendedOffline:
            return "Скачивание всего контента для использования без интернета"
        case .arQuests:
            return "Специальные AR квесты и достижения"
        case .advancedAnalytics:
            return "Подробная статистика ваших путешествий"
        case .partnerOffers:
            return "Специальные предложения от партнеров"
        case .eventAdvertising:
            return "Уведомления о событиях и рекламные предложения"
        case .prioritySupport:
            return "Приоритетная поддержка пользователей"
        case .customThemes:
            return "Возможность настройки внешнего вида приложения"
        }
    }
    
    var icon: String {
        switch self {
        case .exclusiveRoutes:
            return "map"
        case .extendedOffline:
            return "icloud.and.arrow.down"
        case .arQuests:
            return "camera.viewfinder"
        case .advancedAnalytics:
            return "chart.bar"
        case .partnerOffers:
            return "handshake"
        case .eventAdvertising:
            return "megaphone"
        case .prioritySupport:
            return "person.crop.circle.badge.questionmark"
        case .customThemes:
            return "paintbrush"
        }
    }
}

// MARK: - Subscription Status
enum SubscriptionStatus: String, Codable {
    case none = "none"
    case basic = "basic"
    case premium = "premium"
    case family = "family"
    case expired = "expired"
    
    var title: String {
        switch self {
        case .none:
            return "Без подписки"
        case .basic:
            return "Базовая подписка"
        case .premium:
            return "Премиум подписка"
        case .family:
            return "Семейная подписка"
        case .expired:
            return "Подписка истекла"
        }
    }
    
    var features: [PremiumFeature] {
        switch self {
        case .none:
            return []
        case .basic:
            return [.exclusiveRoutes, .extendedOffline]
        case .premium:
            return PremiumFeature.allCases
        case .family:
            return PremiumFeature.allCases
        case .expired:
            return []
        }
    }
}

// MARK: - Subscription Period
enum SubscriptionPeriod: String, Codable {
    case monthly = "monthly"
    case yearly = "yearly"
    case lifetime = "lifetime"
    
    var title: String {
        switch self {
        case .monthly:
            return "Месяц"
        case .yearly:
            return "Год"
        case .lifetime:
            return "Навсегда"
        }
    }
    
    var description: String {
        switch self {
        case .monthly:
            return "Ежемесячная подписка"
        case .yearly:
            return "Годовая подписка (экономия 40%)"
        case .lifetime:
            return "Пожизненный доступ"
        }
    }
}

// MARK: - Subscription Product
struct SubscriptionProduct: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let price: Decimal
    let currency: String
    let period: SubscriptionPeriod
    let features: [PremiumFeature]
    let isPopular: Bool
    let savings: Int? // Процент экономии для годовой подписки
    
    init(id: String, title: String, description: String, price: Decimal, currency: String, period: SubscriptionPeriod, features: [PremiumFeature], isPopular: Bool = false, savings: Int? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.currency = currency
        self.period = period
        self.features = features
        self.isPopular = isPopular
        self.savings = savings
    }
}

// MARK: - Partner Offer
struct PartnerOffer: Codable, Identifiable {
    let id: String
    let partnerId: String
    let partnerName: String
    let title: String
    let description: String
    let discount: Double
    let validUntil: Date
    let category: String
    let imageURL: String?
    let terms: String
    let commission: Double
    let isActive: Bool
    let maxUses: Int?
    let currentUses: Int
    
    var isExpired: Bool {
        return validUntil < Date()
    }
    
    var isAvailable: Bool {
        return isActive && !isExpired && (maxUses == nil || currentUses < maxUses!)
    }
    
    var discountText: String {
        return "Скидка \(Int(discount * 100))%"
    }
    
    var validUntilText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Действует до \(formatter.string(from: validUntil))"
    }
}

// MARK: - User Offer
struct UserOffer: Codable, Identifiable {
    let id: String
    let offerId: String
    let userId: String
    let activatedAt: Date
    let usedAt: Date?
    let status: OfferStatus
    let partnerOffer: PartnerOffer?
    
    var isActive: Bool {
        return status == .active && usedAt == nil
    }
    
    var daysSinceActivation: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: activatedAt, to: Date()).day ?? 0
    }
}

// MARK: - Offer Status
enum OfferStatus: String, Codable {
    case active = "active"
    case used = "used"
    case expired = "expired"
    
    var title: String {
        switch self {
        case .active:
            return "Активно"
        case .used:
            return "Использовано"
        case .expired:
            return "Истекло"
        }
    }
    
    var color: String {
        switch self {
        case .active:
            return "green"
        case .used:
            return "blue"
        case .expired:
            return "red"
        }
    }
}

// MARK: - Event
struct Event: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let location: Coordinates
    let category: String
    let imageURL: String?
    let price: Double?
    let maxParticipants: Int?
    let currentParticipants: Int
    let isPremium: Bool
    let partnerId: String?
    let advertisingBudget: Double?
    let isActive: Bool
    
    var isUpcoming: Bool {
        return startDate > Date()
    }
    
    var isOngoing: Bool {
        return startDate <= Date() && endDate >= Date()
    }
    
    var isPast: Bool {
        return endDate < Date()
    }
    
    var status: EventStatus {
        if isPast {
            return .past
        } else if isOngoing {
            return .ongoing
        } else {
            return .upcoming
        }
    }
    
    var priceText: String {
        if let price = price {
            return "\(Int(price)) ₽"
        } else {
            return "Бесплатно"
        }
    }
    
    var participantsText: String {
        if let maxParticipants = maxParticipants {
            return "\(currentParticipants)/\(maxParticipants)"
        } else {
            return "\(currentParticipants)"
        }
    }
    
    var isFull: Bool {
        guard let maxParticipants = maxParticipants else { return false }
        return currentParticipants >= maxParticipants
    }
}

// MARK: - Event Status
enum EventStatus: String, Codable {
    case upcoming = "upcoming"
    case ongoing = "ongoing"
    case past = "past"
    
    var title: String {
        switch self {
        case .upcoming:
            return "Скоро"
        case .ongoing:
            return "Сейчас"
        case .past:
            return "Завершено"
        }
    }
    
    var color: String {
        switch self {
        case .upcoming:
            return "blue"
        case .ongoing:
            return "green"
        case .past:
            return "gray"
        }
    }
}

// MARK: - User Event
struct UserEvent: Codable, Identifiable {
    let id: String
    let eventId: String
    let userId: String
    let registeredAt: Date
    let attendedAt: Date?
    let status: UserEventStatus
    let event: Event?
    
    var isRegistered: Bool {
        return status == .registered
    }
    
    var isAttended: Bool {
        return status == .attended
    }
    
    var isCancelled: Bool {
        return status == .cancelled
    }
    
    var daysUntilEvent: Int? {
        guard let event = event, event.isUpcoming else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: event.startDate).day
    }
}

// MARK: - User Event Status
enum UserEventStatus: String, Codable {
    case registered = "registered"
    case attended = "attended"
    case cancelled = "cancelled"
    
    var title: String {
        switch self {
        case .registered:
            return "Зарегистрирован"
        case .attended:
            return "Посетил"
        case .cancelled:
            return "Отменено"
        }
    }
    
    var color: String {
        switch self {
        case .registered:
            return "blue"
        case .attended:
            return "green"
        case .cancelled:
            return "red"
        }
    }
}

// MARK: - Revenue Tracking
struct RevenueData: Codable {
    let totalRevenue: Double
    let subscriptionRevenue: Double
    let partnerRevenue: Double
    let eventRevenue: Double
    let period: RevenuePeriod
    let currency: String
    
    var subscriptionPercentage: Double {
        guard totalRevenue > 0 else { return 0 }
        return (subscriptionRevenue / totalRevenue) * 100
    }
    
    var partnerPercentage: Double {
        guard totalRevenue > 0 else { return 0 }
        return (partnerRevenue / totalRevenue) * 100
    }
    
    var eventPercentage: Double {
        guard totalRevenue > 0 else { return 0 }
        return (eventRevenue / totalRevenue) * 100
    }
}

enum RevenuePeriod: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var title: String {
        switch self {
        case .daily:
            return "День"
        case .weekly:
            return "Неделя"
        case .monthly:
            return "Месяц"
        case .yearly:
            return "Год"
        }
    }
}

// MARK: - Analytics Event
struct AnalyticsEvent: Codable {
    let name: String
    let parameters: [String: String]
    let timestamp: Date
    let userId: String?
    let sessionId: String?
    
    init(name: String, parameters: [String: String] = [:], userId: String? = nil, sessionId: String? = nil) {
        self.name = name
        self.parameters = parameters
        self.timestamp = Date()
        self.userId = userId
        self.sessionId = sessionId
    }
}

// MARK: - Performance Metrics
struct PerformanceMetrics: Codable {
    let appLaunchTime: TimeInterval
    let mapLoadTime: TimeInterval
    let audioLoadTime: TimeInterval
    let arSessionStartTime: TimeInterval
    let memoryUsage: Int64
    let batteryUsage: Double
    let networkRequests: Int
    let errors: Int
    let timestamp: Date
    
    var isOptimal: Bool {
        return appLaunchTime < 3.0 &&
               mapLoadTime < 2.0 &&
               audioLoadTime < 1.0 &&
               arSessionStartTime < 5.0 &&
               memoryUsage < 100 * 1024 * 1024 && // 100MB
               batteryUsage < 20.0 &&
               errors == 0
    }
}

// MARK: - App Store Metrics
struct AppStoreMetrics: Codable {
    let downloads: Int
    let activeUsers: Int
    let retentionRate: Double
    let crashRate: Double
    let rating: Double
    let reviewCount: Int
    let subscriptionConversion: Double
    let revenue: Double
    let period: String
    
    var isHealthy: Bool {
        return retentionRate > 0.3 &&
               crashRate < 0.01 &&
               rating > 4.0 &&
               subscriptionConversion > 0.05
    }
}