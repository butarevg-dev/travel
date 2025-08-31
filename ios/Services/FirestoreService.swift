import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - POI
    func fetchPOIList() async throws -> [POI] {
        do {
            let snap = try await db.collection("poi").getDocuments()
            let pois = try snap.documents.compactMap { doc -> POI? in
                // Try new POI format first
                if let newPOI = try? doc.data(as: POI.self) {
                    return newPOI
                }
                // Fallback to legacy format
                if let legacyPOI = try? doc.data(as: LegacyPOI.self) {
                    return POIAdapter.toNewPOI(legacyPOI)
                }
                return nil
            }
            return pois
        } catch {
            // Fallback to local content if Firebase fails
            return LocalContentService.shared.loadPOIs()
        }
    }
    
    func fetchPOI(id: String) async throws -> POI? {
        do {
            let doc = try await db.collection("poi").document(id).getDocument()
            // Try new POI format first
            if let newPOI = try? doc.data(as: POI.self) {
                return newPOI
            }
            // Fallback to legacy format
            if let legacyPOI = try? doc.data(as: LegacyPOI.self) {
                return POIAdapter.toNewPOI(legacyPOI)
            }
            return nil
        } catch {
            return LocalContentService.shared.loadPOIs().first { $0.id == id }
        }
    }
    
    // MARK: - Routes
    func fetchRouteList() async throws -> [Route] {
        do {
            let snap = try await db.collection("routes").getDocuments()
            return try snap.documents.compactMap { try $0.data(as: Route.self) }
        } catch {
            return LocalContentService.shared.loadRoutes()
        }
    }
    
    func fetchRoute(id: String) async throws -> Route? {
        do {
            let doc = try await db.collection("routes").document(id).getDocument()
            return try doc.data(as: Route.self)
        } catch {
            return LocalContentService.shared.loadRoutes().first { $0.id == id }
        }
    }
    
    // MARK: - Reviews
    func fetchReviews(for poiId: String) async throws -> [Review] {
        let snap = try await db.collection("reviews")
            .whereField("poiId", isEqualTo: poiId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Review.self) }
    }
    
    func addReview(_ review: Review) async throws {
        try await db.collection("reviews").addDocument(from: review)
    }
    
    func updateReview(_ review: Review) async throws {
        try await db.collection("reviews").document(review.id).setData(from: review)
    }
    
    func deleteReview(_ reviewId: String) async throws {
        try await db.collection("reviews").document(reviewId).delete()
    }
    
    // MARK: - Questions
    func fetchQuestions(for poiId: String) async throws -> [Question] {
        let snap = try await db.collection("questions")
            .whereField("poiId", isEqualTo: poiId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Question.self) }
    }
    
    func addQuestion(_ question: Question) async throws {
        try await db.collection("questions").addDocument(from: question)
    }
    
    func updateQuestion(_ question: Question) async throws {
        try await db.collection("questions").document(question.id).setData(from: question)
    }
    
    func deleteQuestion(_ questionId: String) async throws {
        try await db.collection("questions").document(questionId).delete()
    }
    
    // MARK: - User Profile
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let doc = try await db.collection("users").document(userId).getDocument()
        return try doc.data(as: UserProfile.self)
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await db.collection("users").document(profile.id).setData(from: profile)
    }
    
    // MARK: - Badges and Quests
    func fetchUserBadges(userId: String) async throws -> [Badge] {
        let snap = try await db.collection("badges")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Badge.self) }
    }
    
    func fetchUserQuests(userId: String) async throws -> [Quest] {
        let snap = try await db.collection("quests")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Quest.self) }
    }
    
    // MARK: - Gamification
    func fetchBadges() async throws -> [Badge] {
        do {
            let snapshot = try await db.collection("badges").getDocuments()
            return try snapshot.documents.compactMap { document in
                try document.data(as: Badge.self)
            }
        } catch {
            // Fallback to local content
            return LocalContentService.shared.getBadges()
        }
    }
    
    func updateBadgeProgress(userId: String, badgeId: String, progress: Double, unlockedAt: Date?) async throws {
        let data: [String: Any] = [
            "progress": progress,
            "unlockedAt": unlockedAt,
            "lastUpdated": Date()
        ]
        try await db.collection("users").document(userId)
            .collection("badges").document(badgeId).setData(data, merge: true)
    }
    
    func fetchQuests() async throws -> [Quest] {
        do {
            let snapshot = try await db.collection("quests").getDocuments()
            return try snapshot.documents.compactMap { document in
                try document.data(as: Quest.self)
            }
        } catch {
            // Fallback to local content
            return LocalContentService.shared.getQuests()
        }
    }
    
    func startQuest(userId: String, questId: String, startedAt: Date) async throws {
        let data: [String: Any] = [
            "startedAt": startedAt,
            "progress": [
                "current": 0,
                "target": 1, // Will be updated with actual target
                "startedAt": startedAt,
                "lastUpdated": startedAt
            ],
            "lastUpdated": Date()
        ]
        try await db.collection("users").document(userId)
            .collection("quests").document(questId).setData(data, merge: true)
    }
    
    func updateQuestProgress(userId: String, questId: String, progress: Int) async throws {
        let data: [String: Any] = [
            "progress.current": progress,
            "progress.lastUpdated": Date(),
            "lastUpdated": Date()
        ]
        try await db.collection("users").document(userId)
            .collection("quests").document(questId).updateData(data)
    }
    
    func fetchAchievements() async throws -> [Achievement] {
        do {
            let snapshot = try await db.collection("achievements").getDocuments()
            return try snapshot.documents.compactMap { document in
                try document.data(as: Achievement.self)
            }
        } catch {
            // Fallback to local content
            return LocalContentService.shared.getAchievements()
        }
    }
    
    func unlockAchievement(userId: String, achievementId: String, unlockedAt: Date) async throws {
        let data: [String: Any] = [
            "unlockedAt": unlockedAt,
            "lastUpdated": Date()
        ]
        try await db.collection("users").document(userId)
            .collection("achievements").document(achievementId).setData(data, merge: true)
    }
    
    func addSocialInteraction(_ interaction: SocialInteraction) async throws {
        try await db.collection("social_interactions").document(interaction.id).setData(from: interaction)
    }
    
    func fetchUserSocialInteractions(userId: String) async throws -> [SocialInteraction] {
        let snapshot = try await db.collection("social_interactions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: SocialInteraction.self)
        }
    }
    
    func fetchLeaderboards() async throws -> [Leaderboard] {
        do {
            let snapshot = try await db.collection("leaderboards").getDocuments()
            return try snapshot.documents.compactMap { document in
                try document.data(as: Leaderboard.self)
            }
        } catch {
            // Fallback to local content
            return LocalContentService.shared.getLeaderboards()
        }
    }
    
    func fetchLeaderboard(_ leaderboardId: String) async throws -> Leaderboard {
        let document = try await db.collection("leaderboards").document(leaderboardId).getDocument()
        return try document.data(as: Leaderboard.self)
    }
    
    func saveGameState(_ gameState: GameState) async throws {
        try await db.collection("game_states").document(gameState.userId).setData(from: gameState)
    }
    
    func fetchGameState(userId: String) async throws -> GameState {
        let document = try await db.collection("game_states").document(userId).getDocument()
        return try document.data(as: GameState.self)
    }
    
    // MARK: - Monetization - Partner Offers
    func fetchPartnerOffers() async throws -> [PartnerOffer] {
        do {
            let snapshot = try await db.collection("partner_offers")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            return try snapshot.documents.compactMap { document in
                try document.data(as: PartnerOffer.self)
            }
        } catch {
            // Fallback to mock data for development
            return []
        }
    }
    
    func saveUserOffer(_ userOffer: UserOffer) async throws {
        try await db.collection("user_offers").document(userOffer.id).setData(from: userOffer)
    }
    
    func updateUserOffer(_ userOffer: UserOffer) async throws {
        try await db.collection("user_offers").document(userOffer.id).setData(from: userOffer)
    }
    
    func fetchUserOffers(userId: String) async throws -> [UserOffer] {
        let snapshot = try await db.collection("user_offers")
            .whereField("userId", isEqualTo: userId)
            .order(by: "activatedAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: UserOffer.self)
        }
    }
    
    func updatePartnerOfferUsage(_ offerId: String) async throws {
        let offerRef = db.collection("partner_offers").document(offerId)
        try await offerRef.updateData([
            "currentUses": FieldValue.increment(1)
        ])
    }
    
    // MARK: - Monetization - Events
    func fetchEvents() async throws -> [Event] {
        do {
            let snapshot = try await db.collection("events")
                .whereField("isActive", isEqualTo: true)
                .order(by: "startDate", descending: false)
                .getDocuments()
            return try snapshot.documents.compactMap { document in
                try document.data(as: Event.self)
            }
        } catch {
            // Fallback to mock data for development
            return []
        }
    }
    
    func saveUserEvent(_ userEvent: UserEvent) async throws {
        try await db.collection("user_events").document(userEvent.id).setData(from: userEvent)
    }
    
    func updateUserEvent(_ userEvent: UserEvent) async throws {
        try await db.collection("user_events").document(userEvent.id).setData(from: userEvent)
    }
    
    func fetchUserEvents(userId: String) async throws -> [UserEvent] {
        let snapshot = try await db.collection("user_events")
            .whereField("userId", isEqualTo: userId)
            .order(by: "registeredAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: UserEvent.self)
        }
    }
    
    func registerUserForEvent(_ eventId: String) async throws {
        let eventRef = db.collection("events").document(eventId)
        try await eventRef.updateData([
            "currentParticipants": FieldValue.increment(1)
        ])
    }
    
    func updateEventParticipants(_ eventId: String) async throws {
        let eventRef = db.collection("events").document(eventId)
        try await eventRef.updateData([
            "currentParticipants": FieldValue.increment(1)
        ])
    }
    
    func decreaseEventParticipants(_ eventId: String) async throws {
        let eventRef = db.collection("events").document(eventId)
        try await eventRef.updateData([
            "currentParticipants": FieldValue.increment(-1)
        ])
    }
    
    // MARK: - Analytics
    func saveAnalyticsEvent(_ event: AnalyticsEvent) async throws {
        try await db.collection("analytics_events").addDocument(from: event)
    }
    
    func savePerformanceMetrics(_ metrics: PerformanceMetrics) async throws {
        try await db.collection("performance_metrics").addDocument(from: metrics)
    }
    
    func saveAppStoreMetrics(_ metrics: AppStoreMetrics) async throws {
        try await db.collection("app_store_metrics").addDocument(from: metrics)
    }
}