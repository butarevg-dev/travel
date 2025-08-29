import SwiftUI
import FirebaseCore

@main
struct SaranskTouristApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootTabs()
        }
        .onOpenURL { url in
            // TODO: forward to GoogleSignIn / VK SDK handlers
            // GIDSignIn.sharedInstance.handle(url)
            // VKSdk.processOpen(url, fromApplication: nil)
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