import SwiftUI

struct ProfileScreen: View {
    @State private var isOffline = true
    @State private var language = "ru"

    var body: some View {
        NavigationStack {
            Form {
                Section("Аккаунт") {
                    HStack {
                        Image(systemName: "person.circle").font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("Гость")
                            Text("Войдите, чтобы синхронизировать избранное").font(.footnote).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Войти") { /* auth */ }
                    }
                }
                Section("Настройки") {
                    Toggle("Оффлайн-режим", isOn: $isOffline)
                    Picker("Язык", selection: $language) {
                        Text("Русский").tag("ru")
                        Text("English").tag("en")
                    }
                }
                Section("Награды и квесты") {
                    Text("Бейджи: 0")
                    Text("Активные квесты: 0")
                }
                Section("О приложении") {
                    Text("Версия контента: см. offline/version.json")
                }
            }
            .navigationTitle("Профиль")
        }
    }
}