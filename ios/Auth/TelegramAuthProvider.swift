import Foundation

final class TelegramAuthProviderStub: ThirdPartyAuthProvider {
    let kind: AuthProviderKind = .telegram

    func signIn() async throws -> AuthResult {
        // TODO: integrate Telegram Login (via webwidget or SDK)
        return AuthResult(user: AuthUser(uid: "tg:stub", email: nil, displayName: "Telegram User", provider: .telegram), isNewUser: false)
    }

    func signOut() async throws {
        // no-op
    }
}