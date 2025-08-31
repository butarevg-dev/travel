import SwiftUI

struct GamificationScreen: View {
    @StateObject private var gamificationService = GamificationService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with game stats
                GameStatsHeader()
                
                // Tab selector
                Picker("Раздел", selection: $selectedTab) {
                    Text("Значки").tag(0)
                    Text("Квесты").tag(1)
                    Text("Достижения").tag(2)
                    Text("Рейтинг").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Tab content
                TabView(selection: $selectedTab) {
                    BadgesTab()
                        .tag(0)
                    
                    QuestsTab()
                        .tag(1)
                    
                    AchievementsTab()
                        .tag(2)
                    
                    LeaderboardsTab()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Геймификация")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshData()
            }
        }
    }
    
    private func refreshData() async {
        gamificationService.loadBadges()
        gamificationService.loadQuests()
        gamificationService.loadAchievements()
        gamificationService.loadLeaderboards()
    }
}

// MARK: - Game Stats Header
struct GameStatsHeader: View {
    @StateObject private var gamificationService = GamificationService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            if let gameState = gamificationService.gameState {
                // Level and experience
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Уровень \(gameState.level)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(gameState.experience) / \(gameState.experienceToNextLevel) XP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(gameState.coins)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        Text("Монеты")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress bar
                ProgressView(value: gameState.levelProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                // Quick stats
                HStack(spacing: 20) {
                    StatItem(title: "Значки", value: "\(gameState.badges.count)")
                    StatItem(title: "Квесты", value: "\(gameState.activeQuests.count)")
                    StatItem(title: "Достижения", value: "\(gameState.achievements.count)")
                }
            } else {
                ProgressView("Загрузка...")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Badges Tab
struct BadgesTab: View {
    @StateObject private var gamificationService = GamificationService.shared
    @State private var selectedCategory: BadgeCategory? = nil
    
    var filteredBadges: [Badge] {
        if let category = selectedCategory {
            return gamificationService.badges.filter { $0.category == category }
        }
        return gamificationService.badges
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryChip(title: "Все", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    
                    ForEach(BadgeCategory.allCases, id: \.self) { category in
                        CategoryChip(title: category.localizedName, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Badges grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(filteredBadges) { badge in
                        BadgeCard(badge: badge)
                    }
                }
                .padding()
            }
        }
    }
}

struct BadgeCard: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 12) {
            // Badge icon
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? Color.accentColor : Color(.systemGray5))
                    .frame(width: 60, height: 60)
                
                Image(systemName: badge.iconName)
                    .font(.title2)
                    .foregroundColor(badge.isUnlocked ? .white : .secondary)
            }
            
