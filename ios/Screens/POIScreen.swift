import SwiftUI

struct POIScreen: View {
    var body: some View {
        NavigationStack {
            List(0..<10) { idx in
                NavigationLink("POI #\(idx)") {
                    POIDetailMock(index: idx)
                }
            }
            .navigationTitle("Каталог POI")
        }
    }
}

struct POIDetailMock: View {
    let index: Int
    @State private var rating: Int = 4
    @State private var comment: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 180).overlay(Text("Фото"))
                Text("Название POI #\(index)").font(.title2).bold()
                Text("Краткое описание точки интереса в Саранске...")
                HStack {
                    Text("Рейтинг:")
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .onTapGesture { rating = i }
                    }
                }
                TextField("Оставить комментарий", text: $comment)
                    .textFieldStyle(.roundedBorder)
                Button("Отправить") { /* submit */ }
                Divider()
                MiniAudioPlayerMock()
            }.padding()
        }
        .navigationTitle("Детали")
    }
}