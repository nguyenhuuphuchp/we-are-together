// Bước 1: AppDelegate.swift - Setup Firebase

import SwiftUI
import Firebase

@main
struct ChungTaCungNhauApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// Bước 2: Model

import Foundation
import FirebaseFirestore

struct Goal: Identifiable {
    var id: String
    var name: String
    var description: String
    var deadline: Date
    var isCompleted: Bool
    var createdBy: String
    
    init(id: String = UUID().uuidString, name: String, description: String, deadline: Date, isCompleted: Bool = false, createdBy: String) {
        self.id = id
        self.name = name
        self.description = description
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.createdBy = createdBy
    }
    
    // Tạo từ Firestore Document
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let name = data["name"] as? String,
              let description = data["description"] as? String,
              let timestamp = data["deadline"] as? Timestamp,
              let isCompleted = data["isCompleted"] as? Bool,
              let createdBy = data["createdBy"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.name = name
        self.description = description
        self.deadline = timestamp.dateValue()
        self.isCompleted = isCompleted
        self.createdBy = createdBy
    }
    
    // Convert thành dictionary để lưu vào Firestore
    var dictionary: [String: Any] {
        return [
            "name": name,
            "description": description,
            "deadline": Timestamp(date: deadline),
            "isCompleted": isCompleted,
            "createdBy": createdBy
        ]
    }
}

// Bước 3: ViewModel

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class GoalViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        setupAuthListener()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            self?.currentUser = user
            if user != nil {
                self?.startListeningForGoals()
            } else {
                self?.goals = []
                self?.listenerRegistration?.remove()
                self?.listenerRegistration = nil
            }
        }
    }
    
    func startListeningForGoals() {
        isLoading = true
        
        listenerRegistration = db.collection("goals")
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Lỗi khi tải mục tiêu: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Không có dữ liệu"
                    return
                }
                
                self.goals = documents.compactMap { Goal(document: $0) }
                    .sorted { $0.deadline < $1.deadline }
            }
    }
    
    func addGoal(name: String, description: String, deadline: Date) {
        guard let userId = currentUser?.uid else {
            errorMessage = "Bạn cần đăng nhập để thêm mục tiêu"
            return
        }
        
        let newGoal = Goal(name: name, description: description, deadline: deadline, createdBy: userId)
        
        db.collection("goals").addDocument(data: newGoal.dictionary) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Lỗi khi thêm mục tiêu: \(error.localizedDescription)"
            }
        }
    }
    
    func updateGoal(_ goal: Goal) {
        db.collection("goals").document(goal.id).setData(goal.dictionary) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Lỗi khi cập nhật mục tiêu: \(error.localizedDescription)"
            }
        }
    }
    
    func toggleGoalCompletion(_ goal: Goal) {
        var updatedGoal = goal
        updatedGoal.isCompleted.toggle()
        updateGoal(updatedGoal)
    }
    
    func deleteGoal(_ goal: Goal) {
        db.collection("goals").document(goal.id).delete { [weak self] error in
            if let error = error {
                self?.errorMessage = "Lỗi khi xóa mục tiêu: \(error.localizedDescription)"
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, error) in
            if let error = error {
                self?.errorMessage = "Đăng nhập thất bại: \(error.localizedDescription)"
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (result, error) in
            if let error = error {
                self?.errorMessage = "Đăng ký thất bại: \(error.localizedDescription)"
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = "Đăng xuất thất bại: \(error.localizedDescription)"
        }
    }
}

// Bước 4: Colors

import SwiftUI

extension Color {
    static let pastelPink = Color(red: 1.0, green: 0.8, blue: 0.9)
    static let pastelBlue = Color(red: 0.7, green: 0.9, blue: 1.0)
    static let pastelPurple = Color(red: 0.85, green: 0.8, blue: 1.0)
    static let pastelYellow = Color(red: 1.0, green: 0.95, blue: 0.7)
    static let pastelGreen = Color(red: 0.8, green: 1.0, blue: 0.8)
}

// Bước 5: Views

// ContentView.swift - Màn hình chính
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

// GoalRow.swift - Hiển thị một mục tiêu
struct GoalRow: View {
    let goal: Goal
    let viewModel: GoalViewModel
    
    private var isDeadlineSoon: Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: goal.deadline)
        return components.day ?? 0 <= 2 && components.day ?? 0 >= 0
    }
    
    private var isExpired: Bool {
        return Date() > goal.deadline
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(goal.name)
                    .font(.headline)
                    .foregroundColor(goal.isCompleted ? .gray : .primary)
                    .strikethrough(goal.isCompleted)
                
                Text(goal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(isExpired ? .red : (isDeadlineSoon ? .orange : .blue))
                    
                    Text(dateFormatter.string(from: goal.deadline))
                        .font(.caption)
                        .foregroundColor(isExpired ? .red : (isDeadlineSoon ? .orange : .gray))
                }
            }
            
            Spacer()
            
            Button(action: {
                viewModel.toggleGoalCompletion(goal)
            }) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(goal.isCompleted ? .green : .gray)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: {
                viewModel.toggleGoalCompletion(goal)
            }) {
                Label(goal.isCompleted ? "Đánh dấu chưa hoàn thành" : "Đánh dấu hoàn thành", systemImage: goal.isCompleted ? "circle" : "checkmark.circle")
            }
            
            Button(role: .destructive, action: {
                viewModel.deleteGoal(goal)
            }) {
                Label("Xóa", systemImage: "trash")
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// AddGoalView.swift - Thêm mục tiêu mới
struct AddGoalView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: GoalViewModel
    
    @State private var goalName: String = ""
    @State private var goalDescription: String = ""
    @State private var deadline: Date = Date().addingTimeInterval(60*60*24) // Mặc định là ngày mai
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.pastelBlue.opacity(0.3).ignoresSafeArea()
                
                Form {
                    Section(header: Text("Thông tin mục tiêu")) {
                        TextField("Tên mục tiêu", text: $goalName)
                            .padding(.vertical, 8)
                        
                        TextField("Mô tả chi tiết", text: $goalDescription)
                            .padding(.vertical, 8)
                        
                        DatePicker("Hạn hoàn thành", selection: $deadline, displayedComponents: .date)
                            .padding(.vertical, 8)
                    }
                }
            }
            .navigationBarTitle("Thêm Mục Tiêu Mới", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Hủy") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Lưu") {
                    saveGoal()
                }
                .disabled(goalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func saveGoal() {
        viewModel.addGoal(
            name: goalName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: goalDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            deadline: deadline
        )
        presentationMode.wrappedValue.dismiss()
    }
}

