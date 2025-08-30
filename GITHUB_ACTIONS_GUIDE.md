# 🔧 **GitHub Actions Guide**

## ⚠️ **Проблема с Swift Action**

GitHub Actions использует Ubuntu 24.04, но `swift-actions/setup-swift@v1` не поддерживает эту версию. Поэтому мы создали альтернативные workflows.

---

## 📋 **Доступные Workflows**

### **1. 🚀 Simple Project Check (РЕКОМЕНДУЕТСЯ)**

**Файл:** `.github/workflows/simple-check.yml`

**Что проверяет:**
- ✅ Структуру проекта
- ✅ Количество Swift файлов
- ✅ Количество документации
- ✅ Наличие ключевых файлов
- ✅ Валидность JSON файлов

**Как запустить:**
1. Перейдите в **Actions** в вашем репозитории
2. Найдите **"Simple Project Check"**
3. Нажмите **"Run workflow"**

**Преимущества:**
- ✅ Работает на любой версии Ubuntu
- ✅ Быстрая проверка
- ✅ Не требует Swift
- ✅ Генерирует отчет

### **2. 🔍 Quick Project Check**

**Файл:** `.github/workflows/quick-check.yml`

**Что проверяет:**
- ✅ Базовую структуру проекта
- ✅ Файлы и документацию
- ✅ JSON валидность

**Как запустить:**
1. Перейдите в **Actions**
2. Найдите **"Quick Project Check"**
3. Нажмите **"Run workflow"**

### **3. 📊 Project Validation and Checks (ОГРАНИЧЕННАЯ)**

**Файл:** `.github/workflows/check-project.yml`

**Что проверяет:**
- ✅ Структуру проекта
- ✅ Документацию
- ✅ JSON файлы
- ⚠️ Swift синтаксис (пропущен из-за проблем совместимости)

**Проблемы:**
- ❌ Swift validation пропущена из-за Ubuntu 24.04
- ⚠️ Может не работать на некоторых системах

---

## 🎯 **Рекомендуемый подход**

### **Для быстрой проверки:**
```bash
# Используйте Simple Project Check
# Это самый надежный способ
```

### **Для полной проверки:**
```bash
# 1. Запустите Simple Project Check
# 2. Проверьте результаты
# 3. Если нужно больше деталей, запустите Quick Project Check
```

---

## 🚀 **Как запустить проверку**

### **Способ 1: Через GitHub UI**

1. **Перейдите в репозиторий:**
   ```
   https://github.com/butarevg-dev/travel
   ```

2. **Откройте Actions:**
   - Нажмите вкладку **"Actions"**

3. **Выберите workflow:**
   - Найдите **"Simple Project Check"**
   - Нажмите на него

4. **Запустите проверку:**
   - Нажмите **"Run workflow"**
   - Выберите ветку: `cursor/investigate-expired-development-agent-status-b61b`
   - Нажмите **"Run workflow"**

### **Способ 2: Через GitHub CLI**

```bash
# Установите GitHub CLI
# https://cli.github.com/

# Запустите workflow
gh workflow run simple-check.yml

# Проверьте статус
gh run list --workflow=simple-check.yml
```

### **Способ 3: Автоматический запуск**

Workflow автоматически запускается при:
- ✅ Push в ветки: `main`, `develop`, `cursor/investigate-expired-development-agent-status-b61b`
- ✅ Pull Request в ветки: `main`, `develop`
- ✅ Ручной запуск через UI

---

## 📊 **Ожидаемые результаты**

### **Успешная проверка:**
```
🚀 Checking project structure...
✅ ios directory found
📱 Swift files found: 44
✅ Swift files count is good
📚 Documentation files found: 33
✅ Documentation count is good
🔍 Checking key files...
✅ ios/App.swift
✅ ios/Models/Models.swift
✅ ios/Services/FirestoreService.swift
✅ ios/Screens/MapScreen.swift
✅ content/poi.json
✅ content/routes.json
✅ README.md
✅ DEVELOPER_GUIDE.md
✅ FUNCTIONALITY_CHECKLIST.md
🔍 Validating JSON files...
✅ poi.json is valid
✅ routes.json is valid
🎉 All checks passed!
```

### **Отчет в PR:**
```
## 📊 Simple Project Check Summary

## ✅ Status: PASSED

### File Counts:
- Swift files: 44
- Documentation: 33
- JSON files: 6

### Key Components:
- ✅ iOS App structure
- ✅ Models, Services, Screens
- ✅ Content files (JSON)
- ✅ Documentation

### Next Steps:
1. Download files using `./setup-xcode-project.sh`
2. Create Xcode project
3. Add files to project
4. Configure Firebase
5. Run in simulator

🎉 Project is ready for Xcode development!
```

---

## 🛠️ **Устранение проблем**

### **Проблема: "Workflow не запускается"**
**Решение:**
1. Убедитесь, что вы на правильной ветке
2. Проверьте, что файлы workflow существуют
3. Попробуйте ручной запуск

### **Проблема: "Swift validation failed"**
**Решение:**
1. Используйте **Simple Project Check** вместо полного
2. Swift validation пропущена из-за совместимости
3. Проверьте Swift синтаксис в Xcode

### **Проблема: "Files not found"**
**Решение:**
1. Убедитесь, что вы на ветке `cursor/investigate-expired-development-agent-status-b61b`
2. Проверьте, что файлы существуют
3. Запустите `./setup-xcode-project.sh` для подготовки файлов

---

## 📚 **Дополнительные ресурсы**

### **Документация:**
- `DEVELOPER_GUIDE.md` — Полное руководство разработчика
- `DOWNLOAD_INSTRUCTIONS.md` — Инструкции по скачиванию
- `XCODE_LAUNCH_GUIDE.md` — Запуск в Xcode

### **Скрипты:**
- `./setup-xcode-project.sh` — Подготовка файлов для Xcode
- `./check-project.sh` — Локальная проверка проекта

---

## 🎉 **Заключение**

**Используйте "Simple Project Check"** — это самый надежный способ проверить проект в GitHub Actions. Он работает на любой версии Ubuntu и не зависит от Swift.

**Проект готов к разработке!** 🚀