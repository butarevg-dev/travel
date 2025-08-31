# DATA SCHEMA — «Саранск для Туристов»

## POI (точка интереса)
- id: string
- title: string
- categories: string[] (архитектура|музеи|еда|сувениры|развлечения|события|...)
- coordinates: { lat: number, lng: number }
- address?: string
- openingHours?: string
- ticket?: string|null
- contacts?: { site?: string|null, phone?: string|null }
- short: string
- description: string (markdown допустим)
- images: { src: string, license?: string, author?: string }[]
- audio?: { src: string, durationSec?: number, voice?: string }
- rating?: { avg: number, count: number }
- tags?: string[]
- meta?: { lastVerified?: string }

## Route (маршрут)
- id: string
- title: string
- durationMinutes: number
- distanceKm?: number
- interests?: string[]
- stops: { poiId: string, note?: string, dwellMin?: number }[]
- polyline?: string|null
- tags?: string[]
- meta?: { lastVerified?: string }

## Review (отзыв)
- id: string
- poiId: string
- userId: string
- rating: 1|2|3|4|5
- text?: string
- createdAt: timestamp
- reported?: boolean

## Question (вопрос)
- id: string
- poiId: string
- userId: string
- text: string
- createdAt: timestamp
- answeredBy?: string (user/moderator/bot)
- answerText?: string
- status: open|answered|closed

## Badge (бейдж)
- id: string
- title: string
- description: string
- icon: string
- rule: { type: visit_poi|finish_route|streak_days, params: object }

## Quest (квест)
- id: string
- title: string
- description: string
- tasks: { type: visit_poi|finish_route|rate_poi, params: object }[]
- rewardBadgeId?: string

## User (профиль)
- id: string
- email?: string
- displayName?: string
- providers: string[] (password|google|apple|vk|...)
- favorites: string[] (poiId)
- badges: string[] (badgeId)
- settings: { language: ru|en|erz|mdf, theme: light|dark|system, offline: boolean }
- premiumUntil?: timestamp

## Media Index
- audio files (m4a), images (jpg/webp) — хранить лицензию и версию

## Версионирование
- Контент имеет поле `version` и `updatedAt`; клиенты сверяют и обновляют кэш