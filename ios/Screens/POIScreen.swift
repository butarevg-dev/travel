import SwiftUI

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

// MARK: - SearchBar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField("Поиск достопримечательностей...", text: $text)
                .font(AppTypography.body)
            
            if !text.isEmpty {
                Button("Очистить") {
                    text = ""
                }
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.primary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.large)
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - FilterBar
struct FilterBar: View {
    @Binding var selectedCategory: String?
    @Binding var selectedSort: SortOption
    
    enum SortOption: String, CaseIterable {
        case name = "По названию"
        case rating = "По рейтингу"
        case distance = "По расстоянию"
        case popularity = "По популярности"
    }
    
    var body: some View {
        HStack {
            // Категории
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    CategoryChip(
                        category: "Все",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(["Музеи", "Храмы", "Парки", "Рестораны"], id: \.self) { category in
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
            
            Spacer()
            
            // Сортировка
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        selectedSort = option
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(AppColors.primary)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.medium)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - POICard
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
                        CategoryChip(
                            category: poi.category,
                            isSelected: false
                        ) {
                            // Ничего не делаем, это просто отображение
                        }
                        
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

// MARK: - POIViewModel
class POIViewModel: ObservableObject {
    @Published var pois: [POI] = []
    @Published var selectedCategory: String?
    @Published var selectedSort: FilterBar.SortOption = .name
    @Published var selectedFilters: [String] = []
    @Published var showingPOIDetail = false
    @Published var selectedPOI: POI?
    
    var filteredPOIs: [POI] {
        var filtered = pois
        
        // Фильтрация по категории
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Фильтрация по дополнительным фильтрам
        for filter in selectedFilters {
            filtered = filtered.filter { poi in
                // Логика фильтрации
                return true
            }
        }
        
        // Сортировка
        switch selectedSort {
        case .name:
            filtered.sort { $0.name < $1.name }
        case .rating:
            filtered.sort { $0.rating > $1.rating }
        case .distance:
            filtered.sort { $0.distance < $1.distance }
        case .popularity:
            filtered.sort { $0.popularity > $1.popularity }
        }
        
        return filtered
    }
    
    func selectPOI(_ poi: POI) {
        selectedPOI = poi
        showingPOIDetail = true
    }
}

// MARK: - POIFilterView
struct POIFilterView: View {
    @Binding var selectedCategory: String?
    @Binding var selectedFilters: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Категории") {
                    ForEach(["Музеи", "Храмы", "Парки", "Рестораны", "Кафе", "Магазины"], id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                
                Section("Дополнительные фильтры") {
                    ForEach(["Бесплатно", "С рейтингом 4+", "Открыто сейчас"], id: \.self) { filter in
                        HStack {
                            Text(filter)
                            Spacer()
                            if selectedFilters.contains(filter) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedFilters.contains(filter) {
                                selectedFilters.removeAll { $0 == filter }
                            } else {
                                selectedFilters.append(filter)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Сбросить") {
                        selectedCategory = nil
                        selectedFilters.removeAll()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - POIDetailView
struct POIDetailView: View {
    let poi: POI
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
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
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(AppCornerRadius.medium)
                    
                    // Информация
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        // Название и рейтинг
                        HStack {
                            Text(poi.name)
                                .font(AppTypography.title1)
                                .foregroundColor(AppColors.text)
                            
                            Spacer()
                            
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                
                                Text(String(format: "%.1f", poi.rating))
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.text)
                            }
                        }
                        
                        // Категория
                        CategoryChip(
                            category: poi.category,
                            isSelected: false
                        ) {
                            // Ничего не делаем
                        }
                        
                        // Описание
                        Text(poi.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                        
                        // Адрес
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(AppColors.textSecondary)
                            Text(poi.address)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.text)
                        }
                        
                        // Часы работы
                        if let workingHours = poi.workingHours {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(AppColors.textSecondary)
                                Text(workingHours)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.text)
                            }
                        }
                        
                        // Цена
                        if let price = poi.price {
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(AppColors.textSecondary)
                                Text(price)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.text)
                            }
                        }
                        
                        // Кнопки действий
                        HStack {
                            AppButton(title: "Навигация", style: .primary) {
                                // Открыть навигацию
                            }
                            
                            AppButton(title: "Поделиться", style: .outline) {
                                // Поделиться POI
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
            .navigationTitle("Детали")
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

#Preview {
    POIScreen()
}