# 🎨 Руководство по разработке UI
## Проект: "Саранск для Туристов" - iOS приложение

---

## 📋 ОБЩИЙ ПОДХОД К РАЗРАБОТКЕ UI

### 🎯 Принципы разработки
- **Mobile-first дизайн** — приоритет мобильного опыта
- **Консистентность** — единый стиль во всем приложении
- **Доступность** — поддержка VoiceOver, Dynamic Type
- **Производительность** — плавная анимация, быстрая отзывчивость
- **Адаптивность** — работа на всех размерах экранов

### 🏗️ Архитектура UI
- **SwiftUI** — основной UI framework
- **MVVM** — архитектурный паттерн
- **Combine** — реактивное программирование
- **Modular Design** — переиспользуемые компоненты

### 📱 Адаптивность устройств

#### Поддерживаемые устройства и разрешения:

**iPhone (Portrait):**
- **iPhone SE (2nd gen):** 375×667
- **iPhone SE (3rd gen):** 375×667
- **iPhone 8:** 375×667
- **iPhone 8 Plus:** 414×736
- **iPhone X:** 375×812
- **iPhone XS:** 375×812
- **iPhone XS Max:** 414×896
- **iPhone XR:** 414×896
- **iPhone 11:** 414×896
- **iPhone 11 Pro:** 375×812
- **iPhone 11 Pro Max:** 414×896
- **iPhone 12 mini:** 375×812
- **iPhone 12:** 390×844
- **iPhone 12 Pro:** 390×844
- **iPhone 12 Pro Max:** 428×926
- **iPhone 13 mini:** 375×812
- **iPhone 13:** 390×844
- **iPhone 13 Pro:** 390×844
- **iPhone 13 Pro Max:** 428×926
- **iPhone 14:** 390×844
- **iPhone 14 Plus:** 428×926
- **iPhone 14 Pro:** 393×852
- **iPhone 14 Pro Max:** 430×932
- **iPhone 15:** 393×852
- **iPhone 15 Plus:** 430×932
- **iPhone 15 Pro:** 393×852
- **iPhone 15 Pro Max:** 430×932

**iPhone (Landscape):**
- **iPhone SE (2nd/3rd gen):** 667×375
- **iPhone 8:** 667×375
- **iPhone 8 Plus:** 736×414
- **iPhone X/XS/11 Pro:** 812×375
- **iPhone XS Max/11 Pro Max:** 896×414
- **iPhone XR/11:** 896×414
- **iPhone 12/13 mini:** 812×375
- **iPhone 12/13/14:** 844×390
- **iPhone 12/13/14 Pro:** 844×390
- **iPhone 12/13/14 Pro Max:** 926×428
- **iPhone 14 Plus:** 926×428
- **iPhone 14/15 Pro:** 852×393
- **iPhone 14/15 Pro Max:** 932×430
- **iPhone 15 Plus:** 932×430

**iPad (Portrait):**
- **iPad (9th gen):** 810×1080
- **iPad (10th gen):** 820×1180
- **iPad Air (4th gen):** 820×1180
- **iPad Air (5th gen):** 820×1180
- **iPad Pro 11" (1st-4th gen):** 834×1194
- **iPad Pro 12.9" (1st-6th gen):** 1024×1366

**iPad (Landscape):**
- **iPad (9th gen):** 1080×810
- **iPad (10th gen):** 1180×820
- **iPad Air (4th gen):** 1180×820
- **iPad Air (5th gen):** 1180×820
- **iPad Pro 11" (1st-4th gen):** 1194×834
- **iPad Pro 12.9" (1st-6th gen):** 1366×1024

#### Принципы адаптивности:
- **Responsive Design** — адаптация под размер экрана
- **Orientation Support** — поддержка Portrait и Landscape
- **Safe Area** — учет безопасных зон
- **Dynamic Type** — адаптивная типографика
- **Accessibility** — поддержка доступности

#### Ключевые размеры экранов:
- **Compact Width:** iPhone в Portrait (375-430pt)
- **Regular Width:** iPhone в Landscape, iPad (667-1366pt)
- **Compact Height:** iPhone в Landscape (375-430pt)
- **Regular Height:** iPhone в Portrait, iPad (667-1366pt)

