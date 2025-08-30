# 🔥 Руководство по настройке Firebase

## 📋 Обзор

Firebase используется в проекте "Саранск для Туристов" для:
- 🔐 **Аутентификации** пользователей (Google, Apple, VK)
- 📊 **Хранения данных** (POI, маршруты, отзывы)
- 📱 **Push-уведомлений**
- 📈 **Аналитики**

## 🚀 ШАГ 1: Создание проекта Firebase

### 1.1 Перейдите в Firebase Console
1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Войдите в свой Google аккаунт

### 1.2 Создайте новый проект
```
1. Нажмите "Create a project" или "Создать проект"
2. Введите название: "SaranskTourist"
3. Нажмите "Continue" или "Продолжить"
4. Отключите Google Analytics (не обязательно)
5. Нажмите "Create project" или "Создать проект"
```

### 1.3 Добавьте iOS приложение
```
1. На главной странице проекта нажмите значок iOS (🍎)
2. Введите Bundle ID: com.yourorg.saransk.tourist
3. Введите App nickname: "Саранск для Туристов"
4. Нажмите "Register app"
```

## 📱 ШАГ 2: Скачивание конфигурации

### 2.1 Скачайте GoogleService-Info.plist
```
1. После регистрации приложения Firebase предложит скачать GoogleService-Info.plist
2. Нажмите "Download GoogleService-Info.plist"
3. Сохраните файл в безопасное место
```

### 2.2 Добавьте файл в Xcode проект
```
1. Откройте Xcode проект
2. Правый клик на папку проекта в навигаторе
3. Выберите "Add Files to SaranskTourist"
4. Найдите и выберите GoogleService-Info.plist
5. Убедитесь, что "Add to target" отмечено
6. Нажмите "Add"
```

## 🔧 ШАГ 3: Настройка Authentication

### 3.1 Включите методы аутентификации
```
1. В Firebase Console перейдите в "Authentication"
2. Нажмите "Get started"
3. Включите следующие провайдеры:
   - Google
   - Apple
   - VK (если доступно)
```

### 3.2 Настройте Google Sign-In
```
1. В разделе "Sign-in method" нажмите "Google"
2. Включите Google Sign-In
3. Добавьте поддержку email
4. Сохраните настройки
```

### 3.3 Настройте Apple Sign-In
```
1. В разделе "Sign-in method" нажмите "Apple"
2. Включите Apple Sign-In
3. Добавьте Service ID (если нужно)
4. Сохраните настройки
```

## 📊 ШАГ 4: Настройка Firestore Database

### 4.1 Создайте базу данных
```
1. В Firebase Console перейдите в "Firestore Database"
2. Нажмите "Create database"
3. Выберите "Start in test mode" (для разработки)
4. Выберите ближайший регион (например, europe-west3)
5. Нажмите "Done"
```

### 4.2 Создайте коллекции
Создайте следующие коллекции в Firestore:

#### Коллекция "poi" (Points of Interest)
```json
{
  "id": "poi_1",
  "name": "Собор Святого Феодора Ушакова",
  "description": "Главный православный храм Саранска",
  "latitude": 54.1833,
  "longitude": 45.1747,
  "category": "religion",
  "rating": 4.8,
  "imageUrl": "https://example.com/cathedral.jpg",
  "address": "ул. Советская, 25",
  "phone": "+7 (8342) 123-456",
  "website": "https://example.com",
  "workingHours": "09:00-18:00",
  "price": "Бесплатно",
  "tags": ["собор", "религия", "архитектура"]
}
```

#### Коллекция "routes" (Маршруты)
```json
{
  "id": "route_1",
  "name": "Исторический центр Саранска",
  "description": "Пешеходный маршрут по историческому центру",
  "duration": "2 часа",
  "distance": "3.5 км",
  "difficulty": "easy",
  "poiIds": ["poi_1", "poi_2", "poi_3"],
  "imageUrl": "https://example.com/route1.jpg",
  "rating": 4.6,
  "tags": ["история", "пешеходный", "центр"]
}
```

#### Коллекция "reviews" (Отзывы)
```json
{
  "id": "review_1",
  "poiId": "poi_1",
  "userId": "user_123",
  "userName": "Иван Петров",
  "rating": 5,
  "comment": "Очень красивое место!",
  "createdAt": "2024-01-15T10:30:00Z",
  "images": ["https://example.com/review1.jpg"]
}
```

#### Коллекция "users" (Пользователи)
```json
{
  "id": "user_123",
  "email": "user@example.com",
  "displayName": "Иван Петров",
  "photoURL": "https://example.com/avatar.jpg",
  "createdAt": "2024-01-01T00:00:00Z",
  "preferences": {
    "language": "ru",
    "notifications": true,
    "theme": "light"
  },
  "stats": {
    "visitedPOIs": 15,
    "completedRoutes": 3,
    "totalDistance": 12.5
  }
}
```

## 🔔 ШАГ 5: Настройка Push-уведомлений

### 5.1 Включите Cloud Messaging
```
1. В Firebase Console перейдите в "Cloud Messaging"
2. Нажмите "Get started"
3. Следуйте инструкциям по настройке
```

### 5.2 Настройте APNs (Apple Push Notification service)
```
1. В Xcode перейдите в "Signing & Capabilities"
2. Добавьте "Push Notifications"
3. Скачайте APNs ключ из Apple Developer Console
4. Загрузите ключ в Firebase Console
```

## 📈 ШАГ 6: Настройка Analytics (опционально)

### 6.1 Включите Google Analytics
```
1. В Firebase Console перейдите в "Analytics"
2. Нажмите "Get started"
3. Следуйте инструкциям по настройке
```

## 🧪 ШАГ 7: Тестирование

### 7.1 Проверьте подключение
```swift
// В Xcode добавьте в App.swift:
import FirebaseCore

@main
struct SaranskTouristApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 7.2 Тестовые данные
```
1. Добавьте несколько тестовых POI в Firestore
2. Запустите приложение
3. Проверьте, что данные загружаются
4. Протестируйте аутентификацию
```

## 🔒 ШАГ 8: Настройка безопасности

### 8.1 Правила Firestore
```javascript
// В Firebase Console → Firestore Database → Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // POI доступны всем
    match /poi/{document} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    // Маршруты доступны всем
    match /routes/{document} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    // Отзывы - читают все, пишут авторизованные
    match /reviews/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Профили пользователей
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🚨 Устранение проблем

### Проблема: "Firebase not configured"
```
Решение: Убедитесь, что GoogleService-Info.plist добавлен в проект
```

### Проблема: "Permission denied"
```
Решение: Проверьте правила безопасности в Firestore
```

### Проблема: "Authentication failed"
```
Решение: Проверьте настройки провайдеров аутентификации
```

## 📚 Дополнительные ресурсы

- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Authentication](https://firebase.google.com/docs/auth)

## ✅ Проверочный список

- [ ] Проект Firebase создан
- [ ] iOS приложение зарегистрировано
- [ ] GoogleService-Info.plist добавлен в Xcode
- [ ] Authentication настроен
- [ ] Firestore Database создан
- [ ] Тестовые данные добавлены
- [ ] Правила безопасности настроены
- [ ] Приложение тестируется

🎉 **Firebase настроен и готов к использованию!**