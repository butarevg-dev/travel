import SwiftUI

struct MapScreen: View {
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Главная карта")
                    .font(.title2).bold()
                Text("Моки: пины, фильтры, кнопка \"Собрать маршрут\"")
                    .foregroundColor(.secondary)
                Spacer()
                MiniAudioPlayerMock()
            }
            .padding()
        }
    }
}

struct MiniAudioPlayerMock: View {
    @State private var isPlaying = false
    @State private var progress: Double = 0.35
    @State private var speed: Double = 1.0

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Button(action: { /* back 10s */ }) { Image(systemName: "gobackward.10") }
                Button(action: { isPlaying.toggle() }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                }
                Button(action: { /* forward 10s */ }) { Image(systemName: "goforward.10") }
                Spacer()
                Menu("x\(String(format: "%.1f", speed))") {
                    Button("0.5x") { speed = 0.5 }
                    Button("1.0x") { speed = 1.0 }
                    Button("1.5x") { speed = 1.5 }
                    Button("2.0x") { speed = 2.0 }
                }
                Button(action: { /* download */ }) { Image(systemName: "arrow.down.circle") }
            }
            .font(.title3)
            Slider(value: $progress)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}