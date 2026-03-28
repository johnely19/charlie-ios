import Foundation

struct ChatMessage: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let role: ChatRole
    var content: String
    let createdAt: Date

    enum ChatRole: String, Codable {
        case user, assistant
    }

    static func user(_ text: String) -> ChatMessage {
        ChatMessage(id: UUID().uuidString, role: .user, content: text, createdAt: Date())
    }

    static func assistant(_ text: String) -> ChatMessage {
        ChatMessage(id: UUID().uuidString, role: .assistant, content: text, createdAt: Date())
    }
}