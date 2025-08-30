import Foundation

final class VKAuthProviderStub: ThirdPartyAuthProvider {
    let kind: AuthProviderKind = .vk

    func signIn() async throws -> AuthResult {
        // TODO: integrate VK iOS SDK (vk.com)
        return AuthResult(user: AuthUser(uid: "vk:stub", email: nil, displayName: "VK User", provider: .vk), isNewUser: false)
    }

    func signOut() async throws {
        // no-op
    }
}