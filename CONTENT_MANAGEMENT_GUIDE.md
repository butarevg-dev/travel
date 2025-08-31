# 📚 Руководство по управлению контентом POI и аудиогидам

## 🎯 Обзор системы

Система управления контентом позволяет добавлять, редактировать и удалять достопримечательности (POI) с поддержкой изображений и аудиогидов.

### 📁 Структура файлов

```
ios/
├── Services/
│   ├── ContentManagementService.swift    ← Управление контентом
│   ├── AudioPlayerService.swift          ← Воспроизведение аудио
│   ├── AudioCacheManager.swift           ← Кэширование аудио
│   └── FirestoreService.swift            ← База данных
├── Screens/
│   └── ContentManagementScreen.swift     ← UI управления контентом
└── Models/
    └── POI.swift                         ← Модель данных POI

content/
├── poi.json                              ← Локальные данные POI
└── routes.json                           ← Локальные маршруты
```

## 🚀 Как добавить информацию для POI

### 1. 📱 Через приложение (рекомендуется)

#### **Шаг 1: Открыть экран управления контентом**
```swift
// В любом экране приложения
@State private var showingContentManagement = false

Button("Управление контентом") {
    showingContentManagement = true
}
.sheet(isPresented: $showingContentManagement) {
    ContentManagementScreen()
}
```

#### **Шаг 2: Добавить новый POI**
1. Нажать кнопку **"Добавить POI"**
2. Заполнить основную информацию:
   - **Название** — название достопримечательности
   - **Описание** — подробное описание
   - **Адрес** — точный адрес
   - **Категория** — выбрать из списка (Музеи, Храмы, Парки и т.д.)
   - **Координаты** — широта и долгота

#### **Шаг 3: Добавить изображения**
1. Нажать **"Добавить изображение"**
2. Выбрать фото из галереи (до 5 изображений)
3. Поддерживаемые форматы: JPG, PNG, HEIC
4. Максимальный размер: 10MB

#### **Шаг 4: Добавить аудиогид**
1. Нажать **"Добавить аудиофайл"**
2. Выбрать аудиофайл из файловой системы
3. Поддерживаемые форматы: M4A, MP3, WAV, AAC
4. Максимальный размер: 50MB

#### **Шаг 5: Сохранить POI**
1. Проверить валидацию (исправить ошибки если есть)
2. Нажать **"Сохранить POI"**
3. Дождаться загрузки файлов в Firebase

### 2. 📄 Через JSON файлы (для разработчиков)

#### **Структура POI в JSON:**
```json
{
  "id": "poi-saransk-kremlin",
  "name": "Соборная площадь",
  "description": "Главная площадь города с историческими зданиями...",
  "address": "Саранск, Соборная площадь",
  "category": "архитектура",
  "imageUrl": "https://firebase-storage.com/images/sobornaya.jpg",
  "audioUrl": "https://firebase-storage.com/audio/sobornaya.m4a",
  "latitude": 54.1834,
  "longitude": 45.1749,
  "rating": 4.7,
  "distance": 0.0,
  "popularity": 100,
  "workingHours": "ежедневно 08:00–20:00",
  "price": null,
  "phone": null,
  "website": null,
  "tags": ["топ-место", "семейный"],
  "isFavorite": false
}
```

#### **Обновление локального файла:**
```bash
# Отредактировать content/poi.json
# Добавить новый POI в массив items
# Сохранить файл
```

## 🎵 Как загружать файлы для аудиогида

### 1. 📱 Через приложение

#### **Поддерживаемые форматы:**
- ✅ **M4A** — рекомендуемый формат (лучшее качество/размер)
- ✅ **MP3** — универсальный формат
- ✅ **WAV** — несжатый аудио
- ✅ **AAC** — альтернативный формат

#### **Требования к аудиофайлам:**
- 📏 **Размер:** максимум 50MB
- ⏱️ **Длительность:** рекомендуется 2-5 минут
- 🎤 **Качество:** 44.1kHz, 128-256 kbps
- 🗣️ **Язык:** русский (для русскоязычного контента)

#### **Процесс загрузки:**
1. **Выбор файла** — через DocumentPicker
2. **Валидация** — проверка формата и размера
3. **Предпрослушивание** — встроенный аудиоплеер
4. **Загрузка** — автоматическая загрузка в Firebase Storage
5. **Связывание** — привязка к POI в Firestore

### 2. 🔧 Программная загрузка

#### **Загрузка через ContentManagementService:**
```swift
let contentService = ContentManagementService.shared

// Загрузить аудиофайл
let audioURL = try await contentService.uploadAudioGuide(
    poiId: "poi-saransk-kremlin",
    audioURL: localAudioURL,
    title: "Аудиогид: Соборная площадь"
)

// Обновить POI с аудиофайлом
var poi = existingPOI
poi.audioUrl = audioURL
try await contentService.updatePOI(poi)
```

