import Foundation
import Combine

@MainActor
class EventService: ObservableObject {
    static let shared = EventService()
    
    // MARK: - Published Properties
    @Published var events: [Event] = []
    @Published var userEvents: [UserEvent] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedCategory: String = "all"
    @Published var selectedStatus: EventStatus = .upcoming
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Service Dependencies
    private let firestoreService = FirestoreService.shared
    private let analyticsService = AnalyticsService.shared
    private let userService = UserService.shared
    private let locationService = LocationService.shared
    
    private init() {
        loadEvents()
        loadUserEvents()
    }
    
    // MARK: - Events Management
    func loadEvents() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let events = try await firestoreService.fetchEvents()
                await MainActor.run {
                    self.events = events
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadUserEvents() {
        guard let userId = userService.currentProfile?.id else { return }
        
        Task {
            do {
                let userEvents = try await firestoreService.fetchUserEvents(userId: userId)
                await MainActor.run {
                    self.userEvents = userEvents
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Event Registration
    func registerForEvent(_ event: Event) async {
        guard let userId = userService.currentProfile?.id else {
            error = "Пользователь не авторизован"
            return
        }
        
        guard event.isActive && !event.isFull else {
            error = "Событие недоступно или переполнено"
            return
        }
        
        // Проверяем, не зарегистрированы ли уже
        if userEvents.contains(where: { $0.eventId == event.id && $0.status == .registered }) {
            error = "Вы уже зарегистрированы на это событие"
            return
        }
        
        do {
            // Создаем пользовательское событие
            let userEvent = UserEvent(
                id: UUID().uuidString,
                eventId: event.id,
                userId: userId,
                registeredAt: Date(),
                attendedAt: nil,
                status: .registered,
                event: event
            )
            
            // Сохраняем в Firestore
            try await firestoreService.saveUserEvent(userEvent)
            
            // Обновляем счетчик участников
            try await firestoreService.updateEventParticipants(event.id)
            
            // Отслеживаем в аналитике
            await analyticsService.trackEventRegistration(event)
            
            // Обновляем локальные данные
            await MainActor.run {
                self.userEvents.append(userEvent)
                self.loadEvents() // Обновляем счетчики
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    func cancelEventRegistration(_ event: Event) async {
        guard let userId = userService.currentProfile?.id else {
            error = "Пользователь не авторизован"
            return
        }
        
        guard let userEvent = userEvents.first(where: { $0.eventId == event.id && $0.userId == userId }) else {
            error = "Регистрация не найдена"
            return
        }
        
        do {
            // Обновляем статус события
            let updatedUserEvent = UserEvent(
                id: userEvent.id,
                eventId: userEvent.eventId,
                userId: userEvent.userId,
                registeredAt: userEvent.registeredAt,
                attendedAt: userEvent.attendedAt,
                status: .cancelled,
                event: userEvent.event
            )
            
            // Сохраняем в Firestore
            try await firestoreService.updateUserEvent(updatedUserEvent)
            
            // Уменьшаем счетчик участников
            try await firestoreService.decreaseEventParticipants(event.id)
            
            // Отслеживаем отмену в аналитике
            await analyticsService.trackEventCancellation(event)
            
            // Обновляем локальные данные
            await MainActor.run {
                if let index = self.userEvents.firstIndex(where: { $0.id == userEvent.id }) {
                    self.userEvents[index] = updatedUserEvent
                }
                self.loadEvents() // Обновляем счетчики
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    func markEventAsAttended(_ event: Event) async {
        guard let userId = userService.currentProfile?.id else {
            error = "Пользователь не авторизован"
            return
        }
        
        guard let userEvent = userEvents.first(where: { $0.eventId == event.id && $0.userId == userId }) else {
            error = "Регистрация не найдена"
            return
        }
        
        do {
            // Обновляем статус события
            let updatedUserEvent = UserEvent(
                id: userEvent.id,
                eventId: userEvent.eventId,
                userId: userEvent.userId,
                registeredAt: userEvent.registeredAt,
                attendedAt: Date(),
                status: .attended,
                event: userEvent.event
            )
            
            // Сохраняем в Firestore
            try await firestoreService.updateUserEvent(updatedUserEvent)
            
            // Отслеживаем посещение в аналитике
            await analyticsService.trackEventAttendance(event)
            
            // Обновляем локальные данные
            await MainActor.run {
                if let index = self.userEvents.firstIndex(where: { $0.id == userEvent.id }) {
                    self.userEvents[index] = updatedUserEvent
                }
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    // MARK: - Filtering and Search
    var filteredEvents: [Event] {
        var filtered = events.filter { $0.isActive }
        
        // Фильтр по категории
        if selectedCategory != "all" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Фильтр по статусу
        filtered = filtered.filter { $0.status == selectedStatus }
        
        return filtered
    }
    
    var availableCategories: [String] {
        let categories = Set(events.map { $0.category })
        return ["all"] + Array(categories).sorted()
    }
    
    func getEventsByCategory(_ category: String) -> [Event] {
        if category == "all" {
            return events.filter { $0.isActive }
        }
        return events.filter { $0.isActive && $0.category == category }
    }
    
    func getEventsByStatus(_ status: EventStatus) -> [Event] {
        return events.filter { $0.isActive && $0.status == status }
    }
    
    func getNearbyEvents(radius: Double = 5000) -> [Event] {
        guard let userLocation = locationService.currentLocation else {
            return []
        }
        
        return events.filter { event in
            let eventLocation = CLLocation(latitude: event.location.latitude, longitude: event.location.longitude)
            let distance = userLocation.distance(from: eventLocation)
            return distance <= radius && event.isActive
        }
    }
    
    // MARK: - User Events Management
    var registeredEvents: [UserEvent] {
        return userEvents.filter { $0.status == .registered }
    }
    
    var attendedEvents: [UserEvent] {
        return userEvents.filter { $0.status == .attended }
    }
    
    var cancelledEvents: [UserEvent] {
        return userEvents.filter { $0.status == .cancelled }
    }
    
    func isRegisteredForEvent(_ eventId: String) -> Bool {
        return userEvents.contains { $0.eventId == eventId && $0.status == .registered }
    }
    
    func hasAttendedEvent(_ eventId: String) -> Bool {
        return userEvents.contains { $0.eventId == eventId && $0.status == .attended }
    }
    
    func getUserEvent(for eventId: String) -> UserEvent? {
        return userEvents.first { $0.eventId == eventId }
    }
    
    // MARK: - Analytics and Tracking
    func trackEventView(_ event: Event) {
        analyticsService.trackEvent("event_viewed", parameters: [
            "event_id": event.id,
            "event_category": event.category,
            "is_premium": String(event.isPremium),
            "price": event.priceText
        ])
    }
    
    func trackEventClick(_ event: Event) {
        analyticsService.trackEvent("event_clicked", parameters: [
            "event_id": event.id,
            "event_category": event.category
        ])
    }
    
    // MARK: - Revenue Tracking
    func calculateTotalEventRevenue() -> Double {
        return userEvents
            .filter { $0.status == .attended }
            .compactMap { $0.event?.price }
            .reduce(0, +)
    }
    
    func calculateRevenueByCategory(_ category: String) -> Double {
        return userEvents
            .filter { $0.status == .attended && $0.event?.category == category }
            .compactMap { $0.event?.price }
            .reduce(0, +)
    }
    
    func calculateRevenueByPartner(_ partnerId: String) -> Double {
        return userEvents
            .filter { $0.status == .attended && $0.event?.partnerId == partnerId }
            .compactMap { $0.event?.price }
            .reduce(0, +)
    }
    
    // MARK: - Event Statistics
    func getEventStatistics() -> EventStatistics {
        let totalEvents = events.count
        let activeEvents = events.filter { $0.isActive }.count
        let upcomingEvents = events.filter { $0.status == .upcoming }.count
        let ongoingEvents = events.filter { $0.status == .ongoing }.count
        let pastEvents = events.filter { $0.status == .past }.count
        
        let totalRegistrations = userEvents.filter { $0.status == .registered }.count
        let totalAttendances = userEvents.filter { $0.status == .attended }.count
        let totalCancellations = userEvents.filter { $0.status == .cancelled }.count
        
        let totalRevenue = calculateTotalEventRevenue()
        
        return EventStatistics(
            totalEvents: totalEvents,
            activeEvents: activeEvents,
            upcomingEvents: upcomingEvents,
            ongoingEvents: ongoingEvents,
            pastEvents: pastEvents,
            totalRegistrations: totalRegistrations,
            totalAttendances: totalAttendances,
            totalCancellations: totalCancellations,
            totalRevenue: totalRevenue
        )
    }
    
    // MARK: - Notifications
    func scheduleEventReminders() {
        let registeredEvents = userEvents.filter { $0.status == .registered }
        
        for userEvent in registeredEvents {
            guard let event = userEvent.event,
                  let daysUntilEvent = userEvent.daysUntilEvent else { continue }
            
            // Напоминание за день до события
            if daysUntilEvent == 1 {
                scheduleNotification(
                    title: "Напоминание о событии",
                    body: "Завтра состоится событие: \(event.title)",
                    eventId: event.id
                )
            }
            
            // Напоминание за час до события
            if daysUntilEvent == 0 {
                scheduleNotification(
                    title: "Событие скоро начнется",
                    body: "Через час начнется: \(event.title)",
                    eventId: event.id
                )
            }
        }
    }
    
    private func scheduleNotification(title: String, body: String, eventId: String) {
        // Здесь будет логика отправки уведомлений
        // Используется UNUserNotificationCenter
    }
    
    // MARK: - Refresh Data
    func refreshData() {
        loadEvents()
        loadUserEvents()
        scheduleEventReminders()
    }
}

// MARK: - Event Statistics
struct EventStatistics {
    let totalEvents: Int
    let activeEvents: Int
    let upcomingEvents: Int
    let ongoingEvents: Int
    let pastEvents: Int
    let totalRegistrations: Int
    let totalAttendances: Int
    let totalCancellations: Int
    let totalRevenue: Double
    
    var attendanceRate: Double {
        guard totalRegistrations > 0 else { return 0 }
        return Double(totalAttendances) / Double(totalRegistrations)
    }
    
    var cancellationRate: Double {
        guard totalRegistrations > 0 else { return 0 }
        return Double(totalCancellations) / Double(totalRegistrations)
    }
    
    var averageRevenuePerEvent: Double {
        guard totalEvents > 0 else { return 0 }
        return totalRevenue / Double(totalEvents)
    }
}

// MARK: - Mock Data for Development
extension EventService {
    func loadMockData() {
        let mockEvents = [
            Event(
                id: "event_1",
                title: "Фестиваль 'Саранск летом'",
                description: "Ежегодный летний фестиваль с концертами, выставками и развлечениями",
                startDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date().addingTimeInterval(86400)) ?? Date(),
                location: Coordinates(latitude: 54.1833, longitude: 45.1833),
                category: "Фестивали",
                imageURL: nil,
                price: 500,
                maxParticipants: 1000,
                currentParticipants: 250,
                isPremium: false,
                partnerId: "partner_1",
                advertisingBudget: 50000,
                isActive: true
            ),
            Event(
                id: "event_2",
                title: "Экскурсия по историческому центру",
                description: "Увлекательная экскурсия по историческому центру Саранска",
                startDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date().addingTimeInterval(7200)) ?? Date(),
                location: Coordinates(latitude: 54.1840, longitude: 45.1840),
                category: "Экскурсии",
                imageURL: nil,
                price: 200,
                maxParticipants: 20,
                currentParticipants: 15,
                isPremium: true,
                partnerId: "partner_2",
                advertisingBudget: 10000,
                isActive: true
            ),
            Event(
                id: "event_3",
                title: "Выставка современного искусства",
                description: "Выставка работ современных художников Мордовии",
                startDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date(),
                location: Coordinates(latitude: 54.1850, longitude: 45.1850),
                category: "Выставки",
                imageURL: nil,
                price: nil,
                maxParticipants: nil,
                currentParticipants: 0,
                isPremium: false,
                partnerId: "partner_3",
                advertisingBudget: 15000,
                isActive: true
            )
        ]
        
        self.events = mockEvents
        self.isLoading = false
    }
}