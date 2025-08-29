# Quick Start (Mock‑First)

Этот проект запустится без внешних SDK и аккаунтов.

1) Откройте папку в Xcode как существующий проект (Swift файлы в `ios/`).
2) Убедитесь, что таргет iOS 16+, схема `SaranskTouristApp` (см. `ios/App.swift`).
3) Соберите и запустите — данные подтянутся из локальных JSON:
   - `content/poi.json`
   - `content/routes.json`
4) Мини‑плеер и все экраны — моки; взаимодействия с сетью отключены.

Переключение на боевой режим:
- Добавьте зависимости из `SPM_DEPENDENCIES.md` (Firebase/Google/VK и т.д.)
- Положите `GoogleService-Info.plist` в таргет и снимите заглушки
- Настройте URL Schemes/Capabilities по `IOS_SETUP.md`
- Реальные методы Firestore начнут работать автоматически (см. `FirestoreService`)