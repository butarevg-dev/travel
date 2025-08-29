import Foundation
import AVFoundation
import Combine
import MediaPlayer

class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var currentAudio: AudioTrack?
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Audio Track Model
    struct AudioTrack: Identifiable, Codable {
        let id: String
        let title: String
        let url: URL
        let duration: TimeInterval
        let poiId: String?
        let isDownloaded: Bool
        
        init(id: String, title: String, url: URL, duration: TimeInterval = 0, poiId: String? = nil, isDownloaded: Bool = false) {
            self.id = id
            self.title = title
            self.url = url
            self.duration = duration
            self.poiId = poiId
            self.isDownloaded = isDownloaded
        }
    }
    
    // MARK: - Initialization
    private override init() {
        self.audioSession = AVAudioSession.sharedInstance()
        super.init()
        setupAudioSession()
        setupNotifications()
        setupRemoteTransportControls()
        restorePlaybackPosition()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            // Enable background playback
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Remote Transport Controls
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // Skip forward command
        commandCenter.skipForwardCommand.preferredIntervals = [10]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }
        
        // Skip backward command
        commandCenter.skipBackwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }
        
        // Seek command
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // App lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            pause()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    play()
                }
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        // Handle audio route changes (headphones, speaker, etc.)
    }
    
    @objc private func handleAppDidEnterBackground() {
        // Save current position when app goes to background
        savePlaybackPosition()
        updateNowPlayingInfo()
    }
    
    @objc private func handleAppWillEnterForeground() {
        // Restore position when app comes to foreground
        restorePlaybackPosition()
    }
    
    // MARK: - Position Persistence
    private func savePlaybackPosition() {
        guard let currentAudio = currentAudio else { return }
        let position = currentTime
        userDefaults.set(position, forKey: "audio_position_\(currentAudio.id)")
        userDefaults.set(currentAudio.id, forKey: "last_audio_id")
    }
    
    private func restorePlaybackPosition() {
        guard let lastAudioId = userDefaults.string(forKey: "last_audio_id"),
              let position = userDefaults.object(forKey: "audio_position_\(lastAudioId)") as? TimeInterval else {
            return
        }
        
        // Only restore if we have the same audio loaded
        if currentAudio?.id == lastAudioId {
            seek(to: position)
        }
    }
    
    // MARK: - Now Playing Info
    private func updateNowPlayingInfo() {
        guard let currentAudio = currentAudio else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentAudio.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Саранск для туристов"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Аудиогид"
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        
        // Set artwork
        if let image = UIImage(systemName: "headphones.circle") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
                return image
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: - Public Methods
    
    func loadAudio(from url: URL, title: String, poiId: String? = nil) {
        isLoading = true
        error = nil
        
        // Check if audio is already downloaded
        if let localURL = AudioCacheManager.shared.getLocalURL(for: url) {
            playAudio(from: localURL, title: title, poiId: poiId)
        } else {
            // Download and play
            AudioCacheManager.shared.downloadAudio(from: url) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let localURL):
                        self?.playAudio(from: localURL, title: title, poiId: poiId)
                    case .failure(let error):
                        self?.error = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func play() {
        guard let player = audioPlayer else { return }
        
        do {
            try audioSession.setActive(true)
            player.play()
            isPlaying = true
            startTimer()
            updateNowPlayingInfo()
        } catch {
            self.error = "Failed to play audio: \(error.localizedDescription)"
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
        savePlaybackPosition()
        updateNowPlayingInfo()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopTimer()
        savePlaybackPosition()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
        updateNowPlayingInfo()
    }
    
    func skipForward() {
        let newTime = min(currentTime + 10, duration)
        seek(to: newTime)
    }
    
    func skipBackward() {
        let newTime = max(currentTime - 10, 0)
        seek(to: newTime)
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        audioPlayer?.rate = rate
        updateNowPlayingInfo()
    }
    
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // MARK: - Private Methods
    
    private func playAudio(from url: URL, title: String, poiId: String?) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            currentAudio = AudioTrack(
                id: url.lastPathComponent,
                title: title,
                url: url,
                duration: duration,
                poiId: poiId,
                isDownloaded: true
            )
            
            play()
        } catch {
            self.error = "Failed to load audio: \(error.localizedDescription)"
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
            self.updateNowPlayingInfo()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopTimer()
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = 0
            self.stopTimer()
            self.savePlaybackPosition()
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.error = error?.localizedDescription ?? "Audio decode error"
            self.isPlaying = false
            self.stopTimer()
        }
    }
}