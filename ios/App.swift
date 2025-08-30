import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct SaranskTouristApp: App {
    @StateObject private var authService = AuthService.shared
    
    init() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    RootTabs()
                } else {
                    AuthScreen()
                }
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle Google Sign-In callback
        if url.scheme == "com.googleusercontent.apps.YOUR_CLIENT_ID" {
            // Google Sign-In will handle this automatically
        }
        
        // Handle VK authentication callback
        if url.scheme == "vk" {
            // VK SDK will handle this automatically
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
            ARScreen()
                .tabItem { Label("AR", systemImage: "camera.viewfinder") }
            GamificationScreen()
                .tabItem { Label("Игра", systemImage: "gamecontroller") }
            ProfileScreen()
                .tabItem { Label("Профиль", systemImage: "person.circle") }
        }
    }
}