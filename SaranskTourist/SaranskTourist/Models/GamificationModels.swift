import Foundation

// MARK: - Badge System
struct Badge: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let category: BadgeCategory
    let rarity: BadgeRarity
    let requirements: BadgeRequirements
    let reward: BadgeReward?
    let unlockedAt: Date?
    let progress: Double? // 0.0 to 1.0
    
    var isUnlocked: Bool {
        return unlockedAt != nil
    }
    
    var progressPercentage: Int {
        return Int((progress ?? 0.0) * 100)
    }
}

enum BadgeCategory: String, Codable, CaseIterable {
    case exploration = "exploration"      // Исследование
    case social = "social"               // Социальное
    case completion = "completion"       // Завершение
    case speed = "speed"                 // Скорость
    case special = "special"             // Специальные
    
    var localizedName: String {
        switch self {
        case .exploration: return "Исследование"
        case .social: return "Социальное"
        case .completion: return "Завершение"
        case .speed: return "Скорость"
        case .special: return "Специальные"
        }
    }
}

enum BadgeRarity: String, Codable, CaseIterable {
    case common = "common"       // Обычный
    case rare = "rare"           // Редкий
    case epic = "epic"           // Эпический
    case legendary = "legendary" // Легендарный
    
    var localizedName: String {
        switch self {
        case .common: return "Обычный"
        case .rare: return "Редкий"
        case .epic: return "Эпический"
        case .legendary: return "Легендарный"
        }
    }
    
    var color: String {
        switch self {
        case .common: return "badge_common"
        case .rare: return "badge_rare"
        case .epic: return "badge_epic"
        case .legendary: return "badge_legendary"
        }
    }
}

struct BadgeRequirements: Codable {
    let type: RequirementType
    let target: Int
    let timeLimit: TimeInterval? // в секундах, nil = без ограничений
    let specificPOIs: [String]? // конкретные POI для посещения
    let specificRoutes: [String]? // конкретные маршруты для прохождения
    
    enum RequirementType: String, Codable {
        case visitPOIs = "visit_pois"           // Посетить N POI
        case completeRoutes = "complete_routes" // Пройти N маршрутов
        case totalDistance = "total_distance"   // Пройти N км
        case totalTime = "total_time"           // Провести N часов
        case reviews = "reviews"                // Оставить N отзывов
        case questions = "questions"            // Задать N вопросов
        case socialInteractions = "social_interactions" // Социальные действия
        case consecutiveDays = "consecutive_days" // Подряд дней
        case specialEvents = "special_events"   // Специальные события
    }
}

struct BadgeReward: Codable {
    let type: RewardType
    let value: Int
    let description: String
    
    enum RewardType: String, Codable {
        case experience = "experience"     // Опыт
        case coins = "coins"              // Монеты
        case premiumDays = "premium_days" // Дни премиума
        case specialAccess = "special_access" // Специальный доступ
        case discount = "discount"        // Скидка
    }
}

// MARK: - Quest System
struct Quest: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: QuestCategory
    let difficulty: QuestDifficulty
    let requirements: QuestRequirements
    let rewards: [QuestReward]
    let timeLimit: TimeInterval? // в секундах
    let isRepeatable: Bool
    let isActive: Bool
    let startedAt: Date?
    let completedAt: Date?
    let progress: QuestProgress
    
    var isCompleted: Bool {
        return completedAt != nil
    }
    
    var isStarted: Bool {
        return startedAt != nil
    }
    
    var timeRemaining: TimeInterval? {
        guard let timeLimit = timeLimit, let startedAt = startedAt else { return nil }
        let elapsed = Date().timeIntervalSince(startedAt)
        return max(0, timeLimit - elapsed)
    }
}

enum QuestCategory: String, Codable, CaseIterable {
    case daily = "daily"           // Ежедневные
    case weekly = "weekly"         // Еженедельные
    case story = "story"           // Сюжетные
    case seasonal = "seasonal"     // Сезонные
    case special = "special"       // Специальные
    
    var localizedName: String {
        switch self {
        case .daily: return "Ежедневные"
        case .weekly: return "Еженедельные"
        case .story: return "Сюжетные"
        case .seasonal: return "Сезонные"
        case .special: return "Специальные"
        }
    }
}

enum QuestDifficulty: String, Codable, CaseIterable {
    case easy = "easy"         // Легкий
    case medium = "medium"     // Средний
    case hard = "hard"         // Сложный
    case expert = "expert"     // Эксперт
    
    var localizedName: String {
        switch self {
        case .easy: return "Легкий"
        case .medium: return "Средний"
        case .hard: return "Сложный"
        case .expert: return "Эксперт"
        }
    }
    
    var experienceReward: Int {
        switch self {
        case .easy: return 10
        case .medium: return 25
        case .hard: return 50
        case .expert: return 100
        }
    }
}

struct QuestRequirements: Codable {
    let type: RequirementType
    let target: Int
    let specificPOIs: [String]?
    let specificRoutes: [String]?
    let timeOfDay: TimeOfDay?
    let weatherCondition: WeatherCondition?
    
    enum RequirementType: String, Codable {
        case visitPOIs = "visit_pois"
        case completeRoutes = "complete_routes"
        case takePhotos = "take_photos"
        case leaveReviews = "leave_reviews"
        case askQuestions = "ask_questions"
        case socialInteractions = "social_interactions"
        case useAR = "use_ar"
        case offlineMode = "offline_mode"
    }
    