#### Диапазоны размеров:
- **iPhone Portrait:** 375×667 - 430×932
- **iPhone Landscape:** 667×375 - 932×430
- **iPad Portrait:** 810×1080 - 1024×1366
- **iPad Landscape:** 1080×810 - 1366×1024

#### Scale Factors:
- **iPhone:** 2x, 3x (@2x, @3x)
- **iPad:** 1x, 2x (@1x, @2x)

---

## 🚀 ЭТАПЫ РАЗРАБОТКИ UI

### 📱 Этап 1: Дизайн-система (1-2 недели)

#### 1.1 Создание дизайн-системы
```swift
// Colors.swift
struct AppColors {
    static let primary = Color("PrimaryColor")
    static let secondary = Color("SecondaryColor")
    static let accent = Color("AccentColor")
    static let background = Color("BackgroundColor")
    static let surface = Color("SurfaceColor")
    static let text = Color("TextColor")
    static let textSecondary = Color("TextSecondaryColor")
    static let error = Color("ErrorColor")
    static let success = Color("SuccessColor")
    static let warning = Color("WarningColor")
}

// Typography.swift
struct AppTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title1 = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .semibold)
    static let title3 = Font.system(size: 20, weight: .semibold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption1 = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)
}

// Spacing.swift
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// CornerRadius.swift
struct AppCornerRadius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
    static let xlarge: CGFloat = 16
    static let round: CGFloat = 25
}
```

#### 1.2 Базовые компоненты
```swift
// AppButton.swift
struct AppButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, outline, text
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(backgroundColor)
                .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return AppColors.primary
        case .secondary: return AppColors.secondary
        case .outline: return Color.clear
        case .text: return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .white
        case .outline: return AppColors.primary
        case .text: return AppColors.primary
        }
    }
}

// AppTextField.swift
struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            TextField(placeholder, text: $text)
                .font(AppTypography.body)
                .foregroundColor(AppColors.text)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .stroke(AppColors.textSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// AppCard.swift
struct AppCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.large)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// AdaptiveLayout.swift
struct AdaptiveLayout<Content: View>: View {
    let content: Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // iPhone в Portrait
                content
                    .padding(.horizontal, AppSpacing.md)
            } else {
                // iPad или iPhone в Landscape
                content
                    .padding(.horizontal, AppSpacing.xl)
                    .frame(maxWidth: 600)
            }
        }
    }
}

// ResponsiveGrid.swift
struct ResponsiveGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let columns: Int
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(data: Data, columns: Int = 2, spacing: CGFloat = AppSpacing.md, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    var adaptiveColumns: Int {
        switch horizontalSizeClass {
        case .compact:
            return 1 // iPhone Portrait
        case .regular:
            return columns // iPad или iPhone Landscape
        default:
            return 1
        }
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: adaptiveColumns), spacing: spacing) {
            ForEach(data) { item in
                content(item)
            }
        }
    }
}

// SafeAreaView.swift
struct SafeAreaView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
    }
}
```

### 🗺️ Этап 2: Карта и навигация (2-3 недели)

