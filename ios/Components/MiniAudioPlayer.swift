import SwiftUI

struct MiniAudioPlayer: View {
    @StateObject private var audioService = AudioPlayerService.shared
    @StateObject private var cacheManager = AudioCacheManager.shared
    @State private var showingSpeedMenu = false
    @State private var showingFullPlayer = false
    
    var body: some View {
        if let currentAudio = audioService.currentAudio {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: audioService.duration > 0 ? audioService.currentTime / audioService.duration : 0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .onTapGesture { location in
                        // Handle seek on progress bar tap
                        let progress = location.x / UIScreen.main.bounds.width
                        let seekTime = progress * audioService.duration
                        audioService.seek(to: seekTime)
                    }
                
                // Player controls
                HStack(spacing: 16) {
                    // Audio info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentAudio.title)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        
                        Text(formatTime(audioService.currentTime))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Control buttons
                    HStack(spacing: 12) {
                        // Skip backward
                        Button(action: audioService.skipBackward) {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        // Play/Pause
                        Button(action: audioService.togglePlayback) {
                            Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.red)
                        }
                        
                        // Skip forward
                        Button(action: audioService.skipForward) {
                            Image(systemName: "goforward.10")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // Right side controls
                    HStack(spacing: 8) {
                        // Speed control
                        Menu {
                            Button("0.5x") { audioService.setPlaybackRate(0.5) }
                            Button("1.0x") { audioService.setPlaybackRate(1.0) }
                            Button("1.5x") { audioService.setPlaybackRate(1.5) }
                            Button("2.0x") { audioService.setPlaybackRate(2.0) }
                        } label: {
                            Text("x\(String(format: "%.1f", audioService.playbackRate))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                        }
                        
                        // Download/Delete button
                        Button(action: toggleDownload) {
                            Image(systemName: cacheManager.isDownloaded(currentAudio.url) ? "trash" : "arrow.down.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(cacheManager.isDownloaded(currentAudio.url) ? .red : .secondary)
                        }
                        
                        // Full player button
                        Button(action: { showingFullPlayer = true }) {
                            Image(systemName: "rectangle.expand.vertical")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .sheet(isPresented: $showingFullPlayer) {
                FullAudioPlayerView(audio: currentAudio)
            }
            .overlay(
                // Loading indicator
                Group {
                    if audioService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            .scaleEffect(0.8)
                    }
                }
                .padding(.trailing, 60)
                .padding(.bottom, 8),
                alignment: .bottomTrailing
            )
        }
    }
    
    private func toggleDownload() {
        guard let currentAudio = audioService.currentAudio else { return }
        
        if cacheManager.isDownloaded(currentAudio.url) {
            cacheManager.deleteAudio(currentAudio.url)
        } else {
            cacheManager.downloadAudio(from: currentAudio.url) { _ in
                // Download completed
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct FullAudioPlayerView: View {
    let audio: AudioPlayerService.AudioTrack
    @StateObject private var audioService = AudioPlayerService.shared
    @StateObject private var cacheManager = AudioCacheManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingSpeedMenu = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Audio artwork
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "headphones.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                            Text("Аудиогид")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                
                // Audio info
                VStack(spacing: 8) {
                    Text(audio.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    if let poiId = audio.poiId {
                        Text("POI: \(poiId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress section
                VStack(spacing: 16) {
                    // Progress bar
                    VStack(spacing: 8) {
                        ProgressView(value: audioService.duration > 0 ? audioService.currentTime / audioService.duration : 0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .red))
                            .scaleEffect(y: 2)
                        
                        HStack {
                            Text(formatTime(audioService.currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatTime(audioService.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Control buttons
                    HStack(spacing: 24) {
                        // Skip backward
                        Button(action: audioService.skipBackward) {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        // Play/Pause
                        Button(action: audioService.togglePlayback) {
                            Image(systemName: audioService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.red)
                        }
                        
                        // Skip forward
                        Button(action: audioService.skipForward) {
                            Image(systemName: "goforward.10")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Additional controls
                HStack(spacing: 32) {
                    // Speed control
                    VStack(spacing: 4) {
                        Button(action: { showingSpeedMenu = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary)
                                Text("x\(String(format: "%.1f", audioService.playbackRate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .actionSheet(isPresented: $showingSpeedMenu) {
                            ActionSheet(
                                title: Text("Скорость воспроизведения"),
                                buttons: [
                                    .default(Text("0.5x")) { audioService.setPlaybackRate(0.5) },
                                    .default(Text("1.0x")) { audioService.setPlaybackRate(1.0) },
                                    .default(Text("1.5x")) { audioService.setPlaybackRate(1.5) },
                                    .default(Text("2.0x")) { audioService.setPlaybackRate(2.0) },
                                    .cancel()
                                ]
                            )
                        }
                    }
                    
                    // Download/Delete
                    VStack(spacing: 4) {
                        Button(action: toggleDownload) {
                            VStack(spacing: 4) {
                                Image(systemName: cacheManager.isDownloaded(audio.url) ? "trash" : "arrow.down.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(cacheManager.isDownloaded(audio.url) ? .red : .secondary)
                                Text(cacheManager.isDownloaded(audio.url) ? "Удалить" : "Скачать")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Share
                    VStack(spacing: 4) {
                        Button(action: shareAudio) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary)
                                Text("Поделиться")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Аудиогид")
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
    
    private func toggleDownload() {
        if cacheManager.isDownloaded(audio.url) {
            cacheManager.deleteAudio(audio.url)
        } else {
            cacheManager.downloadAudio(from: audio.url) { _ in
                // Download completed
            }
        }
    }
    
    private func shareAudio() {
        // TODO: Implement share functionality
        print("Share audio: \(audio.title)")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    MiniAudioPlayer()
}