#### **Пакетная загрузка контента:**
```swift
// Загрузить POI с изображениями и аудио
try await contentService.uploadPOIContent(
    poi: newPOI,
    images: [imageURL1, imageURL2],
    audioURL: audioURL
)
```

### 3. 📁 Ручная загрузка в Firebase

#### **Firebase Storage структура:**
```
firebase-storage/
├── audio/
│   └── poi/
│       ├── poi-saransk-kremlin_audio1.m4a
│       └── poi-museum_audio1.m4a
└── images/
    └── poi/
        ├── poi-saransk-kremlin_image1.jpg
        └── poi-museum_image1.jpg
```

#### **Метаданные аудиофайла:**
```json
{
  "contentType": "audio/mp4",
  "customMetadata": {
    "poiId": "poi-saransk-kremlin",
    "title": "Аудиогид: Соборная площадь",
    "uploadedAt": "2025-08-31T10:00:00Z"
  }
}
```

## 🔄 Синхронизация контента

### 1. 🔄 Автоматическая синхронизация

#### **Firestore → Приложение:**
- ✅ Автоматическая загрузка при запуске
- ✅ Обновление в реальном времени
- ✅ Кэширование для оффлайн режима

#### **Локальный → Firebase:**
```swift
// Синхронизировать локальный контент с Firebase
try await contentService.syncLocalContent()
```

### 2. 📤 Экспорт контента

#### **Экспорт в JSON:**
```swift
// Экспортировать все данные
let exportData = try await contentService.exportContent()

// Сохранить в файл
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let exportURL = documentsPath.appendingPathComponent("export.json")
try exportData.write(to: exportURL)
```

## ✅ Валидация контента

### 1. 📋 Валидация POI

#### **Обязательные поля:**
- ✅ **Название** — не пустое
- ✅ **Описание** — не пустое
- ✅ **Адрес** — не пустой
- ✅ **Координаты** — валидные значения
- ✅ **Категория** — из списка разрешенных

#### **Проверка координат:**
```swift
// Валидация координат Саранска
let saranskLatRange = 54.0...54.5
let saranskLngRange = 45.0...45.5

if !saranskLatRange.contains(latitude) || !saranskLngRange.contains(longitude) {
    errors.append("Координаты должны быть в пределах Саранска")
}
```

### 2. 🎵 Валидация аудиофайлов

#### **Проверки:**
- ✅ **Размер файла** — максимум 50MB
- ✅ **Формат файла** — поддерживаемые расширения
- ✅ **Доступность** — файл можно открыть
- ✅ **Длительность** — не слишком длинный

#### **Код валидации:**
```swift
func validateAudioFile(_ url: URL) -> [String] {
    var errors: [String] = []
    
    // Проверить размер
    if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
       fileSize > 50 * 1024 * 1024 {
        errors.append("Размер аудиофайла не должен превышать 50MB")
    }
    
    // Проверить формат
    let allowedExtensions = ["m4a", "mp3", "wav", "aac"]
    let fileExtension = url.pathExtension.lowercased()
    if !allowedExtensions.contains(fileExtension) {
        errors.append("Поддерживаются только форматы: \(allowedExtensions.joined(separator: ", "))")
    }
    
    return errors
}
```

### 3. 🖼️ Валидация изображений

#### **Проверки:**
- ✅ **Размер файла** — максимум 10MB
- ✅ **Формат файла** — JPG, PNG, HEIC
- ✅ **Разрешение** — минимум 300x300 пикселей
- ✅ **Соотношение сторон** — рекомендуется 16:9 или 4:3

## 🎧 Воспроизведение аудиогидов

### 1. 📱 В приложении

#### **Автоматическое воспроизведение:**
```swift
// При посещении POI
if !poi.audioUrl.isEmpty {
    audioPlayer.loadAudio(from: URL(string: poi.audioUrl)!, title: poi.name, poiId: poi.id)
    audioPlayer.play()
}
```

#### **Ручное воспроизведение:**
```swift
// В детальном экране POI
Button("Слушать аудиогид") {
    if let audioURL = URL(string: poi.audioUrl) {
        audioPlayer.loadAudio(from: audioURL, title: "Аудиогид: \(poi.name)", poiId: poi.id)
        audioPlayer.play()
    }
}
```

### 2. 🔄 Кэширование аудио

#### **Автоматическое кэширование:**
- ✅ Скачивание при первом воспроизведении
- ✅ Сохранение в локальном хранилище
- ✅ Воспроизведение без интернета

#### **Управление кэшем:**
```swift
let cacheManager = AudioCacheManager.shared

// Скачать аудио для оффлайн режима
cacheManager.downloadAudio(from: audioURL) { result in
    switch result {
    case .success(let localURL):
        print("Аудио скачано: \(localURL)")
    case .failure(let error):
        print("Ошибка скачивания: \(error)")
    }
}

// Очистить кэш
cacheManager.clearCache()
```

## 📊 Статистика контента

### 1. 📈 Метрики

