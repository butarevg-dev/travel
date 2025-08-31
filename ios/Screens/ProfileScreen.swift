import SwiftUI

struct ProfileScreen: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    @State private var showingAchievements = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationView {
            AdaptiveLayout {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Профиль пользователя
                        ProfileHeader(user: viewModel.user)
                        
                        // Статистика
                        StatisticsSection(stats: viewModel.statistics)
                        
                        // Достижения
                        AchievementsSection(achievements: viewModel.achievements) {
                            showingAchievements = true
                        }
                        
                        // Избранное
                        FavoritesSection(favorites: viewModel.favorites)
                        
                        // Настройки
                        SettingsSection {
                            showingSettings = true
                        }
                    }
                    .padding(horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.lg)
                }
            }
            .navigationTitle("Профиль")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementsView(achievements: viewModel.achievements)
            }
        }
    }
}

// MARK: - ProfileHeader
struct ProfileHeader: View {
    let user: UserProfile?
    
    var body: some View {
        AppCard {
            VStack(spacing: AppSpacing.md) {
                // Аватар
                AsyncImage(url: URL(string: user?.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppColors.primary, lineWidth: 3)
                )
                
                // Имя и уровень
                VStack(spacing: AppSpacing.xs) {
                    Text(user?.name ?? "Гость")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.text)
                    
                    HStack(spacing: AppSpacing.sm) {
                        Text("Уровень \(user?.level ?? 1)")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.primary)
                        
                        CircularProgressView(
                            progress: Double(user?.experience ?? 0) / Double(user?.experienceToNextLevel ?? 100),
                            size: 20
                        )
                    }
                }
                
                // Опыт
                VStack(spacing: AppSpacing.xs) {
                    HStack {
                        Text("Опыт")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text("\(user?.experience ?? 0) / \(user?.experienceToNextLevel ?? 100)")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    ProgressView(value: Double(user?.experience ?? 0), total: Double(user?.experienceToNextLevel ?? 100))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                }
            }
        }
    }
}

// MARK: - StatisticsSection
struct StatisticsSection: View {
    let stats: UserStatistics
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Статистика")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                ResponsiveGrid(data: [
                    StatItem(title: "Посещено мест", value: "\(stats.visitedPlaces)"),
                    StatItem(title: "Пройдено маршрутов", value: "\(stats.completedRoutes)"),
                    StatItem(title: "Оставлено отзывов", value: "\(stats.reviewsCount)"),
                    StatItem(title: "Общее время", value: "\(stats.totalTime)ч")
                ], columns: 2) { stat in
                    stat
                }
            }
        }
    }
}

// MARK: - AchievementsSection
struct AchievementsSection: View {
    let achievements: [Achievement]
    let onTap: () -> Void
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Text("Достижения")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    Button("Все") {
                        onTap()
                    }
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.primary)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(achievements.prefix(5)) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - AchievementCard
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundColor(achievement.isUnlocked ? AppColors.primary : AppColors.textSecondary)
            
            Text(achievement.title)
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80, height: 80)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
        .opacity(achievement.isUnlocked ? 1.0 : 0.5)
    }
}

// MARK: - FavoritesSection
struct FavoritesSection: View {
    let favorites: [POI]
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Избранное")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                if favorites.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "heart")
                            .font(.title)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Нет избранных мест")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.lg)
                } else {
                    ForEach(favorites.prefix(3)) { poi in
                        HStack {
                            AsyncImage(url: URL(string: poi.imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(AppColors.surface)
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(AppCornerRadius.small)
                            
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(poi.name)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.text)
                                    .lineLimit(1)
                                
                                Text(poi.address)
                                    .font(AppTypography.caption1)
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SettingsSection
struct SettingsSection: View {
    let onTap: () -> Void
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Настройки")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                VStack(spacing: AppSpacing.sm) {
                    SettingsRow(
                        icon: "gear",
                        title: "Общие настройки",
                        action: onTap
                    )
                    
                    SettingsRow(
                        icon: "bell",
                        title: "Уведомления",
                        action: onTap
                    )
                    
                    SettingsRow(
                        icon: "map",
                        title: "Карта",
                        action: onTap
                    )
                    
                    SettingsRow(
                        icon: "questionmark.circle",
                        title: "Помощь",
                        action: onTap
                    )
                }
            }
        }
    }
}

// MARK: - SettingsRow
struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.caption)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.small)
        }
    }
}

// MARK: - ProfileViewModel
class ProfileViewModel: ObservableObject {
    @Published var user: UserProfile?
    @Published var statistics = UserStatistics()
    @Published var achievements: [Achievement] = []
    @Published var favorites: [POI] = []
    
    init() {
        loadUserData()
        loadStatistics()
        loadAchievements()
        loadFavorites()
    }
    
    private func loadUserData() {
        // Загрузка данных пользователя
        user = UserProfile(
            id: "1",
            name: "Александр",
            email: "alex@example.com",
            avatarUrl: "",
            level: 5,
            experience: 750,
            experienceToNextLevel: 1000
        )
    }
    
    private func loadStatistics() {
        statistics = UserStatistics(
            visitedPlaces: 12,
            completedRoutes: 3,
            reviewsCount: 8,
            totalTime: 24
        )
    }
    
    private func loadAchievements() {
        achievements = [
            Achievement(id: "1", title: "Первые шаги", icon: "figure.walk", isUnlocked: true),
            Achievement(id: "2", title: "Исследователь", icon: "map", isUnlocked: true),
            Achievement(id: "3", title: "Фотограф", icon: "camera", isUnlocked: false),
            Achievement(id: "4", title: "Критик", icon: "star", isUnlocked: true),
            Achievement(id: "5", title: "Путешественник", icon: "airplane", isUnlocked: false)
        ]
    }
    
    private func loadFavorites() {
        // Загрузка избранных мест
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @State private var darkModeEnabled = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Уведомления") {
                    Toggle("Push-уведомления", isOn: $notificationsEnabled)
                    Toggle("Уведомления о новых местах", isOn: $notificationsEnabled)
                    Toggle("Еженедельная статистика", isOn: $notificationsEnabled)
                }
                
                Section("Местоположение") {
                    Toggle("Разрешить доступ к местоположению", isOn: $locationEnabled)
                    Toggle("Фоновая геолокация", isOn: $locationEnabled)
                }
                
                Section("Внешний вид") {
                    Toggle("Темная тема", isOn: $darkModeEnabled)
                }
                
                Section("Данные") {
                    Button("Очистить кэш") {
                        // Очистка кэша
                    }
                    .foregroundColor(AppColors.error)
                    
                    Button("Экспорт данных") {
                        // Экспорт данных
                    }
                    .foregroundColor(AppColors.primary)
                }
                
                Section("О приложении") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - AchievementsView
struct AchievementsView: View {
    let achievements: [Achievement]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppSpacing.md) {
                    ForEach(achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Достижения")
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

// MARK: - Models
struct UserProfile {
    let id: String
    let name: String
    let email: String
    let avatarUrl: String
    let level: Int
    let experience: Int
    let experienceToNextLevel: Int
}

struct UserStatistics {
    let visitedPlaces: Int
    let completedRoutes: Int
    let reviewsCount: Int
    let totalTime: Int
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let icon: String
    let isUnlocked: Bool
}

#Preview {
    ProfileScreen()
}