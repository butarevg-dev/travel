# 🚀 **GitHub Codespaces Setup Guide**

## ⚠️ **ВАЖНО: Правильная настройка Codespaces**

### **Проблема:**
GitHub Codespaces по умолчанию клонирует ветку `main`, но наш проект находится в ветке `cursor/investigate-expired-development-agent-status-b61b`.

### **Решение:**

#### **1. Переключение на правильную ветку**
```bash
# В терминале Codespaces выполните:
git fetch origin
git checkout cursor/investigate-expired-development-agent-status-b61b
```

#### **2. Проверка структуры проекта**
```bash
# Убедитесь, что файлы на месте
ls -la
ls -la ios/
ls -la content/
```

#### **3. Запуск проверки проекта**
```bash
# Теперь скрипт должен работать
./check-project.sh
```

---

## 🔧 **Альтернативные способы запуска Codespaces**

### **Способ 1: Прямая ссылка на ветку**
```
https://github.com/butarevg-dev/travel/tree/cursor/investigate-expired-development-agent-status-b61b
```

### **Способ 2: Создание Codespace с правильной веткой**
1. Перейдите в репозиторий
2. Нажмите **"Code"** → **"Codespaces"**
3. В выпадающем списке выберите ветку: `cursor/investigate-expired-development-agent-status-b61b`
4. Нажмите **"Create codespace on cursor/investigate-expired-development-agent-status-b61b"**

### **Способ 3: Через GitHub CLI**
```bash
gh codespace create --repo butarevg-dev/travel --branch cursor/investigate-expired-development-agent-status-b61b
```

---

## 📋 **Команды для проверки в Codespaces**

### **После правильного переключения ветки:**

```bash
# 1. Проверка структуры
./check-project.sh

# 2. Подсчет Swift файлов
find ios/ -name "*.swift" | wc -l

# 3. Подсчет документации
find . -name "*.md" | wc -l

# 4. Проверка контентных файлов
ls -la content/
python3 -m json.tool content/poi.json

# 5. Проверка iOS структуры
ls -la ios/
ls -la ios/Services/
ls -la ios/Screens/
ls -la ios/Models/

# 6. Проверка конфигурации
ls -la .devcontainer/
ls -la .github/workflows/
```

---

## 🎯 **Ожидаемые результаты**

### **При правильной настройке вы должны увидеть:**

```bash
$ ./check-project.sh
🚀 Проверка проекта «Саранск для Туристов»
==========================================

📁 Проверка структуры проекта:
-----------------------------
✅ ios/App.swift
✅ ios/Models/Models.swift
✅ ios/Services/FirestoreService.swift
✅ ios/Screens/MapScreen.swift

📱 Подсчет Swift файлов:
📊 ios: 44 файлов

📚 Подсчет документации:
📊 .: 32 файлов

📄 Проверка контентных файлов:
✅ content/poi.json
✅ content/routes.json

🎉 Итоговая оценка:
------------------
✅ Swift файлов достаточно (44)
✅ Документации достаточно (32)
✅ Сервисов достаточно (19)
✅ Экранов достаточно (10)

🚀 Проект готов к разработке!
```

---

## 🔍 **Диагностика проблем**

### **Если файлы отсутствуют:**
```bash
# Проверьте текущую ветку
git branch

# Проверьте удаленные ветки
git branch -a

# Переключитесь на правильную ветку
git checkout cursor/investigate-expired-development-agent-status-b61b

# Обновите файлы
git pull origin cursor/investigate-expired-development-agent-status-b61b
```

### **Если скрипт не выполняется:**
```bash
# Проверьте права доступа
ls -la check-project.sh

# Сделайте скрипт исполняемым
chmod +x check-project.sh

# Запустите скрипт
./check-project.sh
```

---

## 📚 **Дополнительные ресурсы**

### **Документация проекта:**
- `DEVELOPER_GUIDE.md` — Полное руководство разработчика
- `FUNCTIONALITY_CHECKLIST.md` — Чек-лист функциональности
- `README.md` — Краткое описание проекта

### **Настройка разработки:**
- `QUICK_START.md` — Быстрый запуск
- `IOS_SETUP.md` — Настройка iOS проекта
- `XCODE_SETUP_GUIDE.md` — Настройка Xcode

---

## 🎉 **Успешная настройка**

После правильного переключения ветки вы сможете:
- ✅ Запускать проверки проекта
- ✅ Изучать код и документацию
- ✅ Тестировать функциональность
- ✅ Работать с проектом в браузере

**Проект полностью готов к разработке!** 🚀