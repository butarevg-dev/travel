import Foundation
import Combine
import FirebaseFirestore

@MainActor
class ReviewService: ObservableObject {
    static let shared = ReviewService()
    
    @Published var reviews: [String: [Review]] = [:]
    @Published var questions: [String: [Question]] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    private let firestoreService = FirestoreService.shared
    private let authService = AuthService.shared
    
    private init() {}
    
    // MARK: - Reviews Management
    
    func loadReviews(for poiId: String) async {
        isLoading = true
        error = nil
        
        do {
            let reviews = try await firestoreService.fetchReviews(for: poiId)
            self.reviews[poiId] = reviews
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addReview(poiId: String, rating: Int, text: String?) async {
        guard let user = authService.currentUser else {
            error = "Пользователь не авторизован"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Check spam quota before posting
            let quotaResult = try await CloudFunctionsService.shared.checkSpamQuota(
                contentType: .review, 
                poiId: poiId
            )
            
            let review = Review(
                id: UUID().uuidString,
                poiId: poiId,
                userId: user.uid,
                rating: rating,
                text: text,
                createdAt: Date(),
                reported: false
            )
            
            try await firestoreService.addReview(review)
            
            // Update local cache
            if reviews[poiId] == nil {
                reviews[poiId] = []
            }
            reviews[poiId]?.insert(review, at: 0)
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func reportReview(_ review: Review) async {
        guard let user = authService.currentUser else {
            error = "Пользователь не авторизован"
            return
        }
        
        // Only allow reporting if not already reported
        guard !review.reported else { return }
        
        var updatedReview = review
        updatedReview.reported = true
        
        do {
            try await firestoreService.updateReview(updatedReview)
            
            // Update local cache
            if let index = reviews[review.poiId]?.firstIndex(where: { $0.id == review.id }) {
                reviews[review.poiId]?[index] = updatedReview
            }
            
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func deleteReview(_ review: Review) async {
        guard let user = authService.currentUser else {
            error = "Пользователь не авторизован"
            return
        }
        
        // Only allow deletion by review author
        guard review.userId == user.uid else {
            error = "Недостаточно прав для удаления отзыва"
            return
        }
        
        do {
            try await firestoreService.deleteReview(review.id)
            
            // Update local cache
            reviews[review.poiId]?.removeAll { $0.id == review.id }
            
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func getReviews(for poiId: String) -> [Review] {
        return reviews[poiId] ?? []
    }
    
    func getAverageRating(for poiId: String) -> Double {
        let poiReviews = getReviews(for: poiId)
        guard !poiReviews.isEmpty else { return 0.0 }
        
        let totalRating = poiReviews.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(poiReviews.count)
    }
    
    func getUserReview(for poiId: String) -> Review? {
        guard let user = authService.currentUser else { return nil }
        return getReviews(for: poiId).first { $0.userId == user.uid }
    }
    
    // MARK: - Questions Management
    
    func loadQuestions(for poiId: String) async {
        isLoading = true
        error = nil
        
        do {
            let questions = try await firestoreService.fetchQuestions(for: poiId)
            self.questions[poiId] = questions
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addQuestion(poiId: String, text: String) async {
        guard let user = authService.currentUser else {
            error = "Пользователь не авторизован"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Check spam quota before posting
            let quotaResult = try await CloudFunctionsService.shared.checkSpamQuota(
                contentType: .question, 
                poiId: poiId
            )
            
            let question = Question(
                id: UUID().uuidString,
                poiId: poiId,
                userId: user.uid,
                text: text,
                createdAt: Date(),
                answeredBy: nil,
                answerText: nil,
                status: "pending"
            )
            
            try await firestoreService.addQuestion(question)
            
            // Update local cache
            if questions[poiId] == nil {
                questions[poiId] = []
            }
            questions[poiId]?.insert(question, at: 0)
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func answerQuestion(_ question: Question, answerText: String) async {
        guard let user = authService.currentUser else {
            error = "Пользователь не авторизован"
            return
        }
        
        // Only allow answering by moderators or admins (simplified check)
        // In production, this should check user roles
        guard user.provider == .google || user.provider == .apple else {
            error = "Недостаточно прав для ответа на вопрос"
            return
        }
        
        var updatedQuestion = question
        updatedQuestion.answeredBy = user.uid
        updatedQuestion.answerText = answerText
        updatedQuestion.status = "answered"
        
        do {
            try await firestoreService.updateQuestion(updatedQuestion)
            
            // Update local cache
            if let index = questions[question.poiId]?.firstIndex(where: { $0.id == question.id }) {
                questions[question.poiId]?[index] = updatedQuestion
            }
            
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func deleteQuestion(_ question: Question) async {
        guard let user = authService.currentUser else {
            error = "Пользователь не авторизован"
            return
        }
        
        // Only allow deletion by question author or moderators
        guard question.userId == user.uid || user.provider == .google || user.provider == .apple else {
            error = "Недостаточно прав для удаления вопроса"
            return
        }
        
        do {
            try await firestoreService.deleteQuestion(question.id)
            
            // Update local cache
            questions[question.poiId]?.removeAll { $0.id == question.id }
            
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func getQuestions(for poiId: String) -> [Question] {
        return questions[poiId] ?? []
    }
    
    func getUserQuestions(for poiId: String) -> [Question] {
        guard let user = authService.currentUser else { return [] }
        return getQuestions(for: poiId).filter { $0.userId == user.uid }
    }
    
    func getPendingQuestions(for poiId: String) -> [Question] {
        return getQuestions(for: poiId).filter { $0.status == "pending" }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        reviews.removeAll()
        questions.removeAll()
    }
    
    func clearCache(for poiId: String) {
        reviews.removeValue(forKey: poiId)
        questions.removeValue(forKey: poiId)
    }
}