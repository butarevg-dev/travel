import Foundation

final class AppleAuthProviderStub: ThirdPartyAuthProvider {
    let kind: AuthProviderKind = .apple

    func signIn() async throws -> AuthResult {
        // TODO: integrate ASAuthorizationAppleIDProvider
        return AuthResult(user: AuthUser(uid: "apple:stub", email: nil, displayName: "Apple User", provider: .apple), isNewUser: false)
    }

    func signOut() async throws {
        // no-op
    }
}