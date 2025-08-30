# Xcode Setup Guide для проверки работы

## 1. Создание Xcode проекта

1. Откройте Xcode
2. File → New → Project
3. Выберите "iOS" → "App"
4. Настройки:
   - Product Name: `SaranskTourist`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Minimum Deployment: `iOS 16.0`

## 2. Добавление файлов

### Скопируйте все файлы из `/workspace/ios/` в Xcode проект:
- `App.swift` → замените существующий
- `Screens/` → добавьте как группу
- `Services/` → добавьте как группу  
- `Models/` → добавьте как группу
- `Auth/` → добавьте как группу
- `Map/` → добавьте как группу

### Добавьте контент:
- `content/` → добавьте как группу (убедитесь что "Add to target" включено)

## 3. Настройка SPM зависимостей

### Добавьте пакеты (Project → Package Dependencies):

1. **Firebase iOS SDK**
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Products: `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`

2. **Google Sign-In**
   - URL: `https://github.com/google/GoogleSignIn-iOS`
   - Product: `GoogleSignIn`

3. **VK iOS SDK** (опционально)
   - URL: `https://github.com/VKCOM/vk-ios-sdk`
   - Product: `VKIOSSDK`

## 4. Настройка Bundle ID

- Project → Target → General
- Bundle Identifier: `com.yourorg.saransk.tourist`

## 5. Добавление Firebase (опционально)

1. Создайте проект в [Firebase Console](https://console.firebase.google.com/)
2. Добавьте iOS приложение с вашим Bundle ID
3. Скачайте `GoogleService-Info.plist`
4. Добавьте файл в корень проекта (Add to target)

## 6. Запуск и тестирование

### Что можно проверить:

1. **Карта** - отображение POI, фильтры, режим "Рядом"
2. **Каталог POI** - список, поиск, детали, избранное
3. **Маршруты** - список, детали, ETA расчет
4. **Профиль** - оффлайн-менеджер, настройки

### Ожидаемое поведение:
- ✅ Приложение запускается без ошибок
- ✅ Все экраны отображаются корректно
- ✅ Навигация между табами работает
- ✅ Данные загружаются из локальных JSON файлов
- ✅ Карта показывает POI и маршруты
- ✅ Оффлайн-менеджер работает

## 7. Возможные проблемы и решения

### Ошибка компиляции:
- Проверьте импорты Firebase
- Убедитесь что все файлы добавлены в target
- Проверьте iOS версию (16.0+)

### Пустая карта:
- Проверьте что `content/poi.json` добавлен в bundle
- Проверьте координаты в JSON файлах

### Ошибки Firebase:
- Приложение работает без Firebase (mock-first подход)
- Firebase нужен только для полной функциональности

## 8. Следующие шаги

После успешного запуска:
1. Создайте GitHub репозиторий
2. Загрузите код
3. Настройте CodeRabbit для анализа
4. Переходите к Этапу 2 (Аудиогиды)