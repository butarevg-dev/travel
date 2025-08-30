# BaaS Decision — Firebase (Chosen)

## Why Firebase
- Turnkey Auth: email/password, Google, Sign in with Apple — fastest iOS path
- Realtime/Firestore fits POI, routes, reviews, questions
- Storage for images/audio, SDKs stable on iOS
- Cloud Functions for route generation, moderation, badges
- Tooling: Analytics, Crashlytics, Remote Config

## Tradeoffs vs Supabase
- Vendor lock vs Postgres portability (Supabase)
- Firestore query limits vs SQL flexibility
- For MVP speed and iOS integration, Firebase wins; can migrate later if needed

## Immediate Actions
- Enable Auth providers (email, Google, Apple)
- Create collections: `poi`, `routes`, `reviews`, `questions`, `badges`, `quests`, `users`
- Set Storage buckets and security rules
- (Optional) Deploy Cloud Functions: `generateRoute`, `awardBadge`