import SwiftUI

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
