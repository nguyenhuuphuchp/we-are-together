import SwiftUI

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
