#!/bin/bash

echo "🚀 Создание Xcode проекта для «Саранск для Туристов»"
echo "=================================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Проверка наличия Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode не найден. Установите Xcode с App Store.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Xcode найден${NC}"

# Создание структуры проекта
PROJECT_NAME="SaranskTourist"
PROJECT_DIR="$PROJECT_NAME"

echo -e "${BLUE}📁 Создание структуры проекта...${NC}"

# Создаем основную папку проекта
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Создаем структуру папок
mkdir -p "$PROJECT_NAME/Models"
mkdir -p "$PROJECT_NAME/Services"
mkdir -p "$PROJECT_NAME/Screens"
mkdir -p "$PROJECT_NAME/Components"
mkdir -p "$PROJECT_NAME/Resources"
mkdir -p "$PROJECT_NAME/Resources/images/poi"
mkdir -p "$PROJECT_NAME/Resources/audio/poi"

echo -e "${GREEN}✅ Структура папок создана${NC}"

# Копируем Swift файлы
echo -e "${BLUE}📱 Копирование Swift файлов...${NC}"

# Копируем основные файлы
cp ../ios/App.swift "$PROJECT_NAME/"
cp ../ios/Models/*.swift "$PROJECT_NAME/Models/"
cp ../ios/Services/*.swift "$PROJECT_NAME/Services/"
cp ../ios/Screens/*.swift "$PROJECT_NAME/Screens/"
cp ../ios/Components/*.swift "$PROJECT_NAME/Components/"

echo -e "${GREEN}✅ Swift файлы скопированы${NC}"

# Копируем контентные файлы
echo -e "${BLUE}📄 Копирование контентных файлов...${NC}"
cp ../content/*.json "$PROJECT_NAME/Resources/"

echo -e "${GREEN}✅ Контентные файлы скопированы${NC}"

# Создаем Package.swift для Swift Package Manager
echo -e "${BLUE}📦 Создание Package.swift...${NC}"

cat > Package.swift << 'EOF'
// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "SaranskTourist",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SaranskTourist",
            targets: ["SaranskTourist"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "SaranskTourist",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebasePerformance", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SaranskTouristTests",
            dependencies: ["SaranskTourist"]),
    ]
)
EOF

echo -e "${GREEN}✅ Package.swift создан${NC}"

# Создаем README для проекта
echo -e "${BLUE}📚 Создание README проекта...${NC}"

cat > README.md << 'EOF'
# SaranskTourist iOS App

Нативное iOS-приложение-гид по городу Саранск.

## Быстрый запуск

1. Откройте `SaranskTourist.xcodeproj` в Xcode
2. Добавьте `GoogleService-Info.plist` в проект
3. Соберите и запустите проект

## Структура проекта

- `Models/` - Модели данных
- `Services/` - Сервисы и бизнес-логика
- `Screens/` - Экраны приложения
- `Components/` - UI компоненты
- `Resources/` - Ресурсы (JSON, изображения, аудио)

## Зависимости

- Firebase iOS SDK
- Google Sign-In
- StoreKit 2 (встроен в iOS)

## Требования

- iOS 16.0+
- Xcode 14.0+
- Swift 5.8+
EOF

echo -e "${GREEN}✅ README создан${NC}"

# Создаем .gitignore
echo -e "${BLUE}🔒 Создание .gitignore...${NC}"

cat > .gitignore << 'EOF'
# Xcode
.DS_Store
*/build/*
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata
*.xccheckout
*.moved-aside
DerivedData
.idea/
*.hmap
*.xcuserstate
*.xcworkspace
!default.xcworkspace

# CocoaPods
Pods/

# Carthage
Carthage/Build/

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/test_output

# Code Injection
iOSInjectionProject/

# Firebase
GoogleService-Info.plist

# Swift Package Manager
.build/
Packages/
Package.resolved
*.xcodeproj
EOF

echo -e "${GREEN}✅ .gitignore создан${NC}"

# Создаем инструкции по настройке
echo -e "${BLUE}📋 Создание инструкций...${NC}"

cat > SETUP_INSTRUCTIONS.md << 'EOF'
# Инструкции по настройке Xcode проекта

## 1. Создание Xcode проекта

1. Откройте Xcode
2. File → New → Project
3. iOS → App
4. Настройки:
   - Product Name: SaranskTourist
   - Team: Ваша команда
   - Organization Identifier: com.yourorg.saransk.tourist
   - Language: Swift
   - Interface: SwiftUI
   - Life Cycle: SwiftUI App

## 2. Добавление файлов

1. Правый клик на проект → Add Files to SaranskTourist
2. Выберите все файлы из папки SaranskTourist/
3. Убедитесь, что "Add to target" отмечено

## 3. Настройка зависимостей

1. File → Add Package Dependencies
2. Добавьте Firebase: https://github.com/firebase/firebase-ios-sdk
3. Добавьте Google Sign-In: https://github.com/google/GoogleSignIn-iOS

## 4. Настройка Firebase

1. Создайте проект в Firebase Console
2. Скачайте GoogleService-Info.plist
3. Добавьте файл в проект

## 5. Запуск

1. Выберите симулятор
2. Product → Run (⌘+R)

## Полезные команды

```bash
# Очистка кэша
rm -rf ~/Library/Developer/Xcode/DerivedData

# Сброс пакетов
rm -rf ~/Library/Caches/org.swift.swiftpm
```
EOF

echo -e "${GREEN}✅ Инструкции созданы${NC}"

# Создаем скрипт для быстрого запуска
echo -e "${BLUE}⚡ Создание скрипта быстрого запуска...${NC}"

cat > quick-start.sh << 'EOF'
#!/bin/bash

echo "🚀 Быстрый запуск SaranskTourist"
echo "================================"

# Проверяем наличие Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode не найден. Установите Xcode с App Store."
    exit 1
fi

echo "✅ Xcode найден"

# Проверяем наличие проекта
if [ ! -f "SaranskTourist.xcodeproj/project.pbxproj" ]; then
    echo "⚠️ Xcode проект не найден"
    echo "📋 Следуйте инструкциям в SETUP_INSTRUCTIONS.md"
    echo "🔗 Или откройте Xcode и создайте проект вручную"
    exit 1
fi

echo "✅ Xcode проект найден"

# Открываем проект в Xcode
echo "📱 Открытие проекта в Xcode..."
open SaranskTourist.xcodeproj

echo "🎉 Проект открыт в Xcode!"
echo "📋 Следующие шаги:"
echo "1. Добавьте GoogleService-Info.plist"
echo "2. Настройте зависимости в SPM"
echo "3. Выберите симулятор"
echo "4. Product → Run (⌘+R)"
EOF

chmod +x quick-start.sh

echo -e "${GREEN}✅ Скрипт быстрого запуска создан${NC}"

# Итоговая статистика
echo -e "${BLUE}📊 Статистика созданного проекта:${NC}"

SWIFT_COUNT=$(find "$PROJECT_NAME" -name "*.swift" | wc -l)
JSON_COUNT=$(find "$PROJECT_NAME" -name "*.json" | wc -l)

echo "Swift файлов: $SWIFT_COUNT"
echo "JSON файлов: $JSON_COUNT"
echo "Папок создано: 6"

echo ""
echo -e "${GREEN}🎉 Проект успешно создан!${NC}"
echo ""
echo -e "${YELLOW}📋 Следующие шаги:${NC}"
echo "1. Откройте Xcode"
echo "2. File → New → Project"
echo "3. Создайте iOS App проект"
echo "4. Добавьте файлы из папки $PROJECT_DIR"
echo "5. Настройте зависимости (см. SETUP_INSTRUCTIONS.md)"
echo "6. Добавьте GoogleService-Info.plist"
echo "7. Запустите проект"
echo ""
echo -e "${BLUE}📚 Документация:${NC}"
echo "- SETUP_INSTRUCTIONS.md - Подробные инструкции"
echo "- README.md - Описание проекта"
echo "- quick-start.sh - Скрипт быстрого запуска"
echo ""
echo -e "${GREEN}🚀 Удачной разработки!${NC}"