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
