import Foundation
import Combine
import FirebaseFirestore

@MainActor
class UserService: ObservableObject {
    static let shared = UserService()
    
    @Published var currentProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: String?
    
    private let firestoreService = FirestoreService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthListener()
    }
    
    // MARK: - Auth State Management
    
    private func setupAuthListener() {
        authService.$currentUser
            .sink { [weak self] user in
                if let user = user {
                    Task {
                        await self?.loadUserProfile(userId: user.uid)
                    }
                } else {
                    self?.currentProfile = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Profile Management
    
    func loadUserProfile(userId: String) async {
        isLoading = true
        error = nil
        
        do {
            currentProfile = try await firestoreService.fetchUserProfile(userId: userId)
            
            // Create profile if doesn't exist
            if currentProfile == nil {
                currentProfile = UserProfile(
                    id: userId,
                    email: authService.currentUser?.email,
                    displayName: authService.currentUser?.displayName,
                    providers: [authService.currentUser?.provider.rawValue ?? "email"],
                    favorites: [],
                    badges: [],
                    routeHistory: [],
                    settings: ["language": "ru", "theme": "light", "notifications": "true"],
                    premiumUntil: nil
                )
                try await saveUserProfile()
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func saveUserProfile() async throws {
        guard let profile = currentProfile else { return }
        
        do {
            try await firestoreService.updateUserProfile(profile)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Favorites Management
    
    func toggleFavorite(poiId: String) async {
        guard var profile = currentProfile else { return }
        
        if profile.favorites.contains(poiId) {
            profile.favorites.removeAll { $0 == poiId }
        } else {
            profile.favorites.append(poiId)
        }
        
        currentProfile = profile
        
        do {
            try await saveUserProfile()
        } catch {
            // Revert on error
            if profile.favorites.contains(poiId) {
                profile.favorites.removeAll { $0 == poiId }
            } else {
                profile.favorites.append(poiId)
            }
            currentProfile = profile
        }
    }
    
    func isFavorite(poiId: String) -> Bool {
        return currentProfile?.favorites.contains(poiId) ?? false
    }
    
    func getFavoritePOIs() async -> [POI] {
        guard let profile = currentProfile, !profile.favorites.isEmpty else { return [] }
        
        do {
            var favoritePOIs: [POI] = []
            for poiId in profile.favorites {
                if let poi = try await firestoreService.fetchPOI(id: poiId) {
                    favoritePOIs.append(poi)
                }
            }
            return favoritePOIs
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }
    
    // MARK: - Route History
    
    func addRouteToHistory(routeId: String) async {
        guard var profile = currentProfile else { return }
        
        // Add to beginning of history (most recent first)
        if !profile.routeHistory.contains(routeId) {
            profile.routeHistory.insert(routeId, at: 0)
            
            // Keep only last 50 routes
            if profile.routeHistory.count > 50 {
                profile.routeHistory = Array(profile.routeHistory.prefix(50))
            }
        }
        
        currentProfile = profile
        
        do {
            try await saveUserProfile()
        } catch {
            // Revert on error
            profile.routeHistory.removeAll { $0 == routeId }
            currentProfile = profile
        }
    }
    
    func getRouteHistory() async -> [Route] {
        guard let profile = currentProfile, !profile.routeHistory.isEmpty else { return [] }
        
        do {
            var historyRoutes: [Route] = []
            for routeId in profile.routeHistory {
                if let route = try await firestoreService.fetchRoute(id: routeId) {
                    historyRoutes.append(route)
                }
            }
            return historyRoutes
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }
    
    func clearRouteHistory() async {
        guard var profile = currentProfile else { return }
        
        profile.routeHistory.removeAll()
        currentProfile = profile
        
        do {
            try await saveUserProfile()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Settings Management
    
    func updateSetting(key: String, value: String) async {
        guard var profile = currentProfile else { return }
        
        profile.settings[key] = value
        currentProfile = profile
        
        do {
            try await saveUserProfile()
        } catch {
            // Revert on error
            profile.settings.removeValue(forKey: key)
            currentProfile = profile
        }
    }
    
    func getSetting(key: String, defaultValue: String = "") -> String {
        return currentProfile?.settings[key] ?? defaultValue
    }
    
    // MARK: - Badges Management
    
    func addBadge(badgeId: String) async {
        guard var profile = currentProfile else { return }
        
        if !profile.badges.contains(badgeId) {
            profile.badges.append(badgeId)
            currentProfile = profile
            
            do {
                try await saveUserProfile()
            } catch {
                // Revert on error
                profile.badges.removeAll { $0 == badgeId }
                currentProfile = profile
            }
        }
    }
    
    func hasBadge(badgeId: String) -> Bool {
        return currentProfile?.badges.contains(badgeId) ?? false
    }
    
    // MARK: - Premium Management
    
    func setPremiumUntil(_ date: Date) async {
        guard var profile = currentProfile else { return }
        
        profile.premiumUntil = date
        currentProfile = profile
        
        do {
            try await saveUserProfile()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func isPremium() -> Bool {
        guard let premiumUntil = currentProfile?.premiumUntil else { return false }
        return premiumUntil > Date()
    }
    
    // MARK: - Profile Update
    
    func updateDisplayName(_ name: String) async {
        guard var profile = currentProfile else { return }
        
        profile.displayName = name
        currentProfile = profile
        
        do {
            try await saveUserProfile()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func updateEmail(_ email: String) async {
        guard var profile = currentProfile else { return }
        
        profile.email = email
        currentProfile = profile
        
        do {
            try await saveUserProfile()
        } catch {
            self.error = error.localizedDescription
        }
    }
}