import Foundation

public enum AuthProviderKind: String {
    case emailPassword
    case google
    case apple
    case vk
    case telegram
}

public struct AuthUser {
    public let uid: String
    public let email: String?
    public let displayName: String?
    public let provider: AuthProviderKind
}

public struct AuthResult {
    public let user: AuthUser
    public let isNewUser: Bool
}

public protocol ThirdPartyAuthProvider {
    var kind: AuthProviderKind { get }
    func signIn() async throws -> AuthResult
    func signOut() async throws
}