import SwiftUI

// MARK: - Colors
struct AppColors {
    // Основные цвета (брендинг Саранска)
    static let saranskRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    static let saranskGold = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let saranskBlue = Color(red: 0.1, green: 0.4, blue: 0.8)
    static let saranskGreen = Color(red: 0.2, green: 0.6, blue: 0.3)
    
    // Семантические цвета
    static let primary = saranskRed
    static let secondary = saranskBlue
    static let accent = saranskGold
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let text = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let error = Color.red
    static let success = Color.green
    static let warning = Color.orange
    static let info = Color.blue
}

// MARK: - Typography
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

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct AppCornerRadius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
    static let xlarge: CGFloat = 16
    static let round: CGFloat = 25
}

// MARK: - Base Components

// MARK: - AppButton
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

// MARK: - AppTextField
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

// MARK: - AppCard
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

// MARK: - AdaptiveLayout
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

// MARK: - ResponsiveGrid
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

// MARK: - SafeAreaView
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

// MARK: - AdaptivePadding
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

// MARK: - CircularProgressView
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

// MARK: - CategoryChip
struct CategoryChip: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "mappin.circle")
                    .font(.caption)
                
                Text(category)
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

// MARK: - StatItem
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.primary)
            
            Text(title)
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}