import SwiftUI
import StoreKit

struct PremiumScreen: View {
    @StateObject private var storeKitService = StoreKitService.shared
    @StateObject private var userService = UserService.shared
    @StateObject private var partnerService = PartnerService.shared
    @StateObject private var eventService = EventService.shared
    @State private var selectedProduct: SubscriptionProduct?
    @State private var showingPurchaseSheet = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    PremiumHeader()
                    
                    // Features
                    PremiumFeaturesList()
                    
                    // Subscription Plans
                    SubscriptionPlansView(
                        selectedProduct: $selectedProduct,
                        showingPurchaseSheet: $showingPurchaseSheet
                    )
                    
                    // Partner Offers
                    PartnerOffersView()
                    
                    // Event Advertising
                    EventAdvertisingView()
                }
                .padding()
            }
            .navigationTitle("Премиум")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPurchaseSheet) {
                PurchaseSheet(product: selectedProduct)
            }
            .refreshable {
                await refreshData()
            }
        }
        .onAppear {
            storeKitService.loadProducts()
            partnerService.loadPartnerOffers()
            eventService.loadEvents()
        }
    }
    
    private func refreshData() async {
        storeKitService.loadProducts()
        partnerService.loadPartnerOffers()
        eventService.loadEvents()
    }
}

// MARK: - Premium Header
struct PremiumHeader: View {
    @StateObject private var userService = UserService.shared
    @StateObject private var storeKitService = StoreKitService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
            
            // Title
            Text("Премиум подписка")
                .font(.title)
                .fontWeight(.bold)
            
            // Description
            Text("Откройте для себя все возможности приложения")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Current Status
            if userService.checkPremiumStatus() {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Премиум активен")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
            } else {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Бесплатная версия")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

// MARK: - Premium Features List
struct PremiumFeaturesList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Премиум функции")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PremiumFeature.allCases, id: \.self) { feature in
                    PremiumFeatureCard(feature: feature)
                }
            }
        }
    }
}

struct PremiumFeatureCard: View {
    let feature: PremiumFeature
    @StateObject private var storeKitService = StoreKitService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: feature.icon)
                    .font(.title2)
                    .foregroundColor(storeKitService.hasPremiumFeature(feature) ? .green : .gray)
                
                Spacer()
                
                if storeKitService.hasPremiumFeature(feature) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Text(feature.title)
                .font(.headline)
                .foregroundColor(storeKitService.hasPremiumFeature(feature) ? .primary : .secondary)
            
            Text(feature.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Subscription Plans View
struct SubscriptionPlansView: View {
    @Binding var selectedProduct: SubscriptionProduct?
    @Binding var showingPurchaseSheet: Bool
    @StateObject private var storeKitService = StoreKitService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Планы подписки")
                .font(.title2)
                .fontWeight(.bold)
            
            if storeKitService.isLoading {
                ProgressView("Загрузка планов...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(getSubscriptionProducts(), id: \.id) { product in
                        SubscriptionPlanCard(
                            product: product,
                            isSelected: selectedProduct?.id == product.id
                        ) {
                            selectedProduct = product
                            showingPurchaseSheet = true
                        }
                    }
                }
            }
        }
    }
    
    private func getSubscriptionProducts() -> [SubscriptionProduct] {
        // В реальном приложении здесь будут продукты из StoreKit
        // Пока используем мок данные
        return [
            SubscriptionProduct(
                id: "com.saransk.tourist.premium.monthly",
                title: "Базовая подписка",
                description: "Ежемесячная подписка",
                price: 299,
                currency: "RUB",
                period: .monthly,
                features: [.exclusiveRoutes, .extendedOffline]
            ),
            SubscriptionProduct(
                id: "com.saransk.tourist.premium.yearly",
                title: "Премиум подписка",
                description: "Годовая подписка (экономия 40%)",
                price: 1999,
                currency: "RUB",
                period: .yearly,
                features: PremiumFeature.allCases,
                isPopular: true,
                savings: 40
            ),
            SubscriptionProduct(
                id: "com.saransk.tourist.premium.lifetime",
                title: "Пожизненный доступ",
                description: "Пожизненный доступ ко всем функциям",
                price: 4999,
                currency: "RUB",
                period: .lifetime,
                features: PremiumFeature.allCases
            )
        ]
    }
}