#### 2.1 Основная карта
```swift
// MapScreen.swift
struct MapScreen: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var selectedPOI: POI?
    @State private var showingPOIDetail = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationView {
            AdaptiveLayout {
                ZStack {
                    // Основная карта
                    CustomMapView(
                        pois: viewModel.pois,
                        selectedPOI: $selectedPOI,
                        userLocation: viewModel.userLocation
                    )
                    
                    // Поисковая панель
                    VStack {
                        SearchPanel(
                            searchText: $viewModel.searchText,
                            selectedCategory: $viewModel.selectedCategory
                        )
                        .padding(.top, horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.lg)
                        
                        Spacer()
                        
                        // Панель фильтров
                        if !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil {
                            FilterPanel(
                                selectedCategory: $viewModel.selectedCategory,
                                selectedFilters: $viewModel.selectedFilters
                            )
                            .padding(.bottom, horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.lg)
                        }
                    }
                }
            }
            .navigationTitle("Карта")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Фильтры") {
                        viewModel.showingFilters = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Мое местоположение") {
                        viewModel.centerOnUserLocation()
                    }
                }
            }
            .sheet(isPresented: $showingPOIDetail) {
                if let poi = selectedPOI {
                    POIDetailView(poi: poi)
                }
            }
            .sheet(isPresented: $viewModel.showingFilters) {
                FilterView(selectedFilters: $viewModel.selectedFilters)
            }
        }
    }
}

// CustomMapView.swift
struct CustomMapView: UIViewRepresentable {
    let pois: [POI]
    @Binding var selectedPOI: POI?
    let userLocation: CLLocation?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Обновление маркеров POI
        mapView.removeAnnotations(mapView.annotations)
        
        let annotations = pois.map { poi in
            POIAnnotation(poi: poi)
        }
        mapView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let poiAnnotation = annotation as? POIAnnotation else { return nil }
            
            let identifier = "POIAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            }
            
            annotationView?.image = UIImage(named: poiAnnotation.poi.category.iconName)
            annotationView?.annotation = annotation
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let poiAnnotation = view.annotation as? POIAnnotation {
                parent.selectedPOI = poiAnnotation.poi
            }
        }
    }
}
```

#### 2.2 Поисковая панель
```swift
// SearchPanel.swift
struct SearchPanel: View {
    @Binding var searchText: String
    @Binding var selectedCategory: POICategory?
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Поисковая строка
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Поиск достопримечательностей...", text: $searchText)
                    .font(AppTypography.body)
                
                if !searchText.isEmpty {
                    Button("Очистить") {
                        searchText = ""
                    }
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.primary)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.large)
            
            // Быстрые категории
            if searchText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(POICategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }
}

// CategoryChip.swift
struct CategoryChip: View {
    let category: POICategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: category.iconName)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(AppTypography.caption1)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? AppColors.primary : AppColors.surface)
            .foregroundColor(isSelected ? .white : AppColors.text)
            .cornerRadius(AppCornerRadius.round)
        }
    }
}
```

### 🏛️ Этап 3: Каталог POI (2-3 недели)

#### 3.1 Список достопримечательностей
```swift
// POIScreen.swift
struct POIScreen: View {
    @StateObject private var viewModel = POIViewModel()
    @State private var showingFilters = false
    @State private var searchText = ""
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationView {
            AdaptiveLayout {
                VStack(spacing: 0) {
                    // Поисковая панель
                    SearchBar(text: $searchText)
                        .padding(.top, horizontalSizeClass == .compact ? AppSpacing.sm : AppSpacing.md)
                    
                    // Фильтры
                    FilterBar(
                        selectedCategory: $viewModel.selectedCategory,
                        selectedSort: $viewModel.selectedSort
                    )
                    .padding(.top, horizontalSizeClass == .compact ? AppSpacing.sm : AppSpacing.md)
                    
                    // Адаптивная сетка POI
                    ScrollView {
                        ResponsiveGrid(data: viewModel.filteredPOIs, columns: 2) { poi in
                            POICard(poi: poi) {
                                viewModel.selectPOI(poi)
                            }
                        }
                        .padding(horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.lg)
                    }
                }
            }
            .navigationTitle("Достопримечательности")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Фильтры") {
                        showingFilters = true
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingPOIDetail) {
                if let poi = viewModel.selectedPOI {
                    POIDetailView(poi: poi)
                }
            }
            .sheet(isPresented: $showingFilters) {
                POIFilterView(
                    selectedCategory: $viewModel.selectedCategory,
                    selectedFilters: $viewModel.selectedFilters
                )
            }
        }
    }
}

// POICard.swift
struct POICard: View {
    let poi: POI
    let onTap: () -> Void
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Изображение
                AsyncImage(url: URL(string: poi.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppColors.surface)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(AppColors.textSecondary)
                        )
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(AppCornerRadius.medium)
                
                // Информация
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    // Название и рейтинг
                    HStack {
                        Text(poi.name)
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.text)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(String(format: "%.1f", poi.rating))
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    // Категория и адрес
                    HStack {
                        CategoryBadge(category: poi.category)
                        
                        Spacer()
                        
                        Text(poi.address)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    // Описание
                    Text(poi.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.text)
                        .lineLimit(3)
                    
                    // Действия
                    HStack {
                        Button("Подробнее") {
                            onTap()
                        }
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.primary)
                        
                        Spacer()
                        
                        Button("Избранное") {
                            // Добавить в избранное
                        }
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        
                        Button("Поделиться") {
                            // Поделиться POI
                        }
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}
```

