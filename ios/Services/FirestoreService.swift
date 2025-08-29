import Foundation

final class FirestoreService {
    static let shared = FirestoreService()

    // MARK: - POI
    func fetchPOIList() async throws -> [POI] {
        #if canImport(FirebaseFirestore)
        import FirebaseFirestore
        import FirebaseFirestoreSwift
        let db = Firestore.firestore()
        let snap = try await db.collection("poi").getDocuments()
        return try snap.documents.compactMap { try $0.data(as: POI.self) }
        #else
        return []
        #endif
    }

    func fetchPOI(id: String) async throws -> POI? {
        #if canImport(FirebaseFirestore)
        import FirebaseFirestore
        import FirebaseFirestoreSwift
        let db = Firestore.firestore()
        let doc = try await db.collection("poi").document(id).getDocument()
        return try doc.data(as: POI.self)
        #else
        return nil
        #endif
    }

    // MARK: - Routes
    func fetchRoutes() async throws -> [RoutePlan] {
        #if canImport(FirebaseFirestore)
        import FirebaseFirestore
        import FirebaseFirestoreSwift
        let db = Firestore.firestore()
        let snap = try await db.collection("routes").getDocuments()
        return try snap.documents.compactMap { try $0.data(as: RoutePlan.self) }
        #else
        return []
        #endif
    }

    func fetchRoute(id: String) async throws -> RoutePlan? {
        #if canImport(FirebaseFirestore)
        import FirebaseFirestore
        import FirebaseFirestoreSwift
        let db = Firestore.firestore()
        let doc = try await db.collection("routes").document(id).getDocument()
        return try doc.data(as: RoutePlan.self)
        #else
        return nil
        #endif
    }

    // MARK: - Reviews
    func addReview(_ review: Review) async throws {
        #if canImport(FirebaseFirestore)
        import FirebaseFirestore
        import FirebaseFirestoreSwift
        let db = Firestore.firestore()
        try db.collection("reviews").document(review.id).setData(from: review)
        #else
        #endif
    }

    func fetchReviews(poiId: String) async throws -> [Review] {
        #if canImport(FirebaseFirestore)
        import FirebaseFirestore
        import FirebaseFirestoreSwift
        let db = Firestore.firestore()
        let snap = try await db.collection("reviews").whereField("poiId", isEqualTo: poiId).getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Review.self) }
        #else
        return []
        #endif
    }

    // MARK: - Questions
    func askQuestion(_ q: Question) async throws {
        #if canImport(FirebaseFirestore)
        import FirebaseFirestore
        import FirebaseFirestoreSwift
        let db = Firestore.firestore()
        try db.collection("questions").document(q.id).setData(from: q)
        #else
        #endif
    }

    func fetchQuestions(poiId: String) async throws -> [Question] {
        #if canImport(FirebaseFirestore)
        import FirebaseFirestore
        import FirebaseFirestoreSwift
        let db = Firestore.firestore()
        let snap = try await db.collection("questions").whereField("poiId", isEqualTo: poiId).getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Question.self) }
        #else
        return []
        #endif
    }

    // MARK: - User
    func fetchUserProfile(uid: String) async throws -> UserProfile? {
        #if canImport(FirebaseFirestore)
        import FirebaseFirestore
        import FirebaseFirestoreSwift
        let db = Firestore.firestore()
        let doc = try await db.collection("users").document(uid).getDocument()
        return try doc.data(as: UserProfile.self)
        #else
        return nil
        #endif
    }

    func upsertUserProfile(_ p: UserProfile) async throws {
        #if canImport(FirebaseFirestore)
        import FirebaseFirestore
        import FirebaseFirestoreSwift
        let db = Firestore.firestore()
        try db.collection("users").document(p.id).setData(from: p, merge: true)
        #else
        #endif
    }
}