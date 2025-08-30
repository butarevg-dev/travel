import SwiftUI

struct ModerationScreen: View {
    @StateObject private var reviewService = ReviewService.shared
    @State private var selectedTab = 0
    @State private var showingActionSheet = false
    @State private var selectedContent: ModerationItem?
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab Selector
                Picker("Тип контента", selection: $selectedTab) {
                    Text("Отзывы").tag(0)
                    Text("Вопросы").tag(1)
                    Text("Спам").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content List
                if selectedTab == 0 {
                    ReviewsModerationList()
                } else if selectedTab == 1 {
                    QuestionsModerationList()
                } else {
                    SpamModerationList()
                }
            }
            .navigationTitle("Модерация")
            .navigationBarTitleDisplayMode(.large)
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Действие с контентом"),
                message: Text("Выберите действие для выбранного контента"),
                buttons: [
                    .default(Text("Одобрить")) {
                        approveContent()
                    },
                    .destructive(Text("Удалить")) {
                        deleteContent()
                    },
                    .default(Text("Скрыть")) {
                        hideContent()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func approveContent() {
        guard let content = selectedContent else { return }
        // TODO: Implement approval logic
    }
    
    private func deleteContent() {
        guard let content = selectedContent else { return }
        // TODO: Implement deletion logic
    }
    
    private func hideContent() {
        guard let content = selectedContent else { return }
        // TODO: Implement hide logic
    }
}

// MARK: - Reviews Moderation List

struct ReviewsModerationList: View {
    @StateObject private var reviewService = ReviewService.shared
    @State private var flaggedReviews: [Review] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Загрузка отзывов...")
            } else if flaggedReviews.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("Нет отзывов для модерации")
                        .font(.headline)
                        .padding()
                }
            } else {
                List(flaggedReviews, id: \.id) { review in
                    ReviewModerationRow(review: review)
                }
            }
        }
        .onAppear {
            loadFlaggedReviews()
        }
    }
    
    private func loadFlaggedReviews() {
        // TODO: Load flagged reviews from Firestore
        isLoading = false
    }
}

struct ReviewModerationRow: View {
    let review: Review
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Отзыв для POI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Пользователь: \(review.userId)")
                        .font(.subheadline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Рейтинг: \(review.rating)/5")
                        .font(.caption)
                    if review.reported == true {
                        Text("ПОМЕЧЕН")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            if let text = review.text {
                Text(text)
                    .font(.body)
                    .lineLimit(3)
            }
            
            HStack {
                Text(review.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Подробнее") {
                    showingDetails = true
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDetails) {
            ReviewModerationDetail(review: review)
        }
    }
}

struct ReviewModerationDetail: View {
    let review: Review
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Review Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Содержание отзыва")
                            .font(.headline)
                        
                        if let text = review.text {
                            Text(text)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        HStack {
                            Text("Рейтинг: \(review.rating)/5")
                            Spacer()
                            Text("Дата: \(review.createdAt, style: .date)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    // Moderation Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Действия модерации")
                            .font(.headline)
                        
                        HStack {
                            Button("Одобрить") {
                                // TODO: Approve review
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            
                            Button("Скрыть") {
                                // TODO: Hide review
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            
                            Button("Удалить") {
                                // TODO: Delete review
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Детали отзыва")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Закрыть") {
                dismiss()
            })
        }
    }
}

// MARK: - Questions Moderation List

struct QuestionsModerationList: View {
    @State private var flaggedQuestions: [Question] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Загрузка вопросов...")
            } else if flaggedQuestions.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("Нет вопросов для модерации")
                        .font(.headline)
                        .padding()
                }
            } else {
                List(flaggedQuestions, id: \.id) { question in
                    QuestionModerationRow(question: question)
                }
            }
        }
        .onAppear {
            loadFlaggedQuestions()
        }
    }
    
    private func loadFlaggedQuestions() {
        // TODO: Load flagged questions from Firestore
        isLoading = false
    }
}

struct QuestionModerationRow: View {
    let question: Question
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Вопрос для POI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Пользователь: \(question.userId)")
                        .font(.subheadline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Статус: \(question.status)")
                        .font(.caption)
                    if question.status == "pending" {
                        Text("ОЖИДАЕТ")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Text(question.text)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                Text(question.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Подробнее") {
                    showingDetails = true
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDetails) {
            QuestionModerationDetail(question: question)
        }
    }
}

struct QuestionModerationDetail: View {
    let question: Question
    @Environment(\.dismiss) private var dismiss
    @State private var answerText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Question Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Вопрос")
                            .font(.headline)
                        
                        Text(question.text)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        HStack {
                            Text("Статус: \(question.status)")
                            Spacer()
                            Text("Дата: \(question.createdAt, style: .date)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    // Answer Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ответ")
                            .font(.headline)
                        
                        TextEditor(text: $answerText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Moderation Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Действия модерации")
                            .font(.headline)
                        
                        HStack {
                            Button("Ответить") {
                                // TODO: Answer question
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(answerText.isEmpty)
                            
                            Button("Удалить") {
                                // TODO: Delete question
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Детали вопроса")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Закрыть") {
                dismiss()
            })
        }
    }
}

// MARK: - Spam Moderation List

struct SpamModerationList: View {
    @State private var spamContent: [ModerationItem] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Загрузка спама...")
            } else if spamContent.isEmpty {
                VStack {
                    Image(systemName: "shield.checkmark")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("Спам не обнаружен")
                        .font(.headline)
                    .padding()
                }
            } else {
                List(spamContent, id: \.id) { item in
                    SpamModerationRow(item: item)
                }
            }
        }
        .onAppear {
            loadSpamContent()
        }
    }
    
    private func loadSpamContent() {
        // TODO: Load spam content from Firestore
        isLoading = false
    }
}

struct SpamModerationRow: View {
    let item: ModerationItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.contentType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Пользователь: \(item.userId)")
                        .font(.subheadline)
                }
                Spacer()
                Text("СПАМ")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(item.text)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                Text(item.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Флаги: \(item.flags.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Types

struct ModerationItem {
    let id: String
    let contentType: ContentType
    let userId: String
    let text: String
    let createdAt: Date
    let flags: [String]
}

extension ContentType {
    var displayName: String {
        switch self {
        case .review:
            return "Отзыв"
        case .question:
            return "Вопрос"
        }
    }
}

#Preview {
    ModerationScreen()
}