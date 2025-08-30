# SPM Dependencies (add via Xcode > Project > Package Dependencies)

Recommended minimal set for MVP:

- Firebase iOS SDK (Core, Auth, Firestore, Storage)
  - URL: https://github.com/firebase/firebase-ios-sdk
  - Products: FirebaseAuth, FirebaseFirestore, FirebaseStorage, FirebaseAnalytics (optional)

- Google Sign-In for iOS (SPM package)
  - URL: https://github.com/google/GoogleSignIn-iOS
  - Product: GoogleSignIn

- VK iOS SDK (SPM)
  - URL: https://github.com/VKCOM/vk-ios-sdk
  - Product: VKIOSSDK

- Telegram Login (via WebView / SFSafariViewController)
  - Нет официального SPM; используем веб-логин по документации https://core.telegram.org/widgets/login

- SDWebImage (опционально, для загрузки изображений)
  - URL: https://github.com/SDWebImage/SDWebImage
  - Product: SDWebImage

- Map (встроенный MapKit) — отдельные пакеты не требуются

После добавления:
- Обновите таргет iOS 16+
- Проверьте ссылку на пакетные продукты в сборке и импорт в коде