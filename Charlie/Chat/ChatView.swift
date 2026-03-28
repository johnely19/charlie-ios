import SwiftUI

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var input: String = ""
    @State private var isStreaming: Bool = false
    @State private var streamingMessageId: String?
    @Environment(DiscoveryStore.self) var store

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    isStreaming: message.role == .assistant && message.id == streamingMessageId
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                HStack(spacing: 12) {
                    TextField("Ask Charlie...", text: $input)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .disabled(isStreaming)
                        .onSubmit {
                            sendMessage()
                        }

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(input.isEmpty || isStreaming ? .gray : .blue)
                    }
                    .disabled(input.isEmpty || isStreaming)
                }
                .padding()
            }
            .navigationTitle("Charlie")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sendMessage() {
        guard !input.isEmpty, !isStreaming else { return }

        let userMessage = ChatMessage.user(input)
        messages.append(userMessage)

        var assistantMessage = ChatMessage.assistant("")
        messages.append(assistantMessage)
        streamingMessageId = assistantMessage.id
        isStreaming = true

        let userInput = input
        input = ""

        Task {
            do {
                let stream = APIClient.shared.chat(message: userInput, contextKey: store.activeContext?.key)
                for try await chunk in stream {
                    if let index = messages.firstIndex(where: { $0.id == streamingMessageId }) {
                        messages[index].content += chunk
                    }
                }
            } catch {
                if let index = messages.firstIndex(where: { $0.id == streamingMessageId }) {
                    messages[index].content = "Error: \(error.localizedDescription)"
                }
            }
            isStreaming = false
            streamingMessageId = nil
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var isStreaming: Bool = false

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if isStreaming {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isStreaming ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isStreaming)
    }
}

#Preview {
    ChatView()
        .environment(DiscoveryStore())
}