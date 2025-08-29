import Foundation

final class FirestoreService {
    static let shared = FirestoreService()

    // MARK: - POI
    func fetchPOIList() async throws -> [POI] { return [] }
    func fetchPOI(id: String) async throws -> POI? { return nil }

    // MARK: - Routes
    func fetchRoutes() async throws -> [RoutePlan] { return [] }
    func fetchRoute(id: String) async throws -> RoutePlan? { return nil }

    // MARK: - Reviews
    func addReview(_ review: Review) async throws {}
    func fetchReviews(poiId: String) async throws -> [Review] { return [] }

    // MARK: - Questions
    func askQuestion(_ q: Question) async throws {}
    func fetchQuestions(poiId: String) async throws -> [Question] { return [] }

    // MARK: - User
    func fetchUserProfile(uid: String) async throws -> UserProfile? { return nil }
    func upsertUserProfile(_ p: UserProfile) async throws {}
}