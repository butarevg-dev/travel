import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Карта
            MapScreen()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "map.fill" : "map")
                    Text("Карта")
                }
                .tag(0)
            
            // Каталог POI
            POIScreen()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                    Text("Каталог")
                }
                .tag(1)
            
            // Маршруты
            RoutesScreen()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "figure.walk.circle.fill" : "figure.walk.circle")
                    Text("Маршруты")
                }
                .tag(2)
            
            // Профиль
            ProfileScreen()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                    Text("Профиль")
                }
                .tag(3)
        }
        .accentColor(AppColors.primary)
        .onAppear {
            // Настройка внешнего вида TabBar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - RoutesScreen
struct RoutesScreen: View {
    @StateObject private var viewModel = RoutesViewModel()
    @State private var showingRouteDetail = false
    @State private var selectedRoute: Route?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationView {
            AdaptiveLayout {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Популярные маршруты
                        PopularRoutesSection(routes: viewModel.popularRoutes) { route in
                            selectedRoute = route
                            showingRouteDetail = true
                        }
                        
                        // Рекомендуемые маршруты
                        RecommendedRoutesSection(routes: viewModel.recommendedRoutes) { route in
                            selectedRoute = route
                            showingRouteDetail = true
                        }
                        
                        // Создать свой маршрут
                        CreateRouteSection {
                            // Логика создания маршрута
                        }
                    }
                    .padding(horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.lg)
                }
            }
            .navigationTitle("Маршруты")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Фильтры") {
                        // Показать фильтры маршрутов
                    }
                }
            }
            .sheet(isPresented: $showingRouteDetail) {
                if let route = selectedRoute {
                    RouteDetailView(route: route)
                }
            }
        }
    }
}

// MARK: - PopularRoutesSection
struct PopularRoutesSection: View {
    let routes: [Route]
    let onRouteTap: (Route) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Популярные маршруты")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(routes) { route in
                        RouteCard(route: route) {
                            onRouteTap(route)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }
}

// MARK: - RecommendedRoutesSection
struct RecommendedRoutesSection: View {
    let routes: [Route]
    let onRouteTap: (Route) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Рекомендуемые")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.text)
            
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(routes) { route in
                    RouteListItem(route: route) {
                        onRouteTap(route)
                    }
                }
            }
        }
    }
}

// MARK: - CreateRouteSection
struct CreateRouteSection: View {
    let onCreate: () -> Void
    
    var body: some View {
        AppCard {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(AppColors.primary)
                
                Text("Создать свой маршрут")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                Text("Соберите уникальный маршрут из любимых мест")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                
                AppButton(title: "Создать", style: .primary) {
                    onCreate()
                }
            }
            .padding(AppSpacing.lg)
        }
    }
}

// MARK: - RouteCard
struct RouteCard: View {
    let route: Route
    let onTap: () -> Void
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Изображение
                AsyncImage(url: URL(string: route.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppColors.surface)
                        .overlay(
                            Image(systemName: "map")
                                .foregroundColor(AppColors.textSecondary)
                        )
                }
                .frame(width: 200, height: 120)
                .clipped()
                .cornerRadius(AppCornerRadius.medium)
                
                // Информация
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(route.title)
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(route.poiCount) мест")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Image(systemName: "clock")
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(route.duration)ч")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", route.rating))
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text(route.category)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(AppCornerRadius.small)
                    }
                }
            }
        }
        .frame(width: 200)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - RouteListItem
struct RouteListItem: View {
    let route: Route
    let onTap: () -> Void
    
    var body: some View {
        AppCard {
            HStack(spacing: AppSpacing.md) {
                // Изображение
                AsyncImage(url: URL(string: route.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppColors.surface)
                        .overlay(
                            Image(systemName: "map")
                                .foregroundColor(AppColors.textSecondary)
                        )
                }
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(AppCornerRadius.medium)
                
                // Информация
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(route.title)
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                        .lineLimit(2)
                    
                    Text(route.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                    
                    HStack {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "mappin.circle")
                                .foregroundColor(AppColors.textSecondary)
                            Text("\(route.poiCount)")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "clock")
                                .foregroundColor(AppColors.textSecondary)
                            Text("\(route.duration)ч")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", route.rating))
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - RoutesViewModel
class RoutesViewModel: ObservableObject {
    @Published var popularRoutes: [Route] = []
    @Published var recommendedRoutes: [Route] = []
    
    init() {
        loadRoutes()
    }
    
    private func loadRoutes() {
        // Загрузка маршрутов
        popularRoutes = [
            Route(
                id: "1",
                title: "Исторический центр Саранска",
                description: "Познакомьтесь с главными достопримечательностями города",
                imageUrl: "",
                category: "История",
                poiCount: 8,
                duration: 3,
                rating: 4.8,
                distance: 2.5
            ),
            Route(
                id: "2",
                title: "Парки и скверы",
                description: "Прогуляйтесь по самым красивым паркам города",
                imageUrl: "",
                category: "Природа",
                poiCount: 5,
                duration: 2,
                rating: 4.6,
                distance: 1.8
            )
        ]
        
        recommendedRoutes = [
            Route(
                id: "3",
                title: "Культурная столица",
                description: "Музеи, театры и культурные центры",
                imageUrl: "",
                category: "Культура",
                poiCount: 6,
                duration: 4,
                rating: 4.7,
                distance: 3.2
            )
        ]
    }
}

// MARK: - RouteDetailView
struct RouteDetailView: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Изображение
                    AsyncImage(url: URL(string: route.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(AppColors.surface)
                            .overlay(
                                Image(systemName: "map")
                                    .foregroundColor(AppColors.textSecondary)
                            )
                    }
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(AppCornerRadius.medium)
                    
                    // Информация
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        // Название и рейтинг
                        HStack {
                            Text(route.title)
                                .font(AppTypography.title1)
                                .foregroundColor(AppColors.text)
                            
                            Spacer()
                            
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", route.rating))
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.text)
                            }
                        }
                        
                        // Описание
                        Text(route.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                        
                        // Статистика
                        HStack {
                            StatItem(title: "Мест", value: "\(route.poiCount)")
                            StatItem(title: "Время", value: "\(route.duration)ч")
                            StatItem(title: "Расстояние", value: "\(route.distance)км")
                        }
                        
                        // Кнопки действий
                        HStack {
                            AppButton(title: "Начать маршрут", style: .primary) {
                                // Начать маршрут
                            }
                            
                            AppButton(title: "Поделиться", style: .outline) {
                                // Поделиться маршрутом
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
            .navigationTitle("Маршрут")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Route Model
struct Route: Identifiable {
    let id: String
    let title: String
    let description: String
    let imageUrl: String
    let category: String
    let poiCount: Int
    let duration: Int
    let rating: Double
    let distance: Double
}

#Preview {
    MainTabView()
}