import SwiftUI

struct AuthView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: GoalViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.pastelPink, Color.pastelBlue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text(isSignUp ? "Đăng Ký Tài Khoản" : "Đăng Nhập")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    VStack(spacing: 15) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Mật khẩu", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding()
                    } else {
                        Button(action: authenticate) {
                            Text(isSignUp ? "Đăng Ký" : "Đăng Nhập")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.pastelPurple)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal, 50)
                        .disabled(email.isEmpty || password.isEmpty)
                        
                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                            }
                        }) {
                            Text(isSignUp ? "Đã có tài khoản? Đăng nhập" : "Chưa có tài khoản? Đăng ký")
                                .foregroundColor(.white)
                                .underline()
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Đóng") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func authenticate() {
        isProcessing = true
        
        if isSignUp {
            viewModel.signUp(email: email, password: password) { success in
                isProcessing = false
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } else {
            viewModel.signIn(email: email, password: password) { success in
                isProcessing = false
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
