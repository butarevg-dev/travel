import Foundation
import Combine

class AudioCacheManager: ObservableObject {
    static let shared = AudioCacheManager()
    
    // MARK: - Published Properties
    @Published var downloadProgress: [String: Double] = [:]
    @Published var downloadedAudios: Set<String> = []
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let session = URLSession.shared
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    
    // MARK: - Initialization
    private init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("audio_cache")
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Load existing downloaded files
        loadDownloadedAudios()
    }
    
    // MARK: - Public Methods
    
    func downloadAudio(from url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let audioId = url.lastPathComponent
        
        // Check if already downloaded
        if let localURL = getLocalURL(for: url) {
            completion(.success(localURL))
            return
        }
        
        // Check if download is in progress
        if downloadTasks[audioId] != nil {
            // Download already in progress, wait for completion
            return
        }
        
        let task = session.downloadTask(with: url) { [weak self] localURL, response, error in
            DispatchQueue.main.async {
                self?.downloadTasks.removeValue(forKey: audioId)
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let localURL = localURL else {
                    completion(.failure(AudioCacheError.downloadFailed))
                    return
                }
                
                // Move to cache directory
                let destinationURL = self?.cacheDirectory.appendingPathComponent(audioId)
                
                do {
                    if let destinationURL = destinationURL {
                        // Remove existing file if any
                        try? self?.fileManager.removeItem(at: destinationURL)
                        
                        // Move downloaded file to cache
                        try self?.fileManager.moveItem(at: localURL, to: destinationURL)
                        
                        // Update downloaded audios
                        self?.downloadedAudios.insert(audioId)
                        self?.saveDownloadedAudios()
                        
                        completion(.success(destinationURL))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
        
        downloadTasks[audioId] = task
        downloadProgress[audioId] = 0.0
        task.resume()
    }
    
    func getLocalURL(for url: URL) -> URL? {
        let audioId = url.lastPathComponent
        let localURL = cacheDirectory.appendingPathComponent(audioId)
        
        return fileManager.fileExists(atPath: localURL.path) ? localURL : nil
    }
    
    func isDownloaded(_ url: URL) -> Bool {
        let audioId = url.lastPathComponent
        return downloadedAudios.contains(audioId)
    }
    
    func deleteAudio(_ url: URL) {
        let audioId = url.lastPathComponent
        let localURL = cacheDirectory.appendingPathComponent(audioId)
        
        do {
            try fileManager.removeItem(at: localURL)
            downloadedAudios.remove(audioId)
            saveDownloadedAudios()
        } catch {
            print("Failed to delete audio: \(error)")
        }
    }
    
    func clearCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
            downloadedAudios.removeAll()
            saveDownloadedAudios()
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
    
    func getCacheSize() -> Int64 {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            return try contents.reduce(0) { total, url in
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                return total + Int64(resourceValues.fileSize ?? 0)
            }
        } catch {
            return 0
        }
    }
    
    // MARK: - Private Methods
    
    private func loadDownloadedAudios() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            downloadedAudios = Set(contents.map { $0.lastPathComponent })
        } catch {
            print("Failed to load downloaded audios: \(error)")
        }
    }
    
    private func saveDownloadedAudios() {
        // In a real app, you might want to persist this to UserDefaults or a database
        // For now, we'll just keep it in memory
    }
}

// MARK: - URLSessionDownloadDelegate
extension AudioCacheManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // This is handled in the completion handler
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let audioId = downloadTask.originalRequest?.url?.lastPathComponent ?? ""
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async {
            self.downloadProgress[audioId] = progress
        }
    }
}

// MARK: - Errors
enum AudioCacheError: LocalizedError {
    case downloadFailed
    case fileNotFound
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download audio file"
        case .fileNotFound:
            return "Audio file not found"
        case .invalidURL:
            return "Invalid audio URL"
        }
    }
}