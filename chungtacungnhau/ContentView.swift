import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GoalViewModel()
    @State private var showAddGoalSheet = false
    @State private var showAuthSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.pastelPink, Color.pastelBlue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    if viewModel.currentUser == nil {
                        // Màn hình đăng nhập
                        VStack(spacing: 20) {
                            Image(systemName: "heart.fill")
                                .resizable()
                                .frame(width: 80, height: 70)
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                            
                            Text("Chúng Ta Cùng Nhau")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Theo dõi mục tiêu cùng nhau")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.bottom, 40)
                            
                            Button(action: {
                                showAuthSheet = true
                            }) {
                                Text("Đăng Nhập / Đăng Ký")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.pastelPurple)
                                    .cornerRadius(15)
                                    .shadow(radius: 5)
                            }
                            .padding(.horizontal, 50)
                        }
                        .padding()
                    } else {
                        // Màn hình danh sách mục tiêu
                        VStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            } else if viewModel.goals.isEmpty {
                                VStack(spacing: 15) {
                                    Image(systemName: "star.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.pastelYellow)
                                    
                                    Text("Chưa có mục tiêu nào")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("Hãy tạo mục tiêu đầu tiên của bạn!")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding()
                            } else {
                                List {
                                    Section(header: Text("Mục tiêu của chúng ta").font(.headline)) {
                                        ForEach(viewModel.goals) { goal in
                                            GoalRow(goal: goal, viewModel: viewModel)
                                        }
                                        .onDelete { indexSet in
                                            for index in indexSet {
                                                viewModel.deleteGoal(viewModel.goals[index])
                                            }
                                        }
                                    }
                                }
                                .listStyle(InsetGroupedListStyle())
                            }
                        }
                        .navigationTitle("Mục Tiêu Cùng Nhau")
                        .navigationBarItems(
                            leading: Button(action: {
                                viewModel.signOut()
                            }) {
                                Text("Đăng xuất")
                                    .foregroundColor(.pastelPurple)
                            },
                            trailing: Button(action: {
                                showAddGoalSheet = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.pastelPurple)
                            }
                        )
                    }
                }
            }
            .alert(item: Binding<AlertItem?>(
                get: { viewModel.errorMessage != nil ? AlertItem(message: viewModel.errorMessage!) : nil },
                set: { _ in viewModel.errorMessage = nil }
            )) { alertItem in
                Alert(title: Text("Thông báo"), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showAddGoalSheet) {
                AddGoalView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAuthSheet) {
                AuthView(viewModel: viewModel)
            }
        }
    }
}

struct AlertItem: Identifiable {
    var id = UUID()
    var message: String
}
