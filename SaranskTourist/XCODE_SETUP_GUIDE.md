# 🚀 Руководство по созданию Xcode проекта

## 📱 ШАГ 1: Создание нового Xcode проекта

1. **Откройте Xcode**
2. **File** → **New** → **Project**
3. Выберите **iOS** → **App**
4. Нажмите **Next**

### Настройки проекта:
```
Product Name: SaranskTourist
Team: Ваша команда разработчиков
Organization Identifier: com.yourorg.saransk.tourist
Bundle Identifier: com.yourorg.saransk.tourist
Language: Swift
Interface: SwiftUI
Life Cycle: SwiftUI App
Use Core Data: ❌ (не нужно)
Include Tests: ✅ (рекомендуется)
```

5. Выберите расположение и нажмите **Create**

## 📁 ШАГ 2: Добавление файлов в проект

1. **Правый клик** на папку проекта в Xcode
2. **"Add Files to SaranskTourist"**
3. Перейдите в папку `SaranskTourist/` (созданную этим скриптом)
4. Выберите **все файлы и папки**
5. Убедитесь, что **"Add to target"** отмечено
6. Нажмите **"Add"**

### Создайте группы для организации:
- **Models** (для файлов моделей)
- **Services** (для сервисов)
- **Screens** (для экранов)
- **Components** (для UI компонентов)
- **Resources** (для JSON и медиа файлов)

## 🔧 ШАГ 3: Настройка зависимостей (Swift Package Manager)

### 3.1 Добавьте Firebase
1. **File** → **Add Package Dependencies**
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. Версия: `10.0.0` или новее
4. Выберите продукты:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseAnalytics
   - FirebaseCrashlytics
   - FirebasePerformance

### 3.2 Добавьте Google Sign-In
1. **File** → **Add Package Dependencies**
2. URL: `https://github.com/google/GoogleSignIn-iOS`
3. Версия: `7.0.0` или новее

## ⚙️ ШАГ 4: Настройка Firebase

### 4.1 Создайте проект Firebase
1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Создайте новый проект: **"SaranskTourist"**
3. Добавьте iOS приложение
4. Bundle ID: `com.yourorg.saransk.tourist`

### 4.2 Скачайте GoogleService-Info.plist
1. Скачайте файл из Firebase Console
2. Добавьте в корень проекта в Xcode
3. Убедитесь, что **"Add to target"** отмечено

## 🎯 ШАГ 5: Настройка таргетов и возможностей

### 5.1 Настройте Bundle ID
1. Выберите проект в навигаторе
2. Выберите таргет **SaranskTourist**
3. В **"General"** проверьте Bundle Identifier

### 5.2 Добавьте возможности
В **"Signing & Capabilities"**:
1. **Sign in with Apple** ✅
2. **Push Notifications** ✅ (опционально)
3. **Background Modes** → **Audio, AirPlay, and Picture in Picture** ✅

## 🚀 ШАГ 6: Запуск проекта

### 6.1 Выберите симулятор
1. В верхней части Xcode выберите симулятор
2. Рекомендуется: **iPhone 14** или **iPhone 15**

### 6.2 Соберите проект
1. **Product** → **Build** (⌘+B)
2. Исправьте ошибки, если есть

### 6.3 Запустите приложение
1. **Product** → **Run** (⌘+R)
2. Приложение запустится в симуляторе

## 🛠️ Устранение проблем

### Проблема: "No such module 'Firebase'"
**Решение:**
1. Проверьте, что Firebase добавлен в SPM
2. **File** → **Packages** → **Reset Package Caches**
3. **Product** → **Clean Build Folder**

### Проблема: "Missing GoogleService-Info.plist"
**Решение:**
1. Убедитесь, что файл добавлен в проект
2. Проверьте, что он в правильном таргете
3. Пересоберите проект

### Проблема: "Build failed"
**Решение:**
1. Проверьте Bundle ID
2. Убедитесь, что все файлы добавлены в таргет
3. Проверьте зависимости SPM

## 📚 Дополнительные ресурсы

- `DEVELOPER_GUIDE.md` — Полное руководство разработчика
- `FUNCTIONALITY_CHECKLIST.md` — Чек-лист функциональности
- `QUICK_START.md` — Быстрый старт

## 🎉 Готово!

После выполнения всех шагов у вас будет:
- ✅ Рабочий Xcode проект
- ✅ Все Swift файлы добавлены
- ✅ Firebase настроен
- ✅ Зависимости подключены
- ✅ Приложение готово к запуску

**Удачной разработки!** 🚀