### 👤 Этап 4: Профиль пользователя (1-2 недели)

#### 4.1 Экран профиля
```swift
// ProfileScreen.swift
struct ProfileScreen: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Заголовок профиля
                    ProfileHeader(user: viewModel.user)
                    
                    // Статистика
                    StatisticsSection(stats: viewModel.stats)
                    
                    // Быстрые действия
                    QuickActionsSection()
                    
                    // История
                    HistorySection(history: viewModel.history)
                    
                    // Настройки
                    SettingsSection()
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Профиль")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Настройки") {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

// ProfileHeader.swift
struct ProfileHeader: View {
    let user: UserProfile?
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Аватар
            AsyncImage(url: URL(string: user?.photoURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(AppColors.primary, lineWidth: 3)
            )
            
            // Имя и email
            VStack(spacing: AppSpacing.xs) {
                Text(user?.displayName ?? "Гость")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.text)
                
                Text(user?.email ?? "")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Кнопка входа/выхода
            if let user = user {
                AppButton(title: "Выйти", style: .outline) {
                    // Выход из аккаунта
                }
            } else {
                AppButton(title: "Войти", style: .primary) {
                    // Вход в аккаунт
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
    }
}
```

### 🎮 Этап 5: Геймификация (1-2 недели)

#### 5.1 Экран достижений
```swift
// GamificationScreen.swift
struct GamificationScreen: View {
    @StateObject private var viewModel = GamificationViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Прогресс пользователя
                    UserProgressCard(progress: viewModel.userProgress)
                    
                    // Достижения
                    AchievementsSection(achievements: viewModel.achievements)
                    
                    // Бейджи
                    BadgesSection(badges: viewModel.badges)
                    
                    // Рейтинг
                    LeaderboardSection(leaderboard: viewModel.leaderboard)
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Достижения")
        }
    }
}

// UserProgressCard.swift
struct UserProgressCard: View {
    let progress: UserProgress
    
    var body: some View {
        AppCard {
            VStack(spacing: AppSpacing.md) {
                // Уровень и опыт
                HStack {
                    VStack(alignment: .leading) {
                        Text("Уровень \(progress.level)")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.text)
                        
                        Text("\(progress.currentXP) / \(progress.nextLevelXP) XP")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    CircularProgressView(
                        progress: Double(progress.currentXP) / Double(progress.nextLevelXP),
                        size: 60
                    )
                }
                
                // Прогресс-бар
                ProgressView(value: Double(progress.currentXP), total: Double(progress.nextLevelXP))
                    .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                
                // Статистика
                HStack {
                    StatItem(title: "Посещено", value: "\(progress.visitedPOIs)")
                    StatItem(title: "Маршрутов", value: "\(progress.completedRoutes)")
                    StatItem(title: "Отзывов", value: "\(progress.reviews)")
                }
            }
        }
    }
}

// CircularProgressView.swift
struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.textSecondary.opacity(0.2), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
        }
        .frame(width: size, height: size)
    }
}
```

---

## 📱 АДАПТИВНОСТЬ И ОТЗЫВЧИВОСТЬ

### 🎯 Принципы адаптивного дизайна

#### 1. Size Classes
```swift
// Определение размера устройства
@Environment(\.horizontalSizeClass) var horizontalSizeClass
@Environment(\.verticalSizeClass) var verticalSizeClass

// Использование в коде
if horizontalSizeClass == .compact {
    // iPhone в Portrait
    VStack { /* контент */ }
} else {
    // iPad или iPhone в Landscape
    HStack { /* контент */ }
}
```

#### 2. Адаптивные отступы
```swift
// AdaptivePadding.swift
struct AdaptivePadding: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.xl)
            .padding(.vertical, horizontalSizeClass == .compact ? AppSpacing.sm : AppSpacing.md)
    }
}

extension View {
    func adaptivePadding() -> some View {
        modifier(AdaptivePadding())
    }
}
```

