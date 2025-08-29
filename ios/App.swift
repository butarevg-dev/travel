import SwiftUI

@main
struct SaranskTouristApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabs()
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