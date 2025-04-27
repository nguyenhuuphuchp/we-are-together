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
