# iOS Setup Guide

## Bundle ID и таргеты
- Создайте Xcode проект `SaranskTourist` (iOS App, SwiftUI, iOS 16+)
- Bundle ID: `com.yourorg.saransk.tourist` (замените на реальный)
- Targets: App (основной)

## Firebase
1. Добавьте SPM зависимости (см. `SPM_DEPENDENCIES.md`)
2. В Firebase Console создайте iOS приложение с вашим Bundle ID
3. Скачайте `GoogleService-Info.plist` и добавьте в корень App таргета
4. Включите Auth (Email/Password, Google, Apple) и создайте Firestore/Storage

## URL Schemes
- Google Sign-In: добавьте URL Type из `REVERSED_CLIENT_ID` в `GoogleService-Info.plist`
- VK SDK: добавьте URL scheme `vk<APP_ID>`
- Apple Sign-In: включите Capability `Sign In with Apple`

## Entitlements & Capabilities
- Push (опционально позже): `Push Notifications` + `Background Modes (Remote notifications)`
- Sign In with Apple

## Импорт SDK и инициализация
- В `App.swift`:
  - `import FirebaseCore`
  - `FirebaseApp.configure()` в `init()` приложения
- Google Sign-In: настройте `GIDSignIn.sharedInstance.handle(url)` в `onOpenURL` сцены (SwiftUI App lifecycle)
- VK SDK: настройте обработчик URL (см. VK SDK docs)
- Telegram Login: используйте SFSafariViewController/WebView для OAuth flow

## Проверка
- Сборка таргета iOS 16+, запуск на симуляторе
- Проверьте `FirebaseApp.configure()` (без крэшей), сеть доступна