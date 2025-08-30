import Foundation
import Combine
import FirebaseFirestore

@MainActor
class GamificationService: ObservableObject {
    static let shared = GamificationService()
    
    // MARK: - Published Properties
    @Published var badges: [Badge] = []
    @Published var quests: [Quest] = []
    @Published var achievements: [Achievement] = []
    @Published var gameState: GameState?
    @Published var leaderboards: [Leaderboard] = []
    @Published var socialInteractions: [SocialInteraction] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private let firestoreService = FirestoreService.shared
    private let authService = AuthService.shared
    private let userService = UserService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthListener()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupAuthListener() {
        authService.$currentUser
            .sink { [weak self] user in
                if user != nil {
                    self?.loadUserGameData()
                } else {
                    self?.clearUserData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        loadBadges()
        loadQuests()
        loadAchievements()
        loadLeaderboards()
    }
    
    // MARK: - Badge Management
    func loadBadges() {
        Task {
            do {
                let fetchedBadges = try await firestoreService.fetchBadges()
                await MainActor.run {
                    self.badges = fetchedBadges
                }
            } catch {
                await MainActor.run {
                    self.error = "Ошибка загрузки значков: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func unlockBadge(_ badgeId: String) async {
        guard let user = authService.currentUser else { return }
        
        do {
            // Update badge in Firestore
            try await firestoreService.updateBadgeProgress(userId: user.uid, badgeId: badgeId, progress: 1.0, unlockedAt: Date())
            
            // Update local state
            if let index = badges.firstIndex(where: { $0.id == badgeId }) {
                var updatedBadge = badges[index]
                updatedBadge = Badge(
                    id: updatedBadge.id,
                    title: updatedBadge.title,
                    description: updatedBadge.description,
                    iconName: updatedBadge.iconName,
                    category: updatedBadge.category,
                    rarity: updatedBadge.rarity,
                    requirements: updatedBadge.requirements,
                    reward: updatedBadge.reward,
                    unlockedAt: Date(),
                    progress: 1.0
                )
                badges[index] = updatedBadge
            }
            
            // Add to user profile
            await userService.addBadge(badgeId)
            
            // Check for rewards
            if let badge = badges.first(where: { $0.id == badgeId }),
               let reward = badge.reward {
                await processReward(reward)
            }
            
        } catch {
            self.error = "Ошибка разблокировки значка: \(error.localizedDescription)"
        }
    }
    
    func updateBadgeProgress(_ badgeId: String, progress: Double) async {
        guard let user = authService.currentUser else { return }
        
        do {
            try await firestoreService.updateBadgeProgress(userId: user.uid, badgeId: badgeId, progress: progress, unlockedAt: nil)
            
            // Update local state
            if let index = badges.firstIndex(where: { $0.id == badgeId }) {
                var updatedBadge = badges[index]
                let unlockedAt = progress >= 1.0 ? Date() : nil
                updatedBadge = Badge(
                    id: updatedBadge.id,
                    title: updatedBadge.title,
                    description: updatedBadge.description,
                    iconName: updatedBadge.iconName,
                    category: updatedBadge.category,
                    rarity: updatedBadge.rarity,
                    requirements: updatedBadge.requirements,
                    reward: updatedBadge.reward,
                    unlockedAt: unlockedAt,
                    progress: progress
                )
                badges[index] = updatedBadge
                
                // If badge is now unlocked, process rewards
                if progress >= 1.0, let reward = updatedBadge.reward {
                    await processReward(reward)
                }
            }
        } catch {
            self.error = "Ошибка обновления прогресса значка: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Quest Management
    func loadQuests() {
        Task {
            do {
                let fetchedQuests = try await firestoreService.fetchQuests()
                await MainActor.run {
                    self.quests = fetchedQuests
                }
            } catch {
                await MainActor.run {
                    self.error = "Ошибка загрузки квестов: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func startQuest(_ questId: String) async {
        guard let user = authService.currentUser else { return }
        
        do {
            let startDate = Date()
            try await firestoreService.startQuest(userId: user.uid, questId: questId, startedAt: startDate)
            
            // Update local state
            if let index = quests.firstIndex(where: { $0.id == questId }) {
                var updatedQuest = quests[index]
                let progress = QuestProgress(current: 0, target: updatedQuest.requirements.target, startedAt: startDate, lastUpdated: startDate)
                updatedQuest = Quest(
                    id: updatedQuest.id,
                    title: updatedQuest.title,
                    description: updatedQuest.description,
                    category: updatedQuest.category,
                    difficulty: updatedQuest.difficulty,
                    requirements: updatedQuest.requirements,
                    rewards: updatedQuest.rewards,
                    timeLimit: updatedQuest.timeLimit,
                    isRepeatable: updatedQuest.isRepeatable,
                    isActive: updatedQuest.isActive,
                    startedAt: startDate,
                    completedAt: nil,
                    progress: progress
                )
                quests[index] = updatedQuest
            }
        } catch {
            self.error = "Ошибка запуска квеста: \(error.localizedDescription)"
        }
    }
    
    func updateQuestProgress(_ questId: String, progress: Int) async {
        guard let user = authService.currentUser else { return }
        
        do {
            try await firestoreService.updateQuestProgress(userId: user.uid, questId: questId, progress: progress)
            
            // Update local state
            if let index = quests.firstIndex(where: { $0.id == questId }) {
                var updatedQuest = quests[index]
                let lastUpdated = Date()
                let newProgress = QuestProgress(
                    current: progress,
                    target: updatedQuest.requirements.target,
                    startedAt: updatedQuest.progress.startedAt,
                    lastUpdated: lastUpdated
                )
                
                let completedAt = progress >= updatedQuest.requirements.target ? Date() : nil
                
                updatedQuest = Quest(
                    id: updatedQuest.id,
                    title: updatedQuest.title,
                    description: updatedQuest.description,
                    category: updatedQuest.category,
                    difficulty: updatedQuest.difficulty,
                    requirements: updatedQuest.requirements,
                    rewards: updatedQuest.rewards,
                    timeLimit: updatedQuest.timeLimit,
                    isRepeatable: updatedQuest.isRepeatable,
                    isActive: updatedQuest.isActive,
                    startedAt: updatedQuest.startedAt,
                    completedAt: completedAt,
                    progress: newProgress
                )
                quests[index] = updatedQuest
                
                // If quest is completed, process rewards
                if completedAt != nil {
                    await completeQuest(updatedQuest)
                }
            }
        } catch {
            self.error = "Ошибка обновления прогресса квеста: \(error.localizedDescription)"
        }
    }
    
    private func completeQuest(_ quest: Quest) async {
        // Process all rewards
        for reward in quest.rewards {
            await processReward(QuestReward(type: reward.type, value: reward.value, description: reward.description))
        }
        
        // Add experience based on difficulty
        await addExperience(quest.difficulty.experienceReward)
        
        // Update game state
        await updateGameState()
    }
    
    // MARK: - Achievement Management
    func loadAchievements() {
        Task {
            do {
                let fetchedAchievements = try await firestoreService.fetchAchievements()
                await MainActor.run {
                    self.achievements = fetchedAchievements
                }
            } catch {
                await MainActor.run {
                    self.error = "Ошибка загрузки достижений: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func unlockAchievement(_ achievementId: String) async {
        guard let user = authService.currentUser else { return }
        
        do {
            try await firestoreService.unlockAchievement(userId: user.uid, achievementId: achievementId, unlockedAt: Date())
            
            // Update local state
            if let index = achievements.firstIndex(where: { $0.id == achievementId }) {
                var updatedAchievement = achievements[index]
                updatedAchievement = Achievement(
                    id: updatedAchievement.id,
                    title: updatedAchievement.title,
                    description: updatedAchievement.description,
                    category: updatedAchievement.category,
                    points: updatedAchievement.points,
                    unlockedAt: Date(),
                    progress: nil
                )
                achievements[index] = updatedAchievement
            }
            
            // Add points to game state
            if let achievement = achievements.first(where: { $0.id == achievementId }) {
                await addPoints(achievement.points)
            }
            
        } catch {
            self.error = "Ошибка разблокировки достижения: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Social Features
    func likePOI(_ poiId: String) async {
        await createSocialInteraction(
            targetPOIId: poiId,
            type: .like
        )
    }
    
    func followUser(_ userId: String) async {
        await createSocialInteraction(
            targetUserId: userId,
            type: .follow
        )
    }
    
    func shareRoute(_ routeId: String) async {
        await createSocialInteraction(
            targetRouteId: routeId,
            type: .share
        )
    }
    
    private func createSocialInteraction(targetUserId: String? = nil, targetPOIId: String? = nil, targetRouteId: String? = nil, type: SocialInteraction.InteractionType) async {
        guard let user = authService.currentUser else { return }
        
        let interaction = SocialInteraction(
            id: UUID().uuidString,
            userId: user.uid,
            targetUserId: targetUserId,
            targetPOIId: targetPOIId,
            targetRouteId: targetRouteId,
            type: type,
            createdAt: Date(),
            metadata: nil
        )
        
        do {
            try await firestoreService.addSocialInteraction(interaction)
            socialInteractions.append(interaction)
            
            // Update game statistics
            await updateGameStatistics()
            
        } catch {
            self.error = "Ошибка создания социального взаимодействия: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Leaderboard Management
    func loadLeaderboards() {
        Task {
            do {
                let fetchedLeaderboards = try await firestoreService.fetchLeaderboards()
                await MainActor.run {
                    self.leaderboards = fetchedLeaderboards
                }
            } catch {
                await MainActor.run {
                    self.error = "Ошибка загрузки рейтингов: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func refreshLeaderboard(_ leaderboardId: String) async {
        do {
            let updatedLeaderboard = try await firestoreService.fetchLeaderboard(leaderboardId)
            if let index = leaderboards.firstIndex(where: { $0.id == leaderboardId }) {
                leaderboards[index] = updatedLeaderboard
            }
        } catch {
            self.error = "Ошибка обновления рейтинга: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Game State Management
    func loadUserGameData() {
        Task {
            await loadGameState()
            await loadUserSocialInteractions()
        }
    }
    
    private func loadGameState() async {
        guard let user = authService.currentUser else { return }
        
        do {
            let fetchedGameState = try await firestoreService.fetchGameState(userId: user.uid)
            await MainActor.run {
                self.gameState = fetchedGameState
            }
        } catch {
            // Create new game state if doesn't exist
            await createNewGameState()
        }
    }
    
    private func createNewGameState() async {
        guard let user = authService.currentUser else { return }
        
        let newGameState = GameState(
            userId: user.uid,
            level: 1,
            experience: 0,
            coins: 0,
            badges: [],
            achievements: [],
            activeQuests: [],
            completedQuests: [],
            statistics: GameStatistics(
                totalPOIsVisited: 0,
                totalRoutesCompleted: 0,
                totalDistance: 0,
                totalTime: 0,
                totalReviews: 0,
                totalQuestions: 0,
                totalLikes: 0,
                totalFollowers: 0,
                consecutiveDays: 0,
                longestStreak: 0,
                badgesUnlocked: 0,
                achievementsUnlocked: 0,
                questsCompleted: 0,
                specialEventsAttended: 0
            ),
            lastUpdated: Date()
        )
        
        do {
            try await firestoreService.saveGameState(newGameState)
            await MainActor.run {
                self.gameState = newGameState
            }
        } catch {
            self.error = "Ошибка создания игрового состояния: \(error.localizedDescription)"
        }
    }
    
    private func loadUserSocialInteractions() async {
        guard let user = authService.currentUser else { return }
        
        do {
            let interactions = try await firestoreService.fetchUserSocialInteractions(userId: user.uid)
            await MainActor.run {
                self.socialInteractions = interactions
            }
        } catch {
            await MainActor.run {
                self.error = "Ошибка загрузки социальных взаимодействий: \(error.localizedDescription)"
            }
        }
    }
    
    private func updateGameState() async {
        guard var currentState = gameState else { return }
        
        currentState = GameState(
            userId: currentState.userId,
            level: currentState.level,
            experience: currentState.experience,
            coins: currentState.coins,
            badges: currentState.badges,
            achievements: currentState.achievements,
            activeQuests: currentState.activeQuests,
            completedQuests: currentState.completedQuests,
            statistics: currentState.statistics,
            lastUpdated: Date()
        )
        
        do {
            try await firestoreService.saveGameState(currentState)
            await MainActor.run {
                self.gameState = currentState
            }
        } catch {
            self.error = "Ошибка обновления игрового состояния: \(error.localizedDescription)"
        }
    }
    
    private func updateGameStatistics() async {
        guard var currentState = gameState else { return }
        
        // Update statistics based on current data
        let newStatistics = GameStatistics(
            totalPOIsVisited: currentState.statistics.totalPOIsVisited,
            totalRoutesCompleted: currentState.statistics.totalRoutesCompleted,
            totalDistance: currentState.statistics.totalDistance,
            totalTime: currentState.statistics.totalTime,
            totalReviews: currentState.statistics.totalReviews,
            totalQuestions: currentState.statistics.totalQuestions,
            totalLikes: socialInteractions.filter { $0.type == .like }.count,
            totalFollowers: currentState.statistics.totalFollowers,
            consecutiveDays: currentState.statistics.consecutiveDays,
            longestStreak: currentState.statistics.longestStreak,
            badgesUnlocked: badges.filter { $0.isUnlocked }.count,
            achievementsUnlocked: achievements.filter { $0.isUnlocked }.count,
            questsCompleted: quests.filter { $0.isCompleted }.count,
            specialEventsAttended: currentState.statistics.specialEventsAttended
        )
        
        currentState = GameState(
            userId: currentState.userId,
            level: currentState.level,
            experience: currentState.experience,
            coins: currentState.coins,
            badges: currentState.badges,
            achievements: currentState.achievements,
            activeQuests: currentState.activeQuests,
            completedQuests: currentState.completedQuests,
            statistics: newStatistics,
            lastUpdated: Date()
        )
        
        do {
            try await firestoreService.saveGameState(currentState)
            await MainActor.run {
                self.gameState = currentState
            }
        } catch {
            self.error = "Ошибка обновления статистики: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reward Processing
    private func processReward(_ reward: BadgeReward) async {
        switch reward.type {
        case .experience:
            await addExperience(reward.value)
        case .coins:
            await addCoins(reward.value)
        case .premiumDays:
            await addPremiumDays(reward.value)
        case .specialAccess:
            // Handle special access
            break
        case .discount:
            // Handle discount
            break
        }
    }
    
    private func processReward(_ reward: QuestReward) async {
        switch reward.type {
        case .experience:
            await addExperience(reward.value)
        case .coins:
            await addCoins(reward.value)
        case .badge:
            // Handle badge reward
            break
        case .premiumDays:
            await addPremiumDays(reward.value)
        case .specialAccess:
            // Handle special access
            break
        case .discount:
            // Handle discount
            break
        }
    }
    
    private func addExperience(_ amount: Int) async {
        guard var currentState = gameState else { return }
        
        let newExperience = currentState.experience + amount
        let newLevel = calculateLevel(experience: newExperience)
        
        currentState = GameState(
            userId: currentState.userId,
            level: newLevel,
            experience: newExperience,
            coins: currentState.coins,
            badges: currentState.badges,
            achievements: currentState.achievements,
            activeQuests: currentState.activeQuests,
            completedQuests: currentState.completedQuests,
            statistics: currentState.statistics,
            lastUpdated: Date()
        )
        
        do {
            try await firestoreService.saveGameState(currentState)
            await MainActor.run {
                self.gameState = currentState
            }
        } catch {
            self.error = "Ошибка добавления опыта: \(error.localizedDescription)"
        }
    }
    
    private func addCoins(_ amount: Int) async {
        guard var currentState = gameState else { return }
        
        currentState = GameState(
            userId: currentState.userId,
            level: currentState.level,
            experience: currentState.experience,
            coins: currentState.coins + amount,
            badges: currentState.badges,
            achievements: currentState.achievements,
            activeQuests: currentState.activeQuests,
            completedQuests: currentState.completedQuests,
            statistics: currentState.statistics,
            lastUpdated: Date()
        )
        
        do {
            try await firestoreService.saveGameState(currentState)
            await MainActor.run {
                self.gameState = currentState
            }
        } catch {
            self.error = "Ошибка добавления монет: \(error.localizedDescription)"
        }
    }
    
    private func addPoints(_ amount: Int) async {
        // Points are similar to experience
        await addExperience(amount)
    }
    
    private func addPremiumDays(_ days: Int) async {
        // Update user premium status
        let premiumUntil = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        await userService.setPremiumUntil(premiumUntil)
    }
    
    // MARK: - Helper Functions
    private func calculateLevel(experience: Int) -> Int {
        var level = 1
        var expNeeded = 100
        
        while experience >= expNeeded {
            level += 1
            expNeeded = Int(Double(level) * 100 * 1.5)
        }
        
        return level
    }
    
    private func clearUserData() {
        gameState = nil
        socialInteractions = []
    }
    
    // MARK: - Public Helper Methods
    func getUserBadges() -> [Badge] {
        return badges.filter { badge in
            gameState?.badges.contains(badge.id) == true
        }
    }
    
    func getUserAchievements() -> [Achievement] {
        return achievements.filter { achievement in
            gameState?.achievements.contains(achievement.id) == true
        }
    }
    
    func getActiveQuests() -> [Quest] {
        return quests.filter { quest in
            quest.isStarted && !quest.isCompleted
        }
    }
    
    func getAvailableQuests() -> [Quest] {
        return quests.filter { quest in
            !quest.isStarted && quest.isActive
        }
    }
    
    func getCompletedQuests() -> [Quest] {
        return quests.filter { quest in
            quest.isCompleted
        }
    }
}