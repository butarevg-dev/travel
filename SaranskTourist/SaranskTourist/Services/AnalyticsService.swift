import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebasePerformance

@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    // MARK: - Private Properties
    private let analytics = Analytics.analytics()
    private let crashlytics = Crashlytics.crashlytics()
    private let performance = Performance.sharedInstance()
    
    // MARK: - Service Dependencies
    private let userService = UserService.shared
    private let storeKitService = StoreKitService.shared
    
    private init() {
        setupAnalytics()
    }
    
    // MARK: - Analytics Setup
    private func setupAnalytics() {
        // Включаем отладку для разработки
        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(true)
        #endif
        
        // Устанавливаем пользовательские свойства
        setUserProperties()
    }
    
    private func setUserProperties() {
        if let user = userService.currentProfile {
            Analytics.setUserProperty(user.id, forName: "user_id")
            Analytics.setUserProperty(user.displayName, forName: "user_name")
            Analytics.setUserProperty(user.email, forName: "user_email")
            
            let isPremium = userService.checkPremiumStatus()
            Analytics.setUserProperty(String(isPremium), forName: "is_premium")
            
            if let premiumUntil = user.premiumUntil {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                Analytics.setUserProperty(formatter.string(from: premiumUntil), forName: "premium_until")
            }
        }
    }
    
    // MARK: - Event Tracking
    func trackEvent(_ name: String, parameters: [String: String]? = nil) {
        analytics.logEvent(name, parameters: parameters)
        
        #if DEBUG
        print("📊 Analytics Event: \(name)")
        if let parameters = parameters {
            print("📊 Parameters: \(parameters)")
        }
        #endif
    }
    
    func trackEvent(_ name: String, parameters: [String: Any]? = nil) {
        analytics.logEvent(name, parameters: parameters)
        
        #if DEBUG
        print("📊 Analytics Event: \(name)")
        if let parameters = parameters {
            print("📊 Parameters: \(parameters)")
        }
        #endif
    }
    
    // MARK: - Screen Tracking
    func trackScreen(_ screenName: String, screenClass: String? = nil) {
        analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
        
        #if DEBUG
        print("📊 Screen View: \(screenName)")
        #endif
    }
    
    // MARK: - User Engagement
    func trackUserEngagement(engagementTime: TimeInterval) {
        analytics.logEvent(AnalyticsEventUserEngagement, parameters: [
            AnalyticsParameterEngagementTimeMs: Int(engagementTime * 1000)
        ])
    }
    
    func trackAppOpen() {
        analytics.logEvent(AnalyticsEventAppOpen)
    }
    
    func trackAppUpdate(previousVersion: String, newVersion: String) {
        analytics.logEvent("app_update", parameters: [
            "previous_version": previousVersion,
            "new_version": newVersion
        ])
    }
    
    // MARK: - Purchase Tracking
    func trackPurchase(productId: String, price: Decimal, currency: String) {
        analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterValue: price,
            AnalyticsParameterCurrency: currency
        ])
    }
    
    func trackSubscriptionStart(productId: String, period: SubscriptionPeriod) {
        analytics.logEvent("subscription_started", parameters: [
            "product_id": productId,
            "period": period.rawValue,
            "subscription_status": storeKitService.subscriptionStatus.rawValue
        ])
    }
    
    func trackSubscriptionCancel(productId: String, reason: String? = nil) {
        var parameters: [String: String] = [
            "product_id": productId,
            "subscription_status": storeKitService.subscriptionStatus.rawValue
        ]
        
        if let reason = reason {
            parameters["cancel_reason"] = reason
        }
        
        analytics.logEvent("subscription_cancelled", parameters: parameters)
    }
    
    func trackSubscriptionRenewal(productId: String) {
        analytics.logEvent("subscription_renewed", parameters: [
            "product_id": productId,
            "subscription_status": storeKitService.subscriptionStatus.rawValue
        ])
    }
    
    // MARK: - Partner Offers Tracking
    func trackOfferActivation(_ offer: PartnerOffer) {
        analytics.logEvent("offer_activated", parameters: [
            "offer_id": offer.id,
            "partner_id": offer.partnerId,
            "partner_name": offer.partnerName,
            "category": offer.category,
            "discount": String(offer.discount),
            "commission": String(offer.commission)
        ])
    }
    
    func trackOfferUsage(_ offer: PartnerOffer) {
        analytics.logEvent("offer_used", parameters: [
            "offer_id": offer.id,
            "partner_id": offer.partnerId,
            "partner_name": offer.partnerName,
            "category": offer.category,
            "discount": String(offer.discount),
            "commission": String(offer.commission)
        ])
    }
    
    func trackOfferView(_ offer: PartnerOffer) {
        analytics.logEvent("offer_viewed", parameters: [
            "offer_id": offer.id,
            "partner_id": offer.partnerId,
            "category": offer.category,
            "discount": String(offer.discount)
        ])
    }
    
    // MARK: - Events Tracking
    func trackEventRegistration(_ event: Event) {
        analytics.logEvent("event_registered", parameters: [
            "event_id": event.id,
            "event_title": event.title,
            "event_category": event.category,
            "is_premium": String(event.isPremium),
            "price": event.priceText,
            "participants": String(event.currentParticipants)
        ])
    }
    
    func trackEventCancellation(_ event: Event) {
        analytics.logEvent("event_cancelled", parameters: [
            "event_id": event.id,
            "event_title": event.title,
            "event_category": event.category
        ])
    }
    
    func trackEventAttendance(_ event: Event) {
        analytics.logEvent("event_attended", parameters: [
            "event_id": event.id,
            "event_title": event.title,
            "event_category": event.category,
            "price": event.priceText
        ])
    }
    
    func trackEventView(_ event: Event) {
        analytics.logEvent("event_viewed", parameters: [
            "event_id": event.id,
            "event_category": event.category,
            "is_premium": String(event.isPremium),
            "price": event.priceText
        ])
    }
    
    // MARK: - Feature Usage Tracking
    func trackFeatureUsage(_ feature: PremiumFeature) {
        analytics.logEvent("feature_used", parameters: [
            "feature_name": feature.rawValue,
            "feature_title": feature.title,
            "is_premium": String(storeKitService.hasPremiumFeature(feature))
        ])
    }
    
    func trackPOIVisit(_ poi: POI) {
        analytics.logEvent("poi_visited", parameters: [
            "poi_id": poi.id,
            "poi_title": poi.title,
            "poi_category": poi.categories.joined(separator: ","),
            "has_audio": String(!poi.audio.isEmpty)
        ])
    }
    
    func trackRouteCompletion(_ route: Route) {
        analytics.logEvent("route_completed", parameters: [
            "route_id": route.id,
            "route_title": route.title,
            "route_category": route.category,
            "duration_minutes": String(route.durationMinutes),
            "distance_km": String(route.distanceKm),
            "is_premium": String(route.isPremium)
        ])
    }
    
    func trackARUsage(mode: ARMode, duration: TimeInterval) {
        analytics.logEvent("ar_used", parameters: [
            "ar_mode": mode.rawValue,
            "duration_seconds": String(Int(duration)),
            "is_premium": String(storeKitService.hasPremiumFeature(.arQuests))
        ])
    }
    
    func trackAudioPlayback(poiId: String, duration: TimeInterval) {
        analytics.logEvent("audio_played", parameters: [
            "poi_id": poiId,
            "duration_seconds": String(Int(duration))
        ])
    }
    
    // MARK: - Error Tracking
    func trackError(_ error: Error, context: String) {
        crashlytics.record(error: error, userInfo: ["context": context])
        
        analytics.logEvent("app_error", parameters: [
            "error_description": error.localizedDescription,
            "error_context": context,
            "error_type": String(describing: type(of: error))
        ])
        
        #if DEBUG
        print("❌ Error tracked: \(error.localizedDescription) in context: \(context)")
        #endif
    }
    
    func trackError(_ message: String, context: String) {
        let error = NSError(domain: "SaranskTourist", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
        trackError(error, context: context)
    }
    
    // MARK: - Performance Tracking
    func startTrace(_ name: String) -> Trace {
        let trace = performance.trace(name: name)
        trace.start()
        
        #if DEBUG
        print("⏱️ Performance trace started: \(name)")
        #endif
        
        return trace
    }
    
    func trackAppLaunchTime(_ time: TimeInterval) {
        analytics.logEvent("app_launch_time", parameters: [
            "launch_time_seconds": String(time)
        ])
        
        #if DEBUG
        print("⏱️ App launch time: \(time) seconds")
        #endif
    }
    
    func trackMapLoadTime(_ time: TimeInterval) {
        analytics.logEvent("map_load_time", parameters: [
            "load_time_seconds": String(time)
        ])
    }
    
    func trackAudioLoadTime(_ time: TimeInterval) {
        analytics.logEvent("audio_load_time", parameters: [
            "load_time_seconds": String(time)
        ])
    }
    
    func trackARSessionStartTime(_ time: TimeInterval) {
        analytics.logEvent("ar_session_start_time", parameters: [
            "start_time_seconds": String(time)
        ])
    }
    
    // MARK: - User Behavior Tracking
    func trackSearch(query: String, results: Int) {
        analytics.logEvent(AnalyticsEventSearch, parameters: [
            AnalyticsParameterSearchTerm: query,
            "results_count": String(results)
        ])
    }
    
    func trackFilterUsage(filterName: String, filterValue: String) {
        analytics.logEvent("filter_used", parameters: [
            "filter_name": filterName,
            "filter_value": filterValue
        ])
    }
    
    func trackShare(contentType: String, contentId: String) {
        analytics.logEvent(AnalyticsEventShare, parameters: [
            AnalyticsParameterContentType: contentType,
            AnalyticsParameterItemID: contentId
        ])
    }
    
    func trackRating(rating: Int, contentType: String, contentId: String) {
        analytics.logEvent("content_rated", parameters: [
            "rating": String(rating),
            "content_type": contentType,
            "content_id": contentId
        ])
    }
    
    // MARK: - Offline Usage Tracking
    func trackOfflineUsage(duration: TimeInterval, features: [String]) {
        analytics.logEvent("offline_usage", parameters: [
            "duration_minutes": String(Int(duration / 60)),
            "features_used": features.joined(separator: ",")
        ])
    }
    
    func trackCacheUsage(cacheType: String, size: Int64) {
        analytics.logEvent("cache_usage", parameters: [
            "cache_type": cacheType,
            "size_mb": String(size / 1024 / 1024)
        ])
    }
    
    // MARK: - Gamification Tracking
    func trackBadgeUnlocked(_ badge: Badge) {
        analytics.logEvent("badge_unlocked", parameters: [
            "badge_id": badge.id,
            "badge_title": badge.title,
            "badge_category": badge.category
        ])
    }
    
    func trackQuestCompleted(_ quest: Quest) {
        analytics.logEvent("quest_completed", parameters: [
            "quest_id": quest.id,
            "quest_title": quest.title,
            "quest_type": quest.type.rawValue,
            "reward_experience": String(quest.reward.experience),
            "reward_coins": String(quest.reward.coins)
        ])
    }
    
    func trackAchievementUnlocked(_ achievement: Achievement) {
        analytics.logEvent("achievement_unlocked", parameters: [
            "achievement_id": achievement.id,
            "achievement_title": achievement.title,
            "achievement_category": achievement.category
        ])
    }
    
    // MARK: - Revenue Tracking
    func trackRevenue(source: String, amount: Double, currency: String) {
        analytics.logEvent("revenue_generated", parameters: [
            "revenue_source": source,
            "amount": String(amount),
            "currency": currency
        ])
    }
    
    func trackConversion(source: String, target: String, value: Double) {
        analytics.logEvent("conversion", parameters: [
            "conversion_source": source,
            "conversion_target": target,
            "conversion_value": String(value)
        ])
    }
    
    // MARK: - User Properties Updates
    func updateUserProperties() {
        setUserProperties()
    }
    
    func setUserProperty(_ value: String?, forName name: String) {
        analytics.setUserProperty(value, forName: name)
    }
    
    func setUserID(_ userID: String) {
        analytics.setUserID(userID)
        crashlytics.setUserID(userID)
    }
    
    // MARK: - Debug and Development
    #if DEBUG
    func enableDebugMode() {
        Analytics.setAnalyticsCollectionEnabled(true)
        print("🔍 Analytics debug mode enabled")
    }
    
    func logDebugEvent(_ name: String, parameters: [String: Any]? = nil) {
        print("🔍 Debug Event: \(name)")
        if let parameters = parameters {
            print("🔍 Parameters: \(parameters)")
        }
        trackEvent(name, parameters: parameters)
    }
    #endif
}