            // Badge info
            VStack(spacing: 4) {
                Text(badge.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(badge.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Progress
                if let progress = badge.progress, !badge.isUnlocked {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    
                    Text("\(badge.progressPercentage)%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Rarity indicator
                HStack {
                    Circle()
                        .fill(rarityColor)
                        .frame(width: 8, height: 8)
                    
                    Text(badge.rarity.localizedName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .opacity(badge.isUnlocked ? 1.0 : 0.7)
    }
    
    private var rarityColor: Color {
        switch badge.rarity {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Quests Tab
struct QuestsTab: View {
    @StateObject private var gamificationService = GamificationService.shared
    @State private var selectedCategory: QuestCategory? = nil
    
    var filteredQuests: [Quest] {
        var quests = gamificationService.quests
        if let category = selectedCategory {
            quests = quests.filter { $0.category == category }
        }
        return quests.sorted { $0.isActive && !$1.isActive }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryChip(title: "Все", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    
                    ForEach(QuestCategory.allCases, id: \.self) { category in
                        CategoryChip(title: category.localizedName, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Quests list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredQuests) { quest in
                        QuestCard(quest: quest)
                    }
                }
                .padding()
            }
        }
    }
}

struct QuestCard: View {
    let quest: Quest
    @StateObject private var gamificationService = GamificationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.headline)
                    
                    Text(quest.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Difficulty indicator
                VStack {
                    Text(quest.difficulty.localizedName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(difficultyColor.opacity(0.2))
                        .foregroundColor(difficultyColor)
                        .cornerRadius(8)
                    
                    Text("\(quest.difficulty.experienceReward) XP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Прогресс")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(quest.progress.current)/\(quest.progress.target)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: quest.progress.percentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
            }
            
            // Rewards
            if !quest.rewards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Награды")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(quest.rewards, id: \.description) { reward in
                            RewardChip(reward: reward)
                        }
                    }
                }
            }
            
            // Action button
            if !quest.isStarted {
                Button("Начать квест") {
                    Task {
                        await gamificationService.startQuest(quest.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!quest.isActive)
            } else if quest.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Завершен")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var difficultyColor: Color {
        switch quest.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        case .expert: return .purple
        }
    }
}

struct RewardChip: View {
    let reward: QuestReward
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: rewardIcon)
                .font(.caption)
            
            Text("\(reward.value)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(rewardColor.opacity(0.2))
        .foregroundColor(rewardColor)
        .cornerRadius(8)
    }
    
    private var rewardIcon: String {
        switch reward.type {
        case .experience: return "star.fill"
        case .coins: return "dollarsign.circle.fill"
        case .badge: return "medal.fill"
        case .premiumDays: return "crown.fill"
        case .specialAccess: return "key.fill"
        case .discount: return "percent"
        }
    }
    
    private var rewardColor: Color {
        switch reward.type {
        case .experience: return .orange
        case .coins: return .yellow
        case .badge: return .blue
        case .premiumDays: return .purple
        case .specialAccess: return .green
        case .discount: return .red
        }
    }
}

// MARK: - Achievements Tab
struct AchievementsTab: View {
    @StateObject private var gamificationService = GamificationService.shared
    @State private var selectedCategory: AchievementCategory? = nil
    
    var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return gamificationService.achievements.filter { $0.category == category }
        }
        return gamificationService.achievements
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryChip(title: "Все", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        CategoryChip(title: category.localizedName, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Achievements list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding()
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.green : Color(.systemGray5))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.isUnlocked ? "checkmark" : "lock")
                    .font(.title3)
                    .foregroundColor(achievement.isUnlocked ? .white : .secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let progress = achievement.progress, !achievement.isUnlocked {
                    ProgressView(value: progress.percentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                }
            }
            
            Spacer()
            
            // Points
            VStack {
                Text("\(achievement.points)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("очков")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Leaderboards Tab
struct LeaderboardsTab: View {
    @StateObject private var gamificationService = GamificationService.shared
    @State private var selectedLeaderboard: Leaderboard?
    
    var body: some View {
        VStack(spacing: 16) {
            // Leaderboards list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(gamificationService.leaderboards) { leaderboard in
                        LeaderboardCard(leaderboard: leaderboard)
                            .onTapGesture {
                                selectedLeaderboard = leaderboard
                            }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $selectedLeaderboard) { leaderboard in
            LeaderboardDetailView(leaderboard: leaderboard)
        }
    }
}

struct LeaderboardCard: View {
    let leaderboard: Leaderboard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(leaderboard.title)
                        .font(.headline)
                    
                    Text(leaderboard.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(leaderboard.timeFrame.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .foregroundColor(.accentColor)
                    .cornerRadius(8)
            }
            
            // Top 3 entries
            VStack(spacing: 8) {
                ForEach(Array(leaderboard.entries.prefix(3).enumerated()), id: \.element.id) { index, entry in
                    HStack {
                        Text("\(entry.rank)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(rankColor(for: entry.rank))
                            .frame(width: 20)
                        
                        Text(entry.username)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(entry.score)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Leaderboard Detail View
struct LeaderboardDetailView: View {
    let leaderboard: Leaderboard
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(leaderboard.entries) { entry in
                    HStack {
                        Text("\(entry.rank)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(rankColor(for: entry.rank))
                            .frame(width: 30)
                        
                        Text(entry.username)
                            .font(.body)
                        
                        Spacer()
                        
                        Text("\(entry.score)")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle(leaderboard.title)
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
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Helper Components
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}