#!/bin/bash

echo "🚀 Проверка проекта «Саранск для Туристов»"
echo "=========================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для проверки файла
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅${NC} $1"
        return 0
    else
        echo -e "${RED}❌${NC} $1 (отсутствует)"
        return 1
    fi
}

# Функция для подсчета файлов
count_files() {
    local count=$(find "$1" -name "$2" | wc -l)
    echo -e "${BLUE}📊${NC} $1: $count файлов"
    return $count
}

echo ""
echo "📁 Проверка структуры проекта:"
echo "-----------------------------"

# Проверка основных папок
check_file "ios/App.swift"
check_file "ios/Models/Models.swift"
check_file "ios/Services/FirestoreService.swift"
check_file "ios/Screens/MapScreen.swift"

echo ""
echo "📱 Подсчет Swift файлов:"
count_files "ios" "*.swift"

echo ""
echo "📚 Подсчет документации:"
count_files "." "*.md"

echo ""
echo "📄 Проверка контентных файлов:"
check_file "content/poi.json"
check_file "content/routes.json"

echo ""
echo "🔧 Проверка конфигурации:"
check_file ".devcontainer/devcontainer.json"
check_file ".github/workflows/check-project.yml"

echo ""
echo "📖 Проверка ключевой документации:"
check_file "README.md"
check_file "DEVELOPER_GUIDE.md"
check_file "FUNCTIONALITY_CHECKLIST.md"
check_file "AGENT_BRIEF.md"
check_file "CONTEXT.md"

echo ""
echo "🎯 Проверка отчетов о завершении этапов:"
for i in {2..7}; do
    if [ $i -eq 3 ]; then
        check_file "STAGE_3_5_COMPLETION_REPORT.md"
    else
        check_file "STAGE_${i}_COMPLETION_REPORT.md"
    fi
done

echo ""
echo "🔍 Проверка JSON файлов:"
if command -v python3 &> /dev/null; then
    echo "Проверка content/poi.json..."
    if python3 -m json.tool content/poi.json > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} poi.json - валидный JSON"
    else
        echo -e "${RED}❌${NC} poi.json - ошибка в JSON"
    fi
    
    echo "Проверка content/routes.json..."
    if python3 -m json.tool content/routes.json > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} routes.json - валидный JSON"
    else
        echo -e "${RED}❌${NC} routes.json - ошибка в JSON"
    fi
else
    echo -e "${YELLOW}⚠️${NC} Python3 не найден, пропускаем проверку JSON"
fi

echo ""
echo "📊 Статистика проекта:"
echo "---------------------"

# Подсчет различных типов файлов
SWIFT_COUNT=$(find ios/ -name "*.swift" | wc -l)
DOC_COUNT=$(find . -name "*.md" | wc -l)
JSON_COUNT=$(find . -name "*.json" | wc -l)
SERVICE_COUNT=$(find ios/Services -name "*.swift" | wc -l)
SCREEN_COUNT=$(find ios/Screens -name "*.swift" | wc -l)
MODEL_COUNT=$(find ios/Models -name "*.swift" | wc -l)

echo "Swift файлов: $SWIFT_COUNT"
echo "Документации: $DOC_COUNT"
echo "JSON файлов: $JSON_COUNT"
echo "Сервисов: $SERVICE_COUNT"
echo "Экранов: $SCREEN_COUNT"
echo "Моделей: $MODEL_COUNT"

echo ""
echo "🎉 Итоговая оценка:"
echo "------------------"

# Проверка минимальных требований
if [ $SWIFT_COUNT -ge 40 ]; then
    echo -e "${GREEN}✅${NC} Swift файлов достаточно ($SWIFT_COUNT)"
else
    echo -e "${RED}❌${NC} Swift файлов недостаточно ($SWIFT_COUNT/40)"
fi

if [ $DOC_COUNT -ge 30 ]; then
    echo -e "${GREEN}✅${NC} Документации достаточно ($DOC_COUNT)"
else
    echo -e "${RED}❌${NC} Документации недостаточно ($DOC_COUNT/30)"
fi

if [ $SERVICE_COUNT -ge 10 ]; then
    echo -e "${GREEN}✅${NC} Сервисов достаточно ($SERVICE_COUNT)"
else
    echo -e "${RED}❌${NC} Сервисов недостаточно ($SERVICE_COUNT/10)"
fi

if [ $SCREEN_COUNT -ge 5 ]; then
    echo -e "${GREEN}✅${NC} Экранов достаточно ($SCREEN_COUNT)"
else
    echo -e "${RED}❌${NC} Экранов недостаточно ($SCREEN_COUNT/5)"
fi

echo ""
echo "🚀 Проект готов к разработке!"
echo "📚 Изучите DEVELOPER_GUIDE.md для подробной информации"
echo "✅ Используйте FUNCTIONALITY_CHECKLIST.md для тестирования"