    enum TimeOfDay: String, Codable {
        case morning = "morning"     // 6:00 - 12:00
        case afternoon = "afternoon" // 12:00 - 18:00
        case evening = "evening"     // 18:00 - 22:00
        case night = "night"         // 22:00 - 6:00
    }
    
    enum WeatherCondition: String, Codable {
        case sunny = "sunny"
        case rainy = "rainy"
        case snowy = "snowy"
        case cloudy = "cloudy"
    }
}

struct QuestProgress: Codable {
    let current: Int
    let target: Int
    let startedAt: Date
    let lastUpdated: Date
    
    var percentage: Double {
        return min(1.0, Double(current) / Double(target))
    }
    
    var isCompleted: Bool {
        return current >= target
    }
}

struct QuestReward: Codable {
    let type: RewardType
    let value: Int
    let description: String
    
    enum RewardType: String, Codable {
        case experience = "experience"
        case coins = "coins"
        case badge = "badge"
        case premiumDays = "premium_days"
        case specialAccess = "special_access"
        case discount = "discount"
    }
}

// MARK: - Achievement System
struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: AchievementCategory
    let points: Int
    let unlockedAt: Date?
    let progress: AchievementProgress?
    
    var isUnlocked: Bool {
        return unlockedAt != nil
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case exploration = "exploration"
    case social = "social"
    case completion = "completion"
    case speed = "speed"
    case special = "special"
    
    var localizedName: String {
        switch self {
        case .exploration: return "Исследование"
        case .social: return "Социальное"
        case .completion: return "Завершение"
        case .speed: return "Скорость"
        case .special: return "Специальные"
        }
    }
}

struct AchievementProgress: Codable {
    let current: Int
    let target: Int
    let lastUpdated: Date
    
    var percentage: Double {
        return min(1.0, Double(current) / Double(target))
    }
}

// MARK: - Social Features
struct SocialInteraction: Codable, Identifiable {
    let id: String
    let userId: String
    let targetUserId: String?
    let targetPOIId: String?
    let targetRouteId: String?
    let type: InteractionType
    let createdAt: Date
    let metadata: [String: String]?
    
    enum InteractionType: String, Codable {
        case like = "like"
        case follow = "follow"
        case share = "share"
        case comment = "comment"
        case rate = "rate"
        case recommend = "recommend"
    }
}

struct UserProfile: Codable, Identifiable {
    let id: String
    let username: String
    let displayName: String
    let avatar: String?
    let bio: String?
    let level: Int
    let experience: Int
    let coins: Int
    let badges: [String]
    let achievements: [String]
    let followers: [String]
    let following: [String]
    let totalPOIsVisited: Int
    let totalRoutesCompleted: Int
    let totalDistance: Double
    let totalTime: TimeInterval
    let joinDate: Date
    let lastActive: Date
    let isPremium: Bool
    let privacySettings: PrivacySettings
    
    var experienceToNextLevel: Int {
        let baseExp = 100
        let levelMultiplier = Double(level) * 1.5
        return Int(baseExp * levelMultiplier)
    }
    
    var levelProgress: Double {
        let currentLevelExp = Double(level - 1) * 100 * 1.5
        let currentExp = Double(experience) - currentLevelExp
        let nextLevelExp = Double(level) * 100 * 1.5 - currentLevelExp
        return min(1.0, currentExp / nextLevelExp)
    }
}

struct PrivacySettings: Codable {
    let profileVisibility: ProfileVisibility
    let showLocation: Bool
    let showActivity: Bool
    let allowMessages: Bool
    let allowFollowRequests: Bool
    
    enum ProfileVisibility: String, Codable {
        case public = "public"
        case friends = "friends"
        case private = "private"
    }
}

// MARK: - Leaderboard System
struct Leaderboard: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let type: LeaderboardType
    let timeFrame: TimeFrame
    let entries: [LeaderboardEntry]
    let lastUpdated: Date
    
    enum LeaderboardType: String, Codable {
        case experience = "experience"
        case badges = "badges"
        case achievements = "achievements"
        case routesCompleted = "routes_completed"
        case distance = "distance"
        case socialScore = "social_score"
    }
    
    enum TimeFrame: String, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case allTime = "all_time"
    }
}

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let avatar: String?
    let rank: Int
    let score: Int
    let metadata: [String: String]?
    
    var isCurrentUser: Bool {
        // Will be set by the service
        return false
    }
}

// MARK: - Game State
struct GameState: Codable {
    let userId: String
    let level: Int
    let experience: Int
    let coins: Int
    let badges: [String]
    let achievements: [String]
    let activeQuests: [String]
    let completedQuests: [String]
    let statistics: GameStatistics
    let lastUpdated: Date
    
    var experienceToNextLevel: Int {
        let baseExp = 100
        let levelMultiplier = Double(level) * 1.5
        return Int(baseExp * levelMultiplier)
    }
    
    var levelProgress: Double {
        let currentLevelExp = Double(level - 1) * 100 * 1.5
        let currentExp = Double(experience) - currentLevelExp
        let nextLevelExp = Double(level) * 100 * 1.5 - currentLevelExp
        return min(1.0, currentExp / nextLevelExp)
    }
}

struct GameStatistics: Codable {
    let totalPOIsVisited: Int
    let totalRoutesCompleted: Int
    let totalDistance: Double
    let totalTime: TimeInterval
    let totalReviews: Int
    let totalQuestions: Int
    let totalLikes: Int
    let totalFollowers: Int
    let consecutiveDays: Int
    let longestStreak: Int
    let badgesUnlocked: Int
    let achievementsUnlocked: Int
    let questsCompleted: Int
    let specialEventsAttended: Int
}