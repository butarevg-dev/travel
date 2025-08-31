import SwiftUI
import AuthenticationServices

struct AuthScreen: View {
    @StateObject private var authService = AuthService.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPasswordReset = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Саранск для туристов")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Откройте для себя красоту столицы Мордовии")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Auth Form
                VStack(spacing: 20) {
                    if isSignUp {
                        signUpForm
                    } else {
                        signInForm
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Social Auth Buttons
                VStack(spacing: 16) {
                    Text("или")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    socialAuthButtons
                }
                .padding(.horizontal, 30)
                
                // Toggle Sign In/Up
                Button(action: {
                    withAnimation {
                        isSignUp.toggle()
                    }
                }) {
                    Text(isSignUp ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
                .padding(.bottom, 30)
            }
            .alert("Ошибка", isPresented: .constant(authService.error != nil)) {
                Button("OK") {
                    authService.error = nil
                }
            } message: {
                Text(authService.error ?? "")
            }
            .sheet(isPresented: $showPasswordReset) {
                PasswordResetSheet()
            }
        }
    }
    
    // MARK: - Sign In Form
    
    private var signInForm: some View {
        VStack(spacing: 16) {
            Text("Вход в аккаунт")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Пароль", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.password)
            }
            
            Button("Забыли пароль?") {
                showPasswordReset = true
            }
            .font(.caption)
            .foregroundColor(.accentColor)
            
            Button(action: signIn) {
                if authService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Войти")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
        }
    }
    
    // MARK: - Sign Up Form
    
    private var signUpForm: some View {
        VStack(spacing: 16) {
            Text("Регистрация")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Пароль", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.newPassword)
                
                SecureField("Подтвердите пароль", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.newPassword)
            }
            
            Button(action: signUp) {
                if authService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Зарегистрироваться")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(authService.isLoading || email.isEmpty || password.isEmpty || password != confirmPassword)
        }
    }
    
    // MARK: - Social Auth Buttons
    
    private var socialAuthButtons: some View {
        VStack(spacing: 12) {
            // Google Sign-In
            Button(action: signInWithGoogle) {
                HStack {
                    Image(systemName: "globe")
                        .font(.title2)
                    Text("Войти через Google")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(authService.isLoading)
            
            // Apple Sign-In
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    Task {
                        await handleAppleSignIn(result)
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(12)
            .disabled(authService.isLoading)
        }
    }
    
    // MARK: - Actions
    
    private func signIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                // Error is handled by AuthService
            }
        }
    }
    
    private func signUp() {
        Task {
            do {
                try await authService.signUp(email: email, password: password)
            } catch {
                // Error is handled by AuthService
            }
        }
    }
    
    private func signInWithGoogle() {
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                // Error is handled by AuthService
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            do {
                try await authService.signInWithApple()
            } catch {
                // Error is handled by AuthService
            }
        case .failure(let error):
            authService.error = error.localizedDescription
        }
    }
}

// MARK: - Password Reset Sheet

struct PasswordResetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                    
                    Text("Сброс пароля")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Введите ваш email для получения инструкций по сбросу пароля")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button(action: resetPassword) {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Отправить инструкции")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(authService.isLoading || email.isEmpty)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Отмена") {
                    dismiss()
                }
            )
            .alert("Ошибка", isPresented: .constant(authService.error != nil)) {
                Button("OK") {
                    authService.error = nil
                }
            } message: {
                Text(authService.error ?? "")
            }
        }
    }
    
    private func resetPassword() {
        Task {
            do {
                try await authService.resetPassword(email: email)
                dismiss()
            } catch {
                // Error is handled by AuthService
            }
        }
    }
}

#Preview {
    AuthScreen()
}