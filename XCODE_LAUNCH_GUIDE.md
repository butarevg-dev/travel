# 🚀 **РУКОВОДСТВО ПО ЗАПУСКУ В XCODE**

## ⚠️ **ВАЖНО: Создание Xcode проекта**

У нас есть **все Swift файлы**, но нет **Xcode проекта**. Нужно создать проект и добавить файлы.

---

## 📱 **ШАГ 1: Создание нового Xcode проекта**

### **1.1 Откройте Xcode**
- Запустите Xcode на вашем Mac
- Выберите **"Create a new Xcode project"**

### **1.2 Выберите тип проекта**
- **iOS** → **App**
- Нажмите **"Next"**

### **1.3 Настройте проект**
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

### **1.4 Выберите расположение**
- Сохраните проект в папку рядом с текущим проектом
- Например: `~/Desktop/SaranskTourist/`

---

## 📁 **ШАГ 2: Добавление файлов в проект**

### **2.1 Скопируйте Swift файлы**
```bash
# В терминале выполните:
cd ~/Desktop/SaranskTourist/  # или где вы создали проект

# Создайте папки
mkdir -p ios/Models ios/Services ios/Screens ios/Components

# Скопируйте файлы из нашего проекта
cp -r /path/to/our/project/ios/* ios/
```

### **2.2 Добавьте файлы в Xcode**
1. **Правый клик** на папку проекта в Xcode
2. **"Add Files to SaranskTourist"**
3. Выберите все файлы из папки `ios/`
4. Убедитесь, что **"Add to target"** отмечено
5. Нажмите **"Add"**

### **2.3 Создайте группы в Xcode**
Создайте группы для организации файлов:
- **Models** (для файлов моделей)
- **Services** (для сервисов)
- **Screens** (для экранов)
- **Components** (для UI компонентов)

---

## 🔧 **ШАГ 3: Настройка зависимостей (Swift Package Manager)**

### **3.1 Добавьте Firebase**
1. **File** → **Add Package Dependencies**
2. Введите URL: `https://github.com/firebase/firebase-ios-sdk`
3. Выберите версию: `10.0.0` или новее
4. Выберите продукты:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseAnalytics
   - FirebaseCrashlytics
   - FirebasePerformance

### **3.2 Добавьте Google Sign-In**
1. **File** → **Add Package Dependencies**
2. URL: `https://github.com/google/GoogleSignIn-iOS`
3. Версия: `7.0.0` или новее

### **3.3 Добавьте StoreKit 2 (встроен в iOS)**
- StoreKit 2 уже доступен в iOS 15+

---

## 📄 **ШАГ 4: Добавление контентных файлов**

### **4.1 Создайте папку Resources**
1. **Правый клик** на проект
2. **"New Group"** → назовите **"Resources"**

### **4.2 Добавьте JSON файлы**
1. Скопируйте `content/poi.json` и `content/routes.json`
2. Добавьте в группу **Resources**
3. Убедитесь, что **"Add to target"** отмечено

### **4.3 Добавьте медиа файлы**
1. Создайте папки `images/poi` и `audio/poi`
2. Добавьте изображения и аудио файлы
3. Убедитесь, что **"Add to target"** отмечено

---

## ⚙️ **ШАГ 5: Настройка Firebase**

### **5.1 Создайте проект Firebase**
1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Создайте новый проект: **"SaranskTourist"**
3. Добавьте iOS приложение
4. Bundle ID: `com.yourorg.saransk.tourist`

### **5.2 Скачайте GoogleService-Info.plist**
1. Скачайте файл из Firebase Console
2. Добавьте в корень проекта в Xcode
3. Убедитесь, что **"Add to target"** отмечено

### **5.3 Настройте Firebase в коде**
В `App.swift` уже есть код инициализации:
```swift
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct SaranskTouristApp: App {
    init() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
    }
    // ...
}
```

---

## 🎯 **ШАГ 6: Настройка таргетов и возможностей**

### **6.1 Настройте Bundle ID**
1. Выберите проект в навигаторе
2. Выберите таргет **SaranskTourist**
3. В **"General"** проверьте Bundle Identifier

### **6.2 Добавьте возможности**
В **"Signing & Capabilities"**:
1. **Sign in with Apple** ✅
2. **Push Notifications** ✅ (опционально)
3. **Background Modes** → **Audio, AirPlay, and Picture in Picture** ✅

### **6.3 Настройте URL Schemes**
В **"Info"** → **"URL Types"**:
1. Добавьте URL Type для Google Sign-In
2. URL Scheme: `com.googleusercontent.apps.YOUR_CLIENT_ID`

---

## 🚀 **ШАГ 7: Запуск проекта**

### **7.1 Выберите симулятор**
1. В верхней части Xcode выберите симулятор
2. Рекомендуется: **iPhone 14** или **iPhone 15**

### **7.2 Соберите проект**
1. **Product** → **Build** (⌘+B)
2. Исправьте ошибки, если есть

### **7.3 Запустите приложение**
1. **Product** → **Run** (⌘+R)
2. Приложение запустится в симуляторе

---

## 🔍 **ШАГ 8: Проверка функциональности**

### **8.1 Проверьте основные экраны**
- ✅ Главная карта
- ✅ Каталог POI
- ✅ Маршруты
- ✅ Профиль
- ✅ Геймификация
- ✅ AR экран
- ✅ Премиум функции

### **8.2 Проверьте функции**
- ✅ Аудио плеер
- ✅ Фильтры POI
- ✅ Поиск
- ✅ Навигация

---

## 🛠️ **УСТРАНЕНИЕ ПРОБЛЕМ**

### **Проблема: "No such module 'Firebase'"`
**Решение:**
1. Проверьте, что Firebase добавлен в SPM
2. **File** → **Packages** → **Reset Package Caches**
3. **Product** → **Clean Build Folder**

### **Проблема: "Missing GoogleService-Info.plist"`
**Решение:**
1. Убедитесь, что файл добавлен в проект
2. Проверьте, что он в правильном таргете
3. Пересоберите проект

### **Проблема: "Build failed"`
**Решение:**
1. Проверьте Bundle ID
2. Убедитесь, что все файлы добавлены в таргет
3. Проверьте зависимости SPM

---

## 📚 **ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ**

### **Документация:**
- `QUICK_START.md` — Быстрый старт
- `IOS_SETUP.md` — Настройка iOS
- `SPM_DEPENDENCIES.md` — Зависимости
- `FUNCTIONALITY_CHECKLIST.md` — Чек-лист

### **Полезные команды:**
```bash
# Очистка кэша Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData

# Сброс пакетов SPM
rm -rf ~/Library/Caches/org.swift.swiftpm
```

---

## 🎉 **ГОТОВО!**

После выполнения всех шагов у вас будет:
- ✅ Рабочий Xcode проект
- ✅ Все Swift файлы добавлены
- ✅ Firebase настроен
- ✅ Зависимости подключены
- ✅ Приложение готово к запуску

**Удачной разработки!** 🚀