#### 3. Адаптивная типографика
```swift
// AdaptiveTypography.swift
struct AdaptiveTypography {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    static func titleFont() -> Font {
        let baseSize: CGFloat = horizontalSizeClass == .compact ? 24 : 28
        return .system(size: baseSize, weight: .bold, design: .default)
    }
    
    static func bodyFont() -> Font {
        let baseSize: CGFloat = horizontalSizeClass == .compact ? 16 : 18
        return .system(size: baseSize, weight: .regular, design: .default)
    }
}
```

### 📱 Примеры адаптивных экранов

#### 1. Адаптивный список
```swift
// AdaptiveList.swift
struct AdaptiveList<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .compact {
            // iPhone Portrait - вертикальный список
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(data) { item in
                    content(item)
                }
            }
        } else {
            // iPad или iPhone Landscape - сетка
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                spacing: AppSpacing.md
            ) {
                ForEach(data) { item in
                    content(item)
                }
            }
        }
    }
}
```

#### 2. Адаптивная навигация
```swift
// AdaptiveNavigation.swift
struct AdaptiveNavigation<Content: View>: View {
    let content: Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if horizontalSizeClass == .compact {
            // iPhone - стандартная навигация
            NavigationView {
                content
            }
        } else {
            // iPad - Split View
            NavigationSplitView {
                SidebarView()
            } detail: {
                content
            }
        }
    }
}
```

#### 3. Адаптивные карточки
```swift
// AdaptiveCard.swift
struct AdaptiveCard<Content: View>: View {
    let content: Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.lg)
            .background(AppColors.surface)
            .cornerRadius(horizontalSizeClass == .compact ? AppCornerRadius.medium : AppCornerRadius.large)
            .shadow(
                color: .black.opacity(0.1),
                radius: horizontalSizeClass == .compact ? 2 : 4,
                x: 0,
                y: horizontalSizeClass == .compact ? 1 : 2
            )
    }
}
```

### 🔄 Ориентация экрана

#### 1. Поддержка Landscape
```swift
// OrientationAwareView.swift
struct OrientationAwareView<Content: View>: View {
    let content: Content
    @State private var orientation = UIDeviceOrientation.portrait
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if orientation.isPortrait {
                // Portrait layout
                VStack {
                    content
                }
            } else {
                // Landscape layout
                HStack {
                    content
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = UIDevice.current.orientation
        }
    }
}
```

#### 2. Адаптивные изображения
```swift
// AdaptiveImage.swift
struct AdaptiveImage: View {
    let imageName: String
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: horizontalSizeClass == .compact ? .fill : .fit)
            .frame(
                maxWidth: horizontalSizeClass == .compact ? .infinity : 400,
                maxHeight: horizontalSizeClass == .compact ? 200 : 300
            )
            .clipped()
            .cornerRadius(AppCornerRadius.medium)
    }
}
```

### 🎨 ДИЗАЙН-СИСТЕМА

### 🎨 Цветовая палитра
```swift
// Основные цвета (брендинг Саранска)
extension Color {
    static let saranskRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    static let saranskGold = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let saranskBlue = Color(red: 0.1, green: 0.4, blue: 0.8)
    static let saranskGreen = Color(red: 0.2, green: 0.6, blue: 0.3)
}

// Семантические цвета
extension Color {
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
}
```

### 📝 Типографика
```swift
// Система типографики
extension Font {
    static func appFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .default)
    }
    
    static let appLargeTitle = appFont(size: 34, weight: .bold)
    static let appTitle1 = appFont(size: 28, weight: .bold)
    static let appTitle2 = appFont(size: 22, weight: .semibold)
    static let appTitle3 = appFont(size: 20, weight: .semibold)
    static let appHeadline = appFont(size: 17, weight: .semibold)
    static let appBody = appFont(size: 17, weight: .regular)
    static let appCallout = appFont(size: 16, weight: .regular)
    static let appSubheadline = appFont(size: 15, weight: .regular)
    static let appFootnote = appFont(size: 13, weight: .regular)
    static let appCaption1 = appFont(size: 12, weight: .regular)
    static let appCaption2 = appFont(size: 11, weight: .regular)
}
```

