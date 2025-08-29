import SwiftUI

struct ProfileScreen: View {
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var audioCacheManager = AudioCacheManager.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var userService = UserService.shared
    @State private var showingOfflineAlert = false
    @State private var showingAudioCacheAlert = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Профиль") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userService.currentProfile?.displayName ?? "Пользователь")
                                .font(.headline)
                            Text(userService.currentProfile?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if userService.isPremium() {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Text("Избранное")
                        Spacer()
                        Text("\(userService.currentProfile?.favorites.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("История маршрутов")
                        Spacer()
                        Text("\(userService.currentProfile?.routeHistory.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Значки")
                        Spacer()
                        Text("\(userService.currentProfile?.badges.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Оффлайн-режим") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Оффлайн-контент")
                                .font(.system(size: 16, weight: .medium))
                            if offlineManager.isOfflineModeEnabled {
                                Text("Версия: \(offlineManager.offlineContentVersion)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("Размер: \(formatFileSize(offlineManager.downloadedSize))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if offlineManager.isDownloading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Button(offlineManager.isOfflineModeEnabled ? "Обновить" : "Загрузить") {
                                Task {
                                    await offlineManager.downloadOfflineContent()
                                }
                            }
                            .disabled(offlineManager.isDownloading)
                        }
                    }
                    
                    if offlineManager.isOfflineModeEnabled {
                        Button("Удалить оффлайн-контент") {
                            showingOfflineAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("Аудио-кэш") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Скачанные аудиогиды")
                                .font(.system(size: 16, weight: .medium))
                            Text("\(audioCacheManager.downloadedAudios.count) файлов")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("Размер: \(formatFileSize(audioCacheManager.getCacheSize()))")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Очистить") {
                            showingAudioCacheAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("Настройки") {
                    Toggle("Оффлайн-режим", isOn: $offlineManager.isOfflineModeEnabled)
                        .disabled(offlineManager.isDownloading)
                    
                    HStack {
                        Text("Язык")
                        Spacer()
                        Text("Русский")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Тема")
                        Spacer()
                        Text("Системная")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Информация") {
                    HStack {
                        Text("Версия приложения")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Версия контента")
                        Spacer()
                        Text(offlineManager.offlineContentVersion.isEmpty ? "Не загружена" : offlineManager.offlineContentVersion)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Аккаунт") {
                    Button("Выйти") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Профиль")
            .alert("Удалить оффлайн-контент?", isPresented: $showingOfflineAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    offlineManager.deleteOfflineContent()
                }
            } message: {
                Text("Это действие нельзя отменить. Весь загруженный контент будет удален.")
            }
            .alert("Очистить аудио-кэш?", isPresented: $showingAudioCacheAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Очистить", role: .destructive) {
                    audioCacheManager.clearCache()
                }
            } message: {
                Text("Все скачанные аудиогиды будут удалены.")
            }
            .alert("Выйти из аккаунта?", isPresented: $showingSignOutAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Выйти", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                    }
                }
            } message: {
                Text("Вы уверены, что хотите выйти из аккаунта?")
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}