import SwiftUI
import PhotosUI
import AVFoundation

struct ContentManagementScreen: View {
    @StateObject private var viewModel = ContentManagementViewModel()
    @State private var showingAddPOI = false
    @State private var showingImagePicker = false
    @State private var showingAudioPicker = false
    @State private var selectedPOI: POI?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            AdaptiveLayout {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Статистика контента
                        ContentStatsSection(stats: viewModel.contentStats)
                        
                        // Список POI
                        POIListSection(
                            pois: viewModel.pois,
                            onEdit: { poi in
                                selectedPOI = poi
                                showingAddPOI = true
                            },
                            onDelete: { poiId in
                                viewModel.deletePOI(poiId)
                            }
                        )
                        
                        // Загрузка контента
                        ContentUploadSection(
                            isUploading: viewModel.isUploading,
                            uploadProgress: viewModel.uploadProgress,
                            onUpload: {
                                showingAddPOI = true
                            }
                        )
                    }
                    .padding(horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.lg)
                }
            }
            .navigationTitle("Управление контентом")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить POI") {
                        showingAddPOI = true
                    }
                }
            }
            .sheet(isPresented: $showingAddPOI) {
                AddPOIScreen(
                    poi: selectedPOI,
                    onSave: { poi in
                        viewModel.savePOI(poi)
                        selectedPOI = nil
                    }
                )
            }
        }
    }
}

// MARK: - ContentStatsSection
struct ContentStatsSection: View {
    let stats: ContentStats
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Статистика контента")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                ResponsiveGrid(data: [
                    StatItem(title: "Всего POI", value: "\(stats.totalPOIs)"),
                    StatItem(title: "С аудио", value: "\(stats.poisWithAudio)"),
                    StatItem(title: "С изображениями", value: "\(stats.poisWithImages)"),
                    StatItem(title: "Версия", value: stats.contentVersion)
                ], columns: 2) { stat in
                    stat
                }
            }
        }
    }
}

// MARK: - POIListSection
struct POIListSection: View {
    let pois: [POI]
    let onEdit: (POI) -> Void
    let onDelete: (String) -> Void
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Достопримечательности")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(pois) { poi in
                        POIListItem(
                            poi: poi,
                            onEdit: { onEdit(poi) },
                            onDelete: { onDelete(poi.id) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - POIListItem
struct POIListItem: View {
    let poi: POI
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
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
            .frame(width: 60, height: 60)
            .cornerRadius(AppCornerRadius.small)
            
            // Информация
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(poi.name)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.text)
                    .lineLimit(1)
                
                Text(poi.category)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
                
                HStack(spacing: AppSpacing.sm) {
                    if !poi.imageUrl.isEmpty {
                        Image(systemName: "photo")
                            .foregroundColor(AppColors.success)
                            .font(.caption)
                    }
                    
                    if !poi.audioUrl.isEmpty {
                        Image(systemName: "headphones")
                            .foregroundColor(AppColors.primary)
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
            
            // Действия
            HStack(spacing: AppSpacing.sm) {
                Button("Редактировать") {
                    onEdit()
                }
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.primary)
                
                Button("Удалить") {
                    onDelete()
                }
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.error)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - ContentUploadSection
struct ContentUploadSection: View {
    let isUploading: Bool
    let uploadProgress: [String: Double]
    let onUpload: () -> Void
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Загрузка контента")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                if isUploading {
                    VStack(spacing: AppSpacing.sm) {
                        Text("Загрузка файлов...")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        
                        ForEach(Array(uploadProgress.keys), id: \.self) { key in
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(key)
                                    .font(AppTypography.caption1)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                ProgressView(value: uploadProgress[key] ?? 0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                            }
                        }
                    }
                } else {
                    AppButton(title: "Добавить новый POI", style: .primary) {
                        onUpload()
                    }
                }
            }
        }
    }
}

// MARK: - AddPOIScreen
struct AddPOIScreen: View {
    let poi: POI?
    let onSave: (POI) -> Void
    
    @StateObject private var viewModel = AddPOIViewModel()
    @State private var showingImagePicker = false
    @State private var showingAudioPicker = false
    @State private var showingDocumentPicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            AdaptiveLayout {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Основная информация
                        BasicInfoSection(viewModel: viewModel)
                        
                        // Изображения
                        ImagesSection(
                            images: viewModel.selectedImages,
                            onAddImage: { showingImagePicker = true },
                            onRemoveImage: { index in
                                viewModel.removeImage(at: index)
                            }
                        )
                        
                        // Аудио
                        AudioSection(
                            audioURL: viewModel.selectedAudioURL,
                            onAddAudio: { showingAudioPicker = true },
                            onRemoveAudio: { viewModel.removeAudio() }
                        )
                        
                        // Валидация
                        if !viewModel.validationErrors.isEmpty {
                            ValidationErrorsSection(errors: viewModel.validationErrors)
                        }
                        
                        // Кнопки действий
                        ActionButtonsSection(
                            isValid: viewModel.isValid,
                            isUploading: viewModel.isUploading,
                            onSave: {
                                Task {
                                    await viewModel.savePOI { poi in
                                        onSave(poi)
                                        dismiss()
                                    }
                                }
                            }
                        )
                    }
                    .padding(horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.lg)
                }
            }
            .navigationTitle(poi == nil ? "Новый POI" : "Редактировать POI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(images: $viewModel.selectedImages)
            }
            .sheet(isPresented: $showingAudioPicker) {
                AudioPicker(audioURL: $viewModel.selectedAudioURL)
            }
            .onAppear {
                if let poi = poi {
                    viewModel.loadPOI(poi)
                }
            }
        }
    }
}

