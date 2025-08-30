import Foundation

final class GoogleAuthProviderStub: ThirdPartyAuthProvider {
    let kind: AuthProviderKind = .google

    func signIn() async throws -> AuthResult {
        // TODO: integrate GoogleSignIn SDK
        return AuthResult(user: AuthUser(uid: "google:stub", email: "user@example.com", displayName: "Google User", provider: .google), isNewUser: true)
    }

    func signOut() async throws {
        // TODO: sign out
    }
}