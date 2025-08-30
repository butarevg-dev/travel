import Foundation
import Combine
import CryptoKit

struct OfflineManifest: Codable {
    let version: String
    let timestamp: Date
    let files: [OfflineFile]
    let totalSize: Int64
    
    struct OfflineFile: Codable {
        let path: String
        let hash: String
        let size: Int64
        let type: String // "content", "image", "audio"
    }
}

class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var offlineContentVersion: String = ""
    @Published var isOfflineModeEnabled = false
    @Published var downloadedSize: Int64 = 0
    @Published var totalSize: Int64 = 0
    
    private let fileManager = FileManager.default
    private let documentsPath: URL
    private let offlinePath: URL
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        offlinePath = documentsPath.appendingPathComponent("offline")
        
        // Create offline directory if needed
        try? fileManager.createDirectory(at: offlinePath, withIntermediateDirectories: true)
        
        loadOfflineStatus()
    }
    
    // MARK: - Public Methods
    
    func checkForUpdates() async -> Bool {
        do {
            let localVersion = loadLocalVersion()
            let remoteVersion = try await fetchRemoteVersion()
            
            return remoteVersion != localVersion
        } catch {
            print("Error checking for updates: \(error)")
            return false
        }
    }
    
    func downloadOfflineContent() async {
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0.0
        }
        
        do {
            let manifest = try await fetchManifest()
            
            await MainActor.run {
                totalSize = manifest.totalSize
                offlineContentVersion = manifest.version
            }
            
            // Download content files
            for (index, file) in manifest.files.enumerated() {
                try await downloadFile(file)
                
                await MainActor.run {
                    downloadProgress = Double(index + 1) / Double(manifest.files.count)
                    downloadedSize += file.size
                }
            }
            
            // Save manifest locally
            try saveManifest(manifest)
            
            await MainActor.run {
                isOfflineModeEnabled = true
                isDownloading = false
            }
            
        } catch {
            await MainActor.run {
                isDownloading = false
            }
            print("Error downloading offline content: \(error)")
        }
    }
    
    func deleteOfflineContent() {
        do {
            try fileManager.removeItem(at: offlinePath)
            try fileManager.createDirectory(at: offlinePath, withIntermediateDirectories: true)
            
            isOfflineModeEnabled = false
            offlineContentVersion = ""
            downloadedSize = 0
            totalSize = 0
            
            saveOfflineStatus()
        } catch {
            print("Error deleting offline content: \(error)")
        }
    }
    
    func getOfflineFileURL(for path: String) -> URL? {
        let fileURL = offlinePath.appendingPathComponent(path)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func isFileAvailableOffline(_ path: String) -> Bool {
        let fileURL = offlinePath.appendingPathComponent(path)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Private Methods
    
    private func fetchManifest() async throws -> OfflineManifest {
        // In a real app, this would fetch from your backend
        // For now, we'll create a mock manifest based on local files
        
        let contentURL = Bundle.main.url(forResource: "poi", withExtension: "json", subdirectory: "content")
        let routesURL = Bundle.main.url(forResource: "routes", withExtension: "json", subdirectory: "content")
        
        var files: [OfflineManifest.OfflineFile] = []
        var totalSize: Int64 = 0
        
        if let contentURL = contentURL {
            let contentData = try Data(contentsOf: contentURL)
            let contentHash = contentData.sha256()
            files.append(OfflineManifest.OfflineFile(
                path: "content/poi.json",
                hash: contentHash,
                size: Int64(contentData.count),
                type: "content"
            ))
            totalSize += Int64(contentData.count)
        }
        
        if let routesURL = routesURL {
            let routesData = try Data(contentsOf: routesURL)
            let routesHash = routesData.sha256()
            files.append(OfflineManifest.OfflineFile(
                path: "content/routes.json",
                hash: routesHash,
                size: Int64(routesData.count),
                type: "content"
            ))
            totalSize += Int64(routesData.count)
        }
        
        return OfflineManifest(
            version: "1.0.0",
            timestamp: Date(),
            files: files,
            totalSize: totalSize
        )
    }
    
    private func fetchRemoteVersion() async throws -> String {
        // In a real app, this would fetch from your backend
        // For now, return a mock version
        return "1.0.0"
    }
    
    private func downloadFile(_ file: OfflineManifest.OfflineFile) async throws {
        // In a real app, this would download from your backend
        // For now, we'll copy from bundle if available
        
        let sourceURL = Bundle.main.url(forResource: file.path.replacingOccurrences(of: ".json", with: ""), 
                                       withExtension: "json", 
                                       subdirectory: file.path.replacingOccurrences(of: "/\(file.path.components(separatedBy: "/").last!)", with: ""))
        
        if let sourceURL = sourceURL {
            let destinationURL = offlinePath.appendingPathComponent(file.path)
            
            // Create directory if needed
            try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), 
                                          withIntermediateDirectories: true)
            
            // Copy file
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
    }
    
    private func saveManifest(_ manifest: OfflineManifest) throws {
        let manifestURL = offlinePath.appendingPathComponent("manifest.json")
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: manifestURL)
    }
    
    private func loadLocalVersion() -> String {
        let manifestURL = offlinePath.appendingPathComponent("manifest.json")
        guard let data = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(OfflineManifest.self, from: data) else {
            return ""
        }
        return manifest.version
    }
    
    private func loadOfflineStatus() {
        let manifestURL = offlinePath.appendingPathComponent("manifest.json")
        if fileManager.fileExists(atPath: manifestURL.path) {
            isOfflineModeEnabled = true
            offlineContentVersion = loadLocalVersion()
            
            // Calculate downloaded size
            let manifest = try? JSONDecoder().decode(OfflineManifest.self, from: Data(contentsOf: manifestURL))
            downloadedSize = manifest?.totalSize ?? 0
            totalSize = manifest?.totalSize ?? 0
        }
    }
    
    private func saveOfflineStatus() {
        // Save to UserDefaults or other persistent storage
        UserDefaults.standard.set(isOfflineModeEnabled, forKey: "isOfflineModeEnabled")
        UserDefaults.standard.set(offlineContentVersion, forKey: "offlineContentVersion")
    }
}

// MARK: - Extensions

extension Data {
    func sha256() -> String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}