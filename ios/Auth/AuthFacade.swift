import Foundation

final class AuthFacade {
    static let shared = AuthFacade()

    private let google = GoogleAuthProviderStub()
    private let apple = AppleAuthProviderStub()
    private let vk = VKAuthProviderStub()
    private let tg = TelegramAuthProviderStub()

    func signIn(with kind: AuthProviderKind) async throws -> AuthResult {
        let provider: ThirdPartyAuthProvider
        switch kind {
        case .google: provider = google
        case .apple: provider = apple
        case .vk: provider = vk
        case .telegram: provider = tg
        case .emailPassword:
            // not implemented here
            throw NSError(domain: "auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email auth not implemented in facade"])
        }
        let res = try await provider.signIn()
        // TODO: Link third-party credential with Firebase Auth
        return res
    }

    func signOutAll() async {
        for p in [google as ThirdPartyAuthProvider, apple, vk, tg] {
            try? await p.signOut()
        }
        // TODO: also sign out Firebase
    }
}