struct SubscriptionPlanCard: View {
    let product: SubscriptionProduct
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if product.isPopular {
                            Text("ПОПУЛЯРНЫЙ")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    
                    Text(product.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let savings = product.savings {
                        Text("Экономия \(savings)%")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(product.price) ₽")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(product.period.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Partner Offers View
struct PartnerOffersView: View {
    @StateObject private var partnerService = PartnerService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Партнерские предложения")
                .font(.title2)
                .fontWeight(.bold)
            
            if partnerService.isLoading {
                ProgressView("Загрузка предложений...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if partnerService.filteredOffers.isEmpty {
                Text("Нет доступных предложений")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(partnerService.filteredOffers.prefix(5)) { offer in
                            PartnerOfferCard(offer: offer)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct PartnerOfferCard: View {
    let offer: PartnerOffer
    @StateObject private var partnerService = PartnerService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Partner Info
            HStack {
                Image(systemName: "handshake.fill")
                    .foregroundColor(.blue)
                Text(offer.partnerName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Offer Title
            Text(offer.title)
                .font(.headline)
                .lineLimit(2)
            
            // Discount
            Text(offer.discountText)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            // Description
            Text(offer.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Valid Until
            Text(offer.validUntilText)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Action Button
            Button(action: {
                Task {
                    await partnerService.activateOffer(offer)
                }
            }) {
                Text(partnerService.hasActiveOffer(for: offer.id) ? "Активировано" : "Активировать")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(partnerService.hasActiveOffer(for: offer.id) ? Color.green : Color.blue)
                    .cornerRadius(8)
            }
            .disabled(partnerService.hasActiveOffer(for: offer.id))
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Event Advertising View
struct EventAdvertisingView: View {
    @StateObject private var eventService = EventService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ближайшие события")
                .font(.title2)
                .fontWeight(.bold)
            
            if eventService.isLoading {
                ProgressView("Загрузка событий...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if eventService.filteredEvents.isEmpty {
                Text("Нет предстоящих событий")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(eventService.filteredEvents.prefix(3)) { event in
                        EventCard(event: event)
                    }
                }
            }
        }
    }
}

struct EventCard: View {
    let event: Event
    @StateObject private var eventService = EventService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(event.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(event.priceText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(event.participantsText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(event.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(formatEventDate(event.startDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if event.isPremium {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("Премиум")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .fontWeight(.semibold)
                }
            }
            
            Button(action: {
                Task {
                    if eventService.isRegisteredForEvent(event.id) {
                        await eventService.cancelEventRegistration(event)
                    } else {
                        await eventService.registerForEvent(event)
                    }
                }
            }) {
                Text(eventService.isRegisteredForEvent(event.id) ? "Отменить регистрацию" : "Зарегистрироваться")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(eventService.isRegisteredForEvent(event.id) ? Color.red : Color.blue)
                    .cornerRadius(8)
            }
            .disabled(event.isFull && !eventService.isRegisteredForEvent(event.id))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Purchase Sheet
struct PurchaseSheet: View {
    let product: SubscriptionProduct?
    @StateObject private var storeKitService = StoreKitService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let product = product {
                    // Product Info
                    ProductInfoView(product: product)
                    
                    // Features
                    FeaturesListView(product: product)
                    
                    // Purchase Button
                    PurchaseButton(product: product)
                    
                    // Terms and Privacy
                    TermsAndPrivacyView()
                } else {
                    Text("Продукт не найден")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("Покупка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProductInfoView: View {
    let product: SubscriptionProduct
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
            
            Text(product.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(product.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                Text("\(product.price) ₽")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(product.period.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let savings = product.savings {
                Text("Экономия \(savings)%")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FeaturesListView: View {
    let product: SubscriptionProduct
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Включенные функции")
                .font(.headline)
            
            ForEach(product.features, id: \.self) { feature in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text(feature.title)
                        .font(.subheadline)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PurchaseButton: View {
    let product: SubscriptionProduct
    @StateObject private var storeKitService = StoreKitService.shared
    
    var body: some View {
        Button(action: {
            Task {
                do {
                    try await storeKitService.purchaseSubscription(product)
                } catch {
                    // Ошибка обрабатывается в StoreKitService
                }
            }
        }) {
            HStack {
                if storeKitService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "cart.fill")
                }
                
                Text(storeKitService.isLoading ? "Обработка..." : "Купить")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(storeKitService.isLoading)
    }
}

struct TermsAndPrivacyView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Нажимая «Купить», вы соглашаетесь с")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Button("Условиями использования") {
                    // Открыть условия использования
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Text("и")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Политикой конфиденциальности") {
                    // Открыть политику конфиденциальности
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PremiumScreen()
}