---

## 🔧 ИНСТРУМЕНТЫ И РЕСУРСЫ

### 🛠️ Инструменты для разработки
- **Xcode** — основная IDE
- **Sketch/Figma** — дизайн-макеты
- **SF Symbols** — системные иконки
- **Lottie** — анимации
- **SwiftGen** — генерация ресурсов

### 📱 Тестирование UI
- **Simulator** — тестирование на разных устройствах
- **Preview** — SwiftUI превью
- **Accessibility Inspector** — тестирование доступности
- **Dark Mode** — тестирование темной темы

### 📱 Тестирование адаптивности
- **Разные устройства** — iPhone SE, iPhone 15 Pro Max, iPad
- **Ориентации** — Portrait и Landscape
- **Size Classes** — Compact и Regular
- **Dynamic Type** — разные размеры шрифтов
- **Safe Areas** — учет безопасных зон

### 🎨 Ресурсы
- **SF Symbols** — системные иконки Apple
- **Human Interface Guidelines** — гайдлайны Apple
- **Material Design** — принципы дизайна
- **iOS Design Patterns** — паттерны iOS

---

## 📋 ЧЕКЛИСТ РАЗРАБОТКИ UI

### ✅ Этап 1: Дизайн-система
- [ ] Цветовая палитра определена
- [ ] Типографика настроена
- [ ] Базовые компоненты созданы
- [ ] Спасинг и отступы определены
- [ ] Иконки подобраны

### ✅ Этап 2: Карта и навигация
- [ ] Основная карта реализована
- [ ] Маркеры POI настроены
- [ ] Поисковая панель создана
- [ ] Фильтры работают
- [ ] Навигация к POI работает

### ✅ Этап 3: Каталог POI
- [ ] Список POI создан
- [ ] Карточки POI реализованы
- [ ] Детальный экран POI готов
- [ ] Поиск и фильтрация работают
- [ ] Отзывы и рейтинги отображаются

### ✅ Этап 4: Профиль пользователя
- [ ] Экран профиля создан
- [ ] Аутентификация работает
- [ ] Статистика отображается
- [ ] Настройки доступны
- [ ] История посещений показывается

### ✅ Этап 5: Геймификация
- [ ] Система достижений реализована
- [ ] Бейджи отображаются
- [ ] Прогресс пользователя показывается
- [ ] Рейтинг работает
- [ ] Анимации достижений готовы

### ✅ Финальная проверка
- [ ] Все экраны адаптивны
- [ ] Темная тема работает
- [ ] Доступность настроена
- [ ] Производительность оптимизирована
- [ ] Анимации плавные

### ✅ Проверка адаптивности
- [ ] iPhone SE (3rd gen) (375×667) — Portrait и Landscape (667×375)
- [ ] iPhone 15 Pro Max (430×932) — Portrait и Landscape (932×430)
- [ ] iPad (10th gen) (820×1180) — Portrait и Landscape (1180×820)
- [ ] iPad Pro 12.9" (1024×1366) — Portrait и Landscape (1366×1024)
- [ ] Dynamic Type — все размеры шрифтов
- [ ] Safe Areas — учет безопасных зон
- [ ] Size Classes — Compact и Regular
- [ ] Split View на iPad
- [ ] Slide Over на iPad

---

## 🚀 ЗАКЛЮЧЕНИЕ

Данное руководство описывает пошаговый подход к разработке UI для приложения "Саранск для Туристов". Ключевые принципы:

1. **Модульность** — создание переиспользуемых компонентов
2. **Консистентность** — единый стиль во всем приложении
3. **Производительность** — плавная работа и быстрая отзывчивость
4. **Доступность** — поддержка всех пользователей
5. **Адаптивность** — работа на всех устройствах

Следуя этому руководству, можно создать качественный и современный UI для iOS приложения, который будет удобен пользователям и соответствует стандартам Apple.

---

**Версия документа:** 1.0  
**Дата создания:** 30 августа 2025  
**Статус:** Утверждено  
**Ответственный:** UI/UX команда