// MARK: - Analytics Constants
extension AnalyticsService {
    struct EventNames {
        static let appOpen = AnalyticsEventAppOpen
        static let appUpdate = "app_update"
        static let purchase = AnalyticsEventPurchase
        static let subscriptionStart = "subscription_started"
        static let subscriptionCancel = "subscription_cancelled"
        static let subscriptionRenewal = "subscription_renewed"
        static let offerActivation = "offer_activated"
        static let offerUsage = "offer_used"
        static let offerView = "offer_viewed"
        static let eventRegistration = "event_registered"
        static let eventCancellation = "event_cancelled"
        static let eventAttendance = "event_attended"
        static let eventView = "event_viewed"
        static let featureUsage = "feature_used"
        static let poiVisit = "poi_visited"
        static let routeCompletion = "route_completed"
        static let arUsage = "ar_used"
        static let audioPlayback = "audio_played"
        static let appError = "app_error"
        static let appLaunchTime = "app_launch_time"
        static let mapLoadTime = "map_load_time"
        static let audioLoadTime = "audio_load_time"
        static let arSessionStartTime = "ar_session_start_time"
        static let search = AnalyticsEventSearch
        static let filterUsage = "filter_used"
        static let share = AnalyticsEventShare
        static let rating = "content_rated"
        static let offlineUsage = "offline_usage"
        static let cacheUsage = "cache_usage"
        static let badgeUnlocked = "badge_unlocked"
        static let questCompleted = "quest_completed"
        static let achievementUnlocked = "achievement_unlocked"
        static let revenueGenerated = "revenue_generated"
        static let conversion = "conversion"
    }
    
    struct ParameterNames {
        static let itemID = AnalyticsParameterItemID
        static let itemName = AnalyticsParameterItemName
        static let value = AnalyticsParameterValue
        static let currency = AnalyticsParameterCurrency
        static let screenName = AnalyticsParameterScreenName
        static let screenClass = AnalyticsParameterScreenClass
        static let searchTerm = AnalyticsParameterSearchTerm
        static let contentType = AnalyticsParameterContentType
        static let engagementTimeMs = AnalyticsParameterEngagementTimeMs
    }
}