// MARK: - BasicInfoSection
struct BasicInfoSection: View {
    @ObservedObject var viewModel: AddPOIViewModel
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Основная информация")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                VStack(spacing: AppSpacing.md) {
                    AppTextField(
                        placeholder: "Название достопримечательности",
                        text: $viewModel.name,
                        icon: "mappin.circle"
                    )
                    
                    AppTextField(
                        placeholder: "Описание",
                        text: $viewModel.description,
                        icon: "text.quote"
                    )
                    
                    AppTextField(
                        placeholder: "Адрес",
                        text: $viewModel.address,
                        icon: "location"
                    )
                    
                    Picker("Категория", selection: $viewModel.category) {
                        ForEach(POICategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.medium)
                    
                    HStack {
                        AppTextField(
                            placeholder: "Широта",
                            text: $viewModel.latitude,
                            icon: "location.north"
                        )
                        
                        AppTextField(
                            placeholder: "Долгота",
                            text: $viewModel.longitude,
                            icon: "location.north"
                        )
                    }
                }
            }
        }
    }
}

// MARK: - ImagesSection
struct ImagesSection: View {
    let images: [UIImage]
    let onAddImage: () -> Void
    let onRemoveImage: (Int) -> Void
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Изображения")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                if images.isEmpty {
                    Button("Добавить изображение") {
                        onAddImage()
                    }
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.lg)
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.medium)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.md) {
                            ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                                VStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(AppCornerRadius.medium)
                                    
                                    Button("Удалить") {
                                        onRemoveImage(index)
                                    }
                                    .font(AppTypography.caption1)
                                    .foregroundColor(AppColors.error)
                                }
                            }
                            
                            Button("Добавить") {
                                onAddImage()
                            }
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.primary)
                            .frame(width: 100, height: 100)
                            .background(AppColors.surface)
                            .cornerRadius(AppCornerRadius.medium)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - AudioSection
struct AudioSection: View {
    let audioURL: URL?
    let onAddAudio: () -> Void
    let onRemoveAudio: () -> Void
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Аудиогид")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.text)
                
                if let audioURL = audioURL {
                    VStack(spacing: AppSpacing.sm) {
                        HStack {
                            Image(systemName: "headphones")
                                .foregroundColor(AppColors.primary)
                            
                            Text(audioURL.lastPathComponent)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.text)
                            
                            Spacer()
                            
                            Button("Удалить") {
                                onRemoveAudio()
                            }
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.error)
                        }
                        
                        // Аудиоплеер для предпрослушивания
                        AudioPreviewPlayer(audioURL: audioURL)
                    }
                } else {
                    Button("Добавить аудиофайл") {
                        onAddAudio()
                    }
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.lg)
                    .background(AppColors.surface)
                    .cornerRadius(AppCornerRadius.medium)
                }
            }
        }
    }
}

// MARK: - AudioPreviewPlayer
struct AudioPreviewPlayer: View {
    let audioURL: URL
    @StateObject private var audioPlayer = AudioPlayerService.shared
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Button(action: {
                if audioPlayer.isPlaying {
                    audioPlayer.pause()
                } else {
                    audioPlayer.loadAudio(from: audioURL, title: "Предпросмотр", poiId: nil)
                    audioPlayer.play()
                }
            }) {
                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Предпросмотр")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
                
                ProgressView(value: audioPlayer.currentTime, total: audioPlayer.duration)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.small)
    }
}

// MARK: - ValidationErrorsSection
struct ValidationErrorsSection: View {
    let errors: [String]
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Ошибки валидации")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.error)
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(errors, id: \.self) { error in
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(AppColors.error)
                            
                            Text(error)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.text)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ActionButtonsSection
struct ActionButtonsSection: View {
    let isValid: Bool
    let isUploading: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            AppButton(
                title: isUploading ? "Загрузка..." : "Сохранить POI",
                style: .primary
            ) {
                onSave()
            }
            .disabled(!isValid || isUploading)
            
            if isUploading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
            }
        }
    }
}

