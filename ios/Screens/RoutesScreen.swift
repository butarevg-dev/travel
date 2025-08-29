import SwiftUI

struct RoutesScreen: View {
    @State private var selectedPreset: String? = "3ч"
    @State private var interests: Set<String> = ["архитектура", "история"]
    @State private var minutes: Double = 180

    var body: some View {
        NavigationStack {
            Form {
                Section("Предустановленные") {
                    Picker("Маршрут", selection: $selectedPreset) {
                        Text("3 часа").tag("3ч" as String?)
                        Text("6 часов").tag("6ч" as String?)
                        Text("1 день").tag("1д" as String?)
                        Text("Выходные").tag("выходные" as String?)
                    }
                }
                Section("Генерация по интересам") {
                    Toggle("Архитектура", isOn: Binding(
                        get: { interests.contains("архитектура") },
                        set: { $0 ? interests.insert("архитектура") : interests.remove("архитектура") }
                    ))
                    Toggle("История", isOn: Binding(
                        get: { interests.contains("история") },
                        set: { $0 ? interests.insert("история") : interests.remove("история") }
                    ))
                    Slider(value: $minutes, in: 60...720, step: 30) { Text("Время (мин)") }
                    Text("~ \(Int(minutes)) минут")
                    Button("Сгенерировать маршрут") { /* generate */ }
                }
            }
            .navigationTitle("Маршруты")
        }
    }
}