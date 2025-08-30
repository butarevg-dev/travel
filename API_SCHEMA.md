# API SCHEMA — «Саранск для Туристов»

Цель: описать два варианта бэкенда — Firebase и Supabase — для Auth, DB, Storage и действий клиента.

## Общие эндпоинты/операции (с точки зрения клиента)
- Auth: signUp/signIn (email+password), Google, Apple, соцсети
- User: get/update profile, favorites, badges, premium
- POI: list/filter, get by id, add review, ask question, report
- Routes: list presets, generate by interests/time, get full details
- Media: download images/audio (with caching), mark for offline
- Quests/Badges: list available, claim on completion

## Firebase (рекомендация по старту)
- Auth: Firebase Authentication (email/password, Google, Apple)
- DB: Firestore
  - collections: `poi`, `routes`, `reviews`, `questions`, `badges`, `quests`, `users`
- Storage: Firebase Storage (`images/poi/...`, `audio/poi/...`)
- Cloud Functions:
  - `generateRoute({ interests, minutes, startCoord? }) -> route`
  - `moderateContent({ type, id })`
  - `awardBadge({ userId, rule })`
- Security Rules (эскиз):
  - чтение `poi`, `routes` — публично (RO)
  - запись `reviews/questions` — авторизованные, антиспам‑квоты
  - `users` — только владелец
  - `storage` — public read, authenticated write (uploads moderated)

### Firestore схемы (соответствуют DATA_SCHEMA.md)
- `poi/{id}`: POI
- `routes/{id}`: Route
- `reviews/{id}`: Review
- `questions/{id}`: Question
- `badges/{id}`: Badge
- `quests/{id}`: Quest
- `users/{id}`: User

## Supabase (альтернатива)
- Auth: Supabase Auth (email, providers)
- DB: Postgres + RLS (таблицы: poi, routes, route_stops, reviews, questions, badges, quests, users)
- Storage: Supabase Storage (buckets: images, audio)
- Edge Functions:
  - `generateRoute` (Deno): аналогично Firebase, доступ через RLS policies
  - `awardBadge`, `moderateContent`
- RLS Policies (эскиз):
  - `SELECT poi, routes` — public; `INSERT reviews/questions` — authenticated
  - `users` — owner only; Storage — публичное чтение, аутентифицированная запись

## Генерация маршрута (алгоритм v0)
Вход: интересы[], бюджет времени (минуты), старт‑точка (опц.)
- Отфильтровать POI по интересам и часам работы
- Оценить время на перемещения (пешком ~ 12–15 мин/км) + dwellMin
- Вписать максимум POI в лимит, строя связный путь вокруг центра
- Вернуть последовательность `stops[]`, оценочный `distanceKm` и `durationMinutes`

## Оффлайн и версии
- `/version.json` в DB/Storage — клиент сверяет и обновляет локальный кэш
- Пакеты: `content/poi.json`, `content/routes.json`, аудио/изображения — манифест с хешами

## События/погода
- Источник афиши: внешний JSON/RSS, агрегация в DB
- Погода: публичный API (кеширование через Cloud Function/Edge Function)