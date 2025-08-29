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
            return try snap.documents.compactMap { try $0.data(as: POI.self) }
        } catch {
            // Fallback to local content if Firebase fails
            return LocalContentService.shared.loadPOIs()
        }
    }
    
    func fetchPOI(id: String) async throws -> POI? {
        do {
            let doc = try await db.collection("poi").document(id).getDocument()
            return try doc.data(as: POI.self)
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
}