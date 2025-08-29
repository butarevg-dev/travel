# «Саранск для Туристов» — iOS

Нативное iOS‑приложение‑гид: карта POI, маршруты (3ч/6ч/1д/выходные), аудиогиды, оффлайн, AR, геймификация, отзывы и шеры.

## Старт (Firebase вариант)
1. Создайте проект в Firebase Console, добавьте iOS‑приложение (Bundle ID).
2. Скачайте `GoogleService-Info.plist`, добавьте в Xcode.
3. Подключите SDK (Swift Package Manager) и инициализируйте Firebase в `App`.
4. Включите Authentication (email/password, Google, Sign in with Apple).
5. Создайте Firestore коллекции: `poi`, `routes`, `reviews`, `questions`, `badges`, `quests`, `users`.
6. Включите Firebase Storage, создайте папки `images/poi`, `audio/poi`.
7. Залейте стартовый контент из `content/poi.json`, `content/routes.json`; медиа — в Storage.
8. Настройте Security Rules (RO для `poi/routes`, запись отзывов — только авторизованным).
9. (Опционально) Cloud Functions: `generateRoute`, `awardBadge`, агрегация афиши.

## Структура контента
- `content/poi.json` — POI с медиа и метаданными
- `content/routes.json` — маршруты и остановки
- `offline/manifest.json` — список файлов для оффлайн‑загрузки
- `images/poi`, `audio/poi` — каталоги медиа (локальные примеры)

## Дизайн/архитектура
- См. `DESIGN_TOKENS.md`, `CONTEXT.md`, `AGENT_BRIEF.md`, `NEXT_STEPS.md`
- Схемы данных/API: `DATA_SCHEMA.md`, `API_SCHEMA.md`

## Команды
- План спринтов и задачи описаны в `NEXT_STEPS.md`

## Примечания по оффлайн
- Клиент сверяет версии (`offline/manifest.json`) и обновляет кэш контента/медиа
- Крупные аудиофайлы загружаются по запросу пользователя

## Лицензии
- OSM/MapKit атрибуция, фото — собственные/CC BY, тексты — с указанием источников