#### **Основные показатели:**
- 📍 **Всего POI** — количество достопримечательностей
- 🎵 **С аудио** — POI с аудиогидами
- 🖼️ **С изображениями** — POI с фото
- 📱 **Версия контента** — текущая версия

#### **Дополнительные метрики:**
- 👥 **Популярные POI** — по количеству посещений
- ⭐ **Рейтинг** — средний рейтинг
- 🗺️ **Покрытие** — по районам города
- 📅 **Обновления** — частота обновления контента

### 2. 📊 Аналитика

#### **Firebase Analytics события:**
```swift
// Отслеживание воспроизведения аудио
Analytics.logEvent("audio_play", parameters: [
    "poi_id": poi.id,
    "poi_name": poi.name,
    "audio_duration": audioPlayer.duration,
    "playback_position": audioPlayer.currentTime
])

// Отслеживание добавления POI
Analytics.logEvent("poi_added", parameters: [
    "poi_id": poi.id,
    "poi_category": poi.category,
    "has_audio": !poi.audioUrl.isEmpty,
    "has_images": !poi.imageUrl.isEmpty
])
```

## 🛠️ Технические детали

### 1. 🔧 Архитектура

#### **MVVM паттерн:**
- **Model** — `POI`, `AudioTrack`
- **View** — `ContentManagementScreen`, `AddPOIScreen`
- **ViewModel** — `ContentManagementViewModel`, `AddPOIViewModel`

#### **Сервисы:**
- **ContentManagementService** — управление контентом
- **AudioPlayerService** — воспроизведение аудио
- **AudioCacheManager** — кэширование
- **FirestoreService** — база данных

### 2. 🔄 Поток данных

```
Пользователь → UI → ViewModel → Service → Firebase
     ↑                                    ↓
     ← UI ← ViewModel ← Service ← Firebase ←
```

### 3. 📱 Адаптивность

#### **Поддержка устройств:**
- ✅ **iPhone** — Portrait и Landscape
- ✅ **iPad** — Portrait и Landscape
- ✅ **Разные размеры экранов**
- ✅ **Динамический тип**

#### **Оффлайн режим:**
- ✅ **Кэширование аудио** — локальное хранение
- ✅ **Локальные данные** — JSON файлы
- ✅ **Синхронизация** — при подключении к интернету

## 🚀 Рекомендации

### 1. 📝 Создание контента

#### **Для POI:**
- ✍️ **Описание** — 100-300 слов, интересное и информативное
- 📍 **Адрес** — точный адрес с номером дома
- 🏷️ **Категория** — правильная категоризация
- 🏷️ **Теги** — релевантные теги для поиска

#### **Для аудиогидов:**
- ⏱️ **Длительность** — 2-5 минут оптимально
- 🗣️ **Диктор** — профессиональный голос
- 🎵 **Музыка** — фоновая музыка (опционально)
- 📝 **Сценарий** — структурированный текст

### 2. 🖼️ Изображения

#### **Требования:**
- 📐 **Разрешение** — минимум 1200x800 пикселей
- 📷 **Качество** — высокое качество, без размытия
- 🎨 **Композиция** — интересные ракурсы
- 🌅 **Освещение** — хорошее освещение

### 3. 🎵 Аудио

#### **Рекомендации:**
- 🎤 **Запись** — в тихом помещении
- 🎧 **Мониторинг** — наушники для контроля
- 📊 **Уровень** — нормализованный уровень громкости
- 🔄 **Тестирование** — на разных устройствах

## 🔧 Устранение неполадок

### 1. ❌ Ошибки загрузки

#### **Проблема:** Файл не загружается
**Решение:**
- Проверить размер файла
- Проверить формат файла
- Проверить подключение к интернету
- Перезапустить приложение

#### **Проблема:** Аудио не воспроизводится
**Решение:**
- Проверить URL аудиофайла
- Проверить формат файла
- Очистить кэш аудио
- Перезагрузить аудиофайл

### 2. 🔄 Проблемы синхронизации

#### **Проблема:** Данные не синхронизируются
**Решение:**
- Проверить подключение к Firebase
- Проверить права доступа
- Принудительная синхронизация
- Очистить кэш приложения

### 3. 📱 Проблемы UI

#### **Проблема:** Экран не отображается корректно
**Решение:**
- Проверить размер экрана
- Перезапустить приложение
- Обновить до последней версии
- Очистить кэш

## 📞 Поддержка

### 🔗 Полезные ссылки:
- 📚 [Firebase Documentation](https://firebase.google.com/docs)
- 🎵 [AVFoundation Guide](https://developer.apple.com/documentation/avfoundation)
- 📱 [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

### 📧 Контакты:
- 🐛 **Баги и ошибки** — создайте Issue в репозитории
- 💡 **Предложения** — обсудите в Discussions
- 📧 **Поддержка** — свяжитесь с командой разработки

---

**🎉 Теперь вы готовы управлять контентом POI и создавать качественные аудиогиды для приложения "Саранск для туристов"!**