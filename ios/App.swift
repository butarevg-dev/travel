import SwiftUI
import Firebase

@main
struct SaranskTouristApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}