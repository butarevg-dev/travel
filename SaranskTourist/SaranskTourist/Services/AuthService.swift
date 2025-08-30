import Foundation
import FirebaseAuth
import FirebaseCore
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: AuthUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State Management
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let firebaseUser = user {
                    self?.currentUser = AuthUser(
                        uid: firebaseUser.uid,
                        email: firebaseUser.email,
                        displayName: firebaseUser.displayName,
                        provider: self?.getProvider(from: firebaseUser.providerData) ?? .email
                    )
                    self?.isAuthenticated = true
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    private func getProvider(from providerData: [UserInfo]) -> AuthProviderKind {
        for info in providerData {
            switch info.providerID {
            case "google.com": return .google
            case "apple.com": return .apple
            case "vk.com": return .vk
            case "telegram.com": return .telegram
            default: return .email
            }
        }
        return .email
    }
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            currentUser = AuthUser(
                uid: result.user.uid,
                email: result.user.email,
                displayName: result.user.displayName,
                provider: .email
            )
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = AuthUser(
                uid: result.user.uid,
                email: result.user.email,
                displayName: result.user.displayName,
                provider: .email
            )
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async throws {
        isLoading = true
        error = nil
        
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.configurationError
            }
            
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                throw AuthError.presentationError
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.tokenError
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = AuthUser(
                uid: authResult.user.uid,
                email: authResult.user.email,
                displayName: authResult.user.displayName,
                provider: .google
            )
            isAuthenticated = true
            
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Apple Sign-In
    
    func signInWithApple() async throws {
        isLoading = true
        error = nil
        
        do {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let result = try await withCheckedThrowingContinuation { continuation in
                let controller = ASAuthorizationController(authorizationRequests: [request])
                let delegate = AppleSignInDelegate { result in
                    continuation.resume(with: result)
                }
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                controller.performRequests()
                
                // Store delegate to prevent deallocation
                objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }
            
            guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthError.tokenError
            }
            
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nil
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = AuthUser(
                uid: authResult.user.uid,
                email: authResult.user.email,
                displayName: authResult.user.displayName,
                provider: .apple
            )
            isAuthenticated = true
            
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        isLoading = true
        error = nil
        
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        isLoading = true
        error = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
}

// MARK: - Supporting Types

enum AuthError: LocalizedError {
    case configurationError
    case presentationError
    case tokenError
    
    var errorDescription: String? {
        switch self {
        case .configurationError:
            return "Ошибка конфигурации Firebase"
        case .presentationError:
            return "Ошибка отображения окна авторизации"
        case .tokenError:
            return "Ошибка получения токена авторизации"
        }
    }
}

// MARK: - Apple Sign-In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorization, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}