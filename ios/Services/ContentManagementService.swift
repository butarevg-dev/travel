import Foundation
import FirebaseStorage
import FirebaseFirestore
import Combine

class ContentManagementService: ObservableObject {
    static let shared = ContentManagementService()
    
    // MARK: - Published Properties
    @Published var uploadProgress: [String: Double] = [:]
    @Published var isUploading = false
    @Published var uploadError: String?
    @Published var contentVersion: String = "1.0.0"
    
    // MARK: - Private Properties
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private var uploadTasks: [String: StorageUploadTask] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - POI Content Management
    
    /// Добавить новый POI в Firebase
    func addPOI(_ poi: POI) async throws {
        let poiData = try JSONEncoder().encode(poi)
        try await db.collection("poi").document(poi.id).setData([
            "data": poiData,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "version": contentVersion
        ])
    }
    
    /// Обновить существующий POI
    func updatePOI(_ poi: POI) async throws {
        let poiData = try JSONEncoder().encode(poi)
        try await db.collection("poi").document(poi.id).updateData([
            "data": poiData,
            "updatedAt": FieldValue.serverTimestamp(),
            "version": contentVersion
        ])
    }
    
    /// Удалить POI
    func deletePOI(_ poiId: String) async throws {
        // Удалить POI из Firestore
        try await db.collection("poi").document(poiId).delete()
        
        // Удалить связанные файлы из Storage
        try await deletePOIFiles(poiId: poiId)
    }
    
    // MARK: - Audio Guide Management
    
