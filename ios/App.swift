import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct SaranskTouristApp: App {
    init() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootTabs()
        }
        .onOpenURL { url in
            // Hook SDK handlers here when integrated (Google/VK)
        }
    }
}

struct RootTabs: View {
    var body: some View {
        TabView {
            MapScreen()
                .tabItem { Label("Карта", systemImage: "map") }
            RoutesScreen()
                .tabItem { Label("Маршруты", systemImage: "point.topleft.down.curvedto.point.bottomright.up") }
            POIScreen()
                .tabItem { Label("Каталог", systemImage: "list.bullet") }
            ProfileScreen()
                .tabItem { Label("Профиль", systemImage: "person.circle") }
        }
    }
}