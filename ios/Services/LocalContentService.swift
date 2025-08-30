import Foundation

class LocalContentService {
    static let shared = LocalContentService()
    
    private init() {}
    
    func loadPOIs() -> [POI] {
        guard let url = Bundle.main.url(forResource: "poi", withExtension: "json", subdirectory: "content"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        
        struct Wrapper: Decodable { let items: [POI] }
        return (try? JSONDecoder().decode(Wrapper.self, from: data))?.items ?? []
    }
    
    func loadRoutes() -> [Route] {
        guard let url = Bundle.main.url(forResource: "routes", withExtension: "json", subdirectory: "content"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        
        struct Wrapper: Decodable { let items: [Route] }
        return (try? JSONDecoder().decode(Wrapper.self, from: data))?.items ?? []
    }
    
    // MARK: - Gamification
    func getBadges() -> [Badge] {
        return [
            Badge(
                id: "badge_explorer",
                title: "Исследователь",
                description: "Посетите 10 достопримечательностей",
                iconName: "map",
                category: .exploration,
                rarity: .common,
                requirements: BadgeRequirements(
                    type: .visitPOIs,
                    target: 10,
                    timeLimit: nil,
                    specificPOIs: nil,
                    specificRoutes: nil
                ),
                reward: BadgeReward(type: .experience, value: 50, description: "50 опыта"),
                unlockedAt: nil,
                progress: 0.3
            ),
            Badge(
                id: "badge_social",
                title: "Общительный",
                description: "Оставьте 5 отзывов",
                iconName: "message",
                category: .social,
                rarity: .rare,
                requirements: BadgeRequirements(
                    type: .reviews,
                    target: 5,
                    timeLimit: nil,
                    specificPOIs: nil,
                    specificRoutes: nil
                ),
                reward: BadgeReward(type: .coins, value: 100, description: "100 монет"),
                unlockedAt: nil,
                progress: 0.0
            ),
            Badge(
                id: "badge_completionist",
                title: "Завершитель",
                description: "Пройдите 5 маршрутов",
                iconName: "flag",
                category: .completion,
                rarity: .epic,
                requirements: BadgeRequirements(
                    type: .completeRoutes,
                    target: 5,
                    timeLimit: nil,
                    specificPOIs: nil,
                    specificRoutes: nil
                ),
                reward: BadgeReward(type: .premiumDays, value: 7, description: "7 дней премиума"),
                unlockedAt: nil,
                progress: 0.0
            )
        ]
    }
    
    func getQuests() -> [Quest] {
        return [
            Quest(
                id: "quest_daily_explorer",
                title: "Ежедневный исследователь",
                description: "Посетите 3 достопримечательности сегодня",
                category: .daily,
                difficulty: .easy,
                requirements: QuestRequirements(
                    type: .visitPOIs,
                    target: 3,
                    specificPOIs: nil,
                    specificRoutes: nil,
                    timeOfDay: nil,
                    weatherCondition: nil
                ),
                rewards: [
                    QuestReward(type: .experience, value: 25, description: "25 опыта"),
                    QuestReward(type: .coins, value: 50, description: "50 монет")
                ],
                timeLimit: 24 * 60 * 60, // 24 hours
                isRepeatable: true,
                isActive: true,
                startedAt: nil,
                completedAt: nil,
                progress: QuestProgress(current: 0, target: 3, startedAt: Date(), lastUpdated: Date())
            ),
            Quest(
                id: "quest_photo_enthusiast",
                title: "Фотограф-любитель",
                description: "Сделайте фото в 5 разных местах",
                category: .weekly,
                difficulty: .medium,
                requirements: QuestRequirements(
                    type: .takePhotos,
                    target: 5,
                    specificPOIs: nil,
                    specificRoutes: nil,
                    timeOfDay: nil,
                    weatherCondition: nil
                ),
                rewards: [
                    QuestReward(type: .experience, value: 50, description: "50 опыта"),
                    QuestReward(type: .badge, value: 1, description: "Значок фотографа")
                ],
                timeLimit: 7 * 24 * 60 * 60, // 7 days
                isRepeatable: true,
                isActive: true,
                startedAt: nil,
                completedAt: nil,
                progress: QuestProgress(current: 0, target: 5, startedAt: Date(), lastUpdated: Date())
            )
        ]
    }
    
    func getAchievements() -> [Achievement] {
        return [
            Achievement(
                id: "achievement_first_visit",
                title: "Первый шаг",
                description: "Посетите первую достопримечательность",
                category: .exploration,
                points: 10,
                unlockedAt: nil,
                progress: AchievementProgress(current: 0, target: 1, lastUpdated: Date())
            ),
            Achievement(
                id: "achievement_social_butterfly",
                title: "Социальная бабочка",
                description: "Получите 10 подписчиков",
                category: .social,
                points: 25,
                unlockedAt: nil,
                progress: AchievementProgress(current: 0, target: 10, lastUpdated: Date())
            ),
            Achievement(
                id: "achievement_marathon_runner",
                title: "Марафонец",
                description: "Пройдите 50 км пешком",
                category: .completion,
                points: 100,
                unlockedAt: nil,
                progress: AchievementProgress(current: 0, target: 50, lastUpdated: Date())
            )
        ]
    }
    
    func getLeaderboards() -> [Leaderboard] {
        return [
            Leaderboard(
                id: "leaderboard_experience",
                title: "Рейтинг по опыту",
                description: "Топ игроков по набранному опыту",
                type: .experience,
                timeFrame: .allTime,
                entries: [
                    LeaderboardEntry(id: "1", userId: "user1", username: "Турист1", avatar: nil, rank: 1, score: 1500, metadata: nil),
                    LeaderboardEntry(id: "2", userId: "user2", username: "Турист2", avatar: nil, rank: 2, score: 1200, metadata: nil),
                    LeaderboardEntry(id: "3", userId: "user3", username: "Турист3", avatar: nil, rank: 3, score: 900, metadata: nil)
                ],
                lastUpdated: Date()
            ),
            Leaderboard(
                id: "leaderboard_badges",
                title: "Рейтинг по значкам",
                description: "Топ игроков по количеству значков",
                type: .badges,
                timeFrame: .allTime,
                entries: [
                    LeaderboardEntry(id: "1", userId: "user1", username: "Турист1", avatar: nil, rank: 1, score: 15, metadata: nil),
                    LeaderboardEntry(id: "2", userId: "user2", username: "Турист2", avatar: nil, rank: 2, score: 12, metadata: nil),
                    LeaderboardEntry(id: "3", userId: "user3", username: "Турист3", avatar: nil, rank: 3, score: 8, metadata: nil)
                ],
                lastUpdated: Date()
            )
        ]
    }
}