    /// Загрузить аудиофайл для POI
    func uploadAudioGuide(poiId: String, audioURL: URL, title: String) async throws -> String {
        let audioId = "\(poiId)_\(UUID().uuidString)"
        let storageRef = storage.reference().child("audio/poi/\(audioId).m4a")
        
        let metadata = StorageMetadata()
        metadata.contentType = "audio/mp4"
        metadata.customMetadata = [
            "poiId": poiId,
            "title": title,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        let uploadTask = storageRef.putFile(from: audioURL, metadata: metadata)
        uploadTasks[audioId] = uploadTask
        
        // Отслеживание прогресса
        uploadTask.observe(.progress) { [weak self] snapshot in
            let progress = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            DispatchQueue.main.async {
                self?.uploadProgress[audioId] = progress
            }
        }
        
        // Ожидание завершения загрузки
        let snapshot = try await uploadTask
        let downloadURL = try await snapshot.reference.downloadURL()
        
        // Обновить POI с новым аудиофайлом
        try await updatePOIAudio(poiId: poiId, audioURL: downloadURL.absoluteString, audioId: audioId)
        
        uploadTasks.removeValue(forKey: audioId)
        uploadProgress.removeValue(forKey: audioId)
        
        return downloadURL.absoluteString
    }
    
    /// Загрузить изображение для POI
    func uploadPOIImage(poiId: String, imageURL: URL, caption: String) async throws -> String {
        let imageId = "\(poiId)_\(UUID().uuidString)"
        let storageRef = storage.reference().child("images/poi/\(imageId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "poiId": poiId,
            "caption": caption,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        let uploadTask = storageRef.putFile(from: imageURL, metadata: metadata)
        uploadTasks[imageId] = uploadTask
        
        // Отслеживание прогресса
        uploadTask.observe(.progress) { [weak self] snapshot in
            let progress = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            DispatchQueue.main.async {
                self?.uploadProgress[imageId] = progress
            }
        }
        
        // Ожидание завершения загрузки
        let snapshot = try await uploadTask
        let downloadURL = try await snapshot.reference.downloadURL()
        
        // Обновить POI с новым изображением
        try await updatePOIImage(poiId: poiId, imageURL: downloadURL.absoluteString, imageId: imageId, caption: caption)
        
        uploadTasks.removeValue(forKey: imageId)
        uploadProgress.removeValue(forKey: imageId)
        
        return downloadURL.absoluteString
    }
    
    /// Пакетная загрузка контента POI
    func uploadPOIContent(_ poi: POI, images: [URL], audioURL: URL?) async throws {
        isUploading = true
        uploadError = nil
        
        do {
            // 1. Загрузить изображения
            var imageURLs: [String] = []
            for imageURL in images {
                let uploadedURL = try await uploadPOIImage(
                    poiId: poi.id,
                    imageURL: imageURL,
                    caption: "Изображение \(poi.name)"
                )
                imageURLs.append(uploadedURL)
            }
            
            // 2. Загрузить аудио (если есть)
            var audioURLs: [String] = []
            if let audioURL = audioURL {
                let uploadedURL = try await uploadAudioGuide(
                    poiId: poi.id,
                    audioURL: audioURL,
                    title: "Аудиогид: \(poi.name)"
                )
                audioURLs.append(uploadedURL)
            }
            
            // 3. Создать POI с загруженными файлами
            var updatedPOI = poi
            updatedPOI.imageUrl = imageURLs.first ?? ""
            // Обновить аудио в POI модели
            
            // 4. Сохранить POI в Firestore
            try await addPOI(updatedPOI)
            
            isUploading = false
            
        } catch {
            isUploading = false
            uploadError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Content Validation
    
    /// Проверить валидность контента POI
    func validatePOIContent(_ poi: POI) -> [String] {
        var errors: [String] = []
        
        if poi.name.isEmpty {
            errors.append("Название POI не может быть пустым")
        }
        
        if poi.description.isEmpty {
            errors.append("Описание POI не может быть пустым")
        }
        
        if poi.address.isEmpty {
            errors.append("Адрес POI не может быть пустым")
        }
        
        if poi.latitude == 0 && poi.longitude == 0 {
            errors.append("Координаты POI должны быть указаны")
        }
        
        if poi.category.isEmpty {
            errors.append("Категория POI должна быть указана")
        }
        
        return errors
    }
    
    /// Проверить валидность аудиофайла
    func validateAudioFile(_ url: URL) -> [String] {
        var errors: [String] = []
        
        // Проверить размер файла (максимум 50MB)
        if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
           fileSize > 50 * 1024 * 1024 {
            errors.append("Размер аудиофайла не должен превышать 50MB")
        }
        
        // Проверить формат файла
        let allowedExtensions = ["m4a", "mp3", "wav", "aac"]
        let fileExtension = url.pathExtension.lowercased()
        if !allowedExtensions.contains(fileExtension) {
            errors.append("Поддерживаются только форматы: \(allowedExtensions.joined(separator: ", "))")
        }
        
        return errors
    }
    
    /// Проверить валидность изображения
    func validateImageFile(_ url: URL) -> [String] {
        var errors: [String] = []
        
        // Проверить размер файла (максимум 10MB)
        if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
           fileSize > 10 * 1024 * 1024 {
            errors.append("Размер изображения не должен превышать 10MB")
        }
        
        // Проверить формат файла
        let allowedExtensions = ["jpg", "jpeg", "png", "heic"]
        let fileExtension = url.pathExtension.lowercased()
        if !allowedExtensions.contains(fileExtension) {
            errors.append("Поддерживаются только форматы: \(allowedExtensions.joined(separator: ", "))")
        }
        
        return errors
    }
    
    // MARK: - Content Synchronization
    
    /// Синхронизировать локальный контент с Firebase
    func syncLocalContent() async throws {
        let localPOIs = LocalContentService.shared.loadPOIs()
        
        for poi in localPOIs {
            do {
                try await addPOI(poi)
            } catch {
                print("Failed to sync POI \(poi.id): \(error)")
            }
        }
    }
    
    /// Экспортировать контент в JSON
    func exportContent() async throws -> Data {
        let pois = try await FirestoreService.shared.fetchPOIList()
        let routes = try await FirestoreService.shared.fetchRouteList()
        
        let exportData = ExportData(
            version: contentVersion,
            exportedAt: Date(),
            pois: pois,
            routes: routes
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    // MARK: - Private Methods
    
    private func updatePOIAudio(poiId: String, audioURL: String, audioId: String) async throws {
        let audioData = [
            "audioId": audioId,
            "audioURL": audioURL,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("poi").document(poiId).updateData([
            "audio": FieldValue.arrayUnion([audioData])
        ])
    }
    
    private func updatePOIImage(poiId: String, imageURL: String, imageId: String, caption: String) async throws {
        let imageData = [
            "imageId": imageId,
            "imageURL": imageURL,
            "caption": caption,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("poi").document(poiId).updateData([
            "images": FieldValue.arrayUnion([imageData])
        ])
    }
    
    private func deletePOIFiles(poiId: String) async throws {
        // Удалить аудиофайлы
        let audioRefs = storage.reference().child("audio/poi").listAll()
        for item in try await audioRefs.items {
            if item.name.hasPrefix(poiId) {
                try await item.delete()
            }
        }
        
        // Удалить изображения
        let imageRefs = storage.reference().child("images/poi").listAll()
        for item in try await imageRefs.items {
            if item.name.hasPrefix(poiId) {
                try await item.delete()
            }
        }
    }
}

// MARK: - Export Data Model
struct ExportData: Codable {
    let version: String
    let exportedAt: Date
    let pois: [POI]
    let routes: [Route]
}

// MARK: - Content Management Errors
enum ContentManagementError: LocalizedError {
    case invalidPOIData
    case invalidAudioFile
    case invalidImageFile
    case uploadFailed
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidPOIData:
            return "Некорректные данные POI"
        case .invalidAudioFile:
            return "Некорректный аудиофайл"
        case .invalidImageFile:
            return "Некорректное изображение"
        case .uploadFailed:
            return "Ошибка загрузки файла"
        case .syncFailed:
            return "Ошибка синхронизации"
        }
    }
}