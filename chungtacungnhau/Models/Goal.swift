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
