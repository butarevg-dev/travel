# 📥 **ИНСТРУКЦИИ ПО СКАЧИВАНИЮ ФАЙЛОВ ДЛЯ XCODE**

## 🚀 **БЫСТРЫЙ СПОСОБ СКАЧИВАНИЯ**

### **Вариант 1: Скачивание ZIP архива**

1. **Перейдите в репозиторий на GitHub:**
   ```
   https://github.com/butarevg-dev/travel
   ```

2. **Переключитесь на правильную ветку:**
   - Нажмите на выпадающий список веток
   - Выберите: `cursor/investigate-expired-development-agent-status-b61b`

3. **Скачайте ZIP архив:**
   - Нажмите зеленую кнопку **"Code"**
   - Выберите **"Download ZIP"**
   - Распакуйте архив на ваш компьютер

4. **Найдите папку с файлами:**
   - В распакованном архиве найдите папку `SaranskTourist/`
   - Эта папка содержит все готовые файлы для Xcode

### **Вариант 2: Клонирование репозитория**

```bash
# Клонируйте репозиторий
git clone https://github.com/butarevg-dev/travel.git

# Переключитесь на нужную ветку
cd travel
git checkout cursor/investigate-expired-development-agent-status-b61b

# Запустите скрипт подготовки
./setup-xcode-project.sh
```

### **Вариант 3: GitHub Codespaces (рекомендуется)**

1. **Откройте репозиторий в Codespaces:**
   - Перейдите на https://github.com/butarevg-dev/travel
   - Нажмите **"Code"** → **"Codespaces"**
   - Выберите ветку: `cursor/investigate-expired-development-agent-status-b61b`
   - Нажмите **"Create codespace"**

2. **В терминале Codespaces выполните:**
   ```bash
   ./setup-xcode-project.sh
   ```

3. **Скачайте готовые файлы:**
   - В Codespaces найдите папку `SaranskTourist/`
   - Скачайте её на ваш компьютер

---

## 📁 **СТРУКТУРА СКАЧИВАЕМЫХ ФАЙЛОВ**

После выполнения скрипта у вас будет:

```
SaranskTourist/
├── SaranskTourist/           # Основная папка с файлами
│   ├── App.swift            # Точка входа приложения
│   ├── Models/              # Модели данных (4 файла)
│   ├── Services/            # Сервисы (19 файлов)
│   ├── Screens/             # Экраны (10 файлов)
│   ├── Components/          # UI компоненты (2 файла)
│   └── Resources/           # Ресурсы
│       ├── poi.json         # Данные POI
│       └── routes.json      # Данные маршрутов
├── XCODE_SETUP_GUIDE.md     # Подробные инструкции
├── README.md                # Описание проекта
└── .gitignore              # Исключения для Git
```

**Всего файлов:**
- ✅ **36 Swift файлов** (модели, сервисы, экраны)
- ✅ **2 JSON файла** (контент)
- ✅ **3 документа** (инструкции)

---

## 🎯 **СЛЕДУЮЩИЕ ШАГИ ПОСЛЕ СКАЧИВАНИЯ**

### **1. Создание Xcode проекта:**
1. Откройте Xcode
2. File → New → Project
3. iOS → App
4. Настройки:
   ```
   Product Name: SaranskTourist
   Team: Ваша команда
   Organization Identifier: com.yourorg.saransk.tourist
   Language: Swift
   Interface: SwiftUI
   ```

### **2. Добавление файлов:**
1. Правый клик на проект → "Add Files to SaranskTourist"
2. Выберите папку `SaranskTourist/SaranskTourist/`
3. Убедитесь, что "Add to target" отмечено
4. Нажмите "Add"

### **3. Настройка зависимостей:**
1. File → Add Package Dependencies
2. Добавьте Firebase: `https://github.com/firebase/firebase-ios-sdk`
3. Добавьте Google Sign-In: `https://github.com/google/GoogleSignIn-iOS`

### **4. Настройка Firebase:**
1. Создайте проект в [Firebase Console](https://console.firebase.google.com/)
2. Скачайте `GoogleService-Info.plist`
3. Добавьте файл в проект

### **5. Запуск:**
1. Выберите симулятор
2. Product → Run (⌘+R)

---

## 📚 **ДОКУМЕНТАЦИЯ**

### **В скачанных файлах:**
- **`XCODE_SETUP_GUIDE.md`** — Подробные инструкции по настройке
- **`README.md`** — Описание проекта

### **В основном репозитории:**
- **`DEVELOPER_GUIDE.md`** — Полное руководство разработчика
- **`FUNCTIONALITY_CHECKLIST.md`** — Чек-лист функциональности
- **`CODESPACES_SETUP.md`** — Настройка Codespaces

---

## 🛠️ **УСТРАНЕНИЕ ПРОБЛЕМ**

### **Проблема: "Файлы не найдены"**
**Решение:**
```bash
# Убедитесь, что вы на правильной ветке
git branch
# Должно показать: cursor/investigate-expired-development-agent-status-b61b

# Если нет, переключитесь:
git checkout cursor/investigate-expired-development-agent-status-b61b
```

### **Проблема: "Скрипт не выполняется"**
**Решение:**
```bash
# Сделайте скрипт исполняемым
chmod +x setup-xcode-project.sh

# Запустите скрипт
./setup-xcode-project.sh
```

### **Проблема: "Файлы повреждены"**
**Решение:**
1. Удалите папку `SaranskTourist/`
2. Запустите скрипт заново: `./setup-xcode-project.sh`
3. Проверьте, что все файлы на месте

---

## 🎉 **ГОТОВО!**

После скачивания и настройки у вас будет:
- ✅ **Полностью функциональное iOS приложение**
- ✅ **Все 36 Swift файлов** готовы к использованию
- ✅ **Подробные инструкции** по настройке
- ✅ **Готовность к разработке** и релизу

**Удачной разработки!** 🚀