// AuthView.swift - Đăng nhập và đăng ký
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

// Notification Manager để gửi thông báo nhắc nhở
import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("Quyền thông báo: \(granted)")
        }
    }
    
    func scheduleNotification(for goal: Goal) {
        let content = UNMutableNotificationContent()
        content.title = "Sắp đến hạn mục tiêu!"
        content.body = "Mục tiêu '\(goal.name)' cần hoàn thành vào ngày \(formattedDate(goal.deadline))"
        content.sound = .default
        
        // Thông báo trước 1 ngày
        let targetDate = Calendar.current.date(byAdding: .day, value: -1, to: goal.deadline) ?? goal.deadline
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: goal.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(for goalId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [goalId])
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Mở rộng ViewModel để tích hợp thông báo
extension GoalViewModel {
    func addGoalWithNotification(name: String, description: String, deadline: Date) {
        addGoal(name: name, description: description, deadline: deadline)
        
        // Thêm thông báo khi đủ quyền
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                let tempGoal = Goal(id: UUID().uuidString, name: name, description: description, deadline: deadline, createdBy: self.currentUser?.uid ?? "")
                NotificationManager.shared.scheduleNotification(for: tempGoal)
            }
        }
    }
    
    func deleteGoalWithNotification(_ goal: Goal) {
        deleteGoal(goal)
        NotificationManager.shared.cancelNotification(for: goal.id)
    }
}