// MARK: - ContentManagementViewModel
class ContentManagementViewModel: ObservableObject {
    @Published var pois: [POI] = []
    @Published var contentStats = ContentStats()
    @Published var isUploading = false
    @Published var uploadProgress: [String: Double] = [:]
    
    private let contentService = ContentManagementService.shared
    
    init() {
        loadPOIs()
        updateStats()
    }
    
    func loadPOIs() {
        Task {
            do {
                let fetchedPOIs = try await FirestoreService.shared.fetchPOIList()
                await MainActor.run {
                    self.pois = fetchedPOIs
                    self.updateStats()
                }
            } catch {
                print("Failed to load POIs: \(error)")
            }
        }
    }
    
    func savePOI(_ poi: POI) {
        Task {
            do {
                try await contentService.addPOI(poi)
                await MainActor.run {
                    self.loadPOIs()
                }
            } catch {
                print("Failed to save POI: \(error)")
            }
        }
    }
    
    func deletePOI(_ poiId: String) {
        Task {
            do {
                try await contentService.deletePOI(poiId)
                await MainActor.run {
                    self.loadPOIs()
                }
            } catch {
                print("Failed to delete POI: \(error)")
            }
        }
    }
    
    private func updateStats() {
        contentStats = ContentStats(
            totalPOIs: pois.count,
            poisWithAudio: pois.filter { !$0.audioUrl.isEmpty }.count,
            poisWithImages: pois.filter { !$0.imageUrl.isEmpty }.count,
            contentVersion: contentService.contentVersion
        )
    }
}

// MARK: - AddPOIViewModel
class AddPOIViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var address = ""
    @Published var category = POICategory.museums.rawValue
    @Published var latitude = ""
    @Published var longitude = ""
    @Published var selectedImages: [UIImage] = []
    @Published var selectedAudioURL: URL?
    @Published var validationErrors: [String] = []
    @Published var isUploading = false
    
    private let contentService = ContentManagementService.shared
    
    var isValid: Bool {
        !name.isEmpty && !description.isEmpty && !address.isEmpty && !category.isEmpty
    }
    
    func loadPOI(_ poi: POI) {
        name = poi.name
        description = poi.description
        address = poi.address
        category = poi.category
        latitude = String(poi.latitude)
        longitude = String(poi.longitude)
    }
    
    func removeImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    func removeAudio() {
        selectedAudioURL = nil
    }
    
    func savePOI(completion: @escaping (POI) -> Void) async {
        isUploading = true
        validationErrors.removeAll()
        
        // Валидация
        let poi = POI(
            id: UUID().uuidString,
            name: name,
            description: description,
            address: address,
            category: category,
            imageUrl: "",
            latitude: Double(latitude) ?? 0,
            longitude: Double(longitude) ?? 0,
            rating: 0,
            distance: 0,
            popularity: 0,
            workingHours: nil,
            price: nil,
            phone: nil,
            website: nil,
            tags: [],
            isFavorite: false
        )
        
        validationErrors = contentService.validatePOIContent(poi)
        
        if !validationErrors.isEmpty {
            isUploading = false
            return
        }
        
        // Валидация файлов
        for image in selectedImages {
            if let imageData = image.jpegData(compressionQuality: 0.8),
               let tempURL = saveImageToTemp(imageData) {
                let errors = contentService.validateImageFile(tempURL)
                validationErrors.append(contentsOf: errors)
            }
        }
        
        if let audioURL = selectedAudioURL {
            let errors = contentService.validateAudioFile(audioURL)
            validationErrors.append(contentsOf: errors)
        }
        
        if !validationErrors.isEmpty {
            isUploading = false
            return
        }
        
        // Загрузка файлов
        do {
            var imageURLs: [URL] = []
            for image in selectedImages {
                if let imageData = image.jpegData(compressionQuality: 0.8),
                   let tempURL = saveImageToTemp(imageData) {
                    imageURLs.append(tempURL)
                }
            }
            
            try await contentService.uploadPOIContent(poi, images: imageURLs, audioURL: selectedAudioURL)
            
            await MainActor.run {
                self.isUploading = false
                completion(poi)
            }
            
        } catch {
            await MainActor.run {
                self.isUploading = false
                self.validationErrors.append(error.localizedDescription)
            }
        }
    }
    
    private func saveImageToTemp(_ imageData: Data) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        do {
            try imageData.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
}

// MARK: - ContentStats
struct ContentStats {
    let totalPOIs: Int
    let poisWithAudio: Int
    let poisWithImages: Int
    let contentVersion: String
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 5
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.images.append(image)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - AudioPicker
struct AudioPicker: UIViewControllerRepresentable {
    @Binding var audioURL: URL?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: AudioPicker
        
        init(_ parent: AudioPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.audioURL = url
            }
        }
    }
}

#Preview {
    ContentManagementScreen()
}