//
//  ChatsView.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 16.06.2024.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Chat: Identifiable {
    var id: String { participantUserUid }
    let currentUser: UserDB
    let lastMessage: String
    let lastMessageTimeStamp: Date
    let participantUserUid: String
    let participantUser: UserDB?
    let isRead: Bool
}

enum ChatsNavigationItem: Hashable {
    case chat(participantUid: String, user: UserDB?)
}

struct ChatsView: View {
    @EnvironmentObject var environmentSettings: EnvironmentSettings
    @State var path: [ChatsNavigationItem] = []
    @State var chats: [Chat] = [.init(currentUser: .mockUser1, lastMessage: "Nasılsın?", lastMessageTimeStamp: .now, participantUserUid: "", participantUser: .mockUser2, isRead: true), .init(currentUser: .mockUser2, lastMessage: "Olabilir abi", lastMessageTimeStamp: .now, participantUserUid: "", participantUser: .mockUser2, isRead: false)]
    @State var isLoading: Bool = true
    private let messageCollection = Firestore.firestore().collection("Messages")
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.blue.ignoresSafeArea()
                
                if chats.isEmpty != true {
                    ScrollView {
                        LazyVStack {
                            ForEach(chats) { chat in
                                ChatRowView(
                                    chat: chat
                                ) {
                                    path.append(.chat(participantUid: chat.participantUserUid, user: chat.participantUser))
                                }
                                .padding(.top)
                                .padding(.horizontal)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("No Messages Yet", systemImage: "envelope.fill", description: Text("It’s quiet here! Start chatting with travellers and make friends."))
                }
            }
            .navigationTitle("Messages")
            .navigationDestination(for: ChatsNavigationItem.self) { item in
                switch item {
                case let .chat(participantUid, user):
                    EmptyView()
                }
            }
        }
        .onChange(of: path) { _, newValue in
            environmentSettings.showTab = newValue.isEmpty
        }
    }
}

struct ChatRowView: View {
    private let viewPresentation: ViewPresentation
    let chat: Chat
    let tapped: () -> Void
    
    init(chat: Chat, tapped: @escaping () -> Void) {
        self.viewPresentation = .init(with: chat)
        self.chat = chat
        self.tapped = tapped
    }
    
    var body: some View {
        let userInfo = viewPresentation.userInfo
        let messageInfo = viewPresentation.messageInfo
        Button {
            tapped()
        } label: {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    VStack(spacing: 8) {
                        HStack {
                            Text(userInfo.nameSurname)
                                .font(
                                    .system(
                                        size: 18,
                                        weight: .medium,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(Color.white)
                            Spacer()
                            Text(viewPresentation.topRightText)
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .medium,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(Color.white)
                        }
                        HStack {
                            Text(messageInfo.text)
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .regular,
                                        design: .rounded
                                    )
                                )
                                .lineLimit(1)
                                .foregroundStyle(Color.white)
                            Spacer()
                            if !messageInfo.isRead {
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundStyle(Color.green)
                            }
                        }
                    }
                }
                Rectangle()
                    .foregroundStyle(Color.white)
                    .frame(height: 0.4)
            }
        }
    }
}

extension ChatRowView {
    struct ViewPresentation: Identifiable {
        let id: String
        let userInfo: UserInfo
        let messageInfo: MessageInfo
        let topRightText: String
        
        struct UserInfo {
            let nameSurname: String
            let profileImageURLString: String?
        }
        
        struct MessageInfo {
            let text: String
            let isRead: Bool
        }
        
        init(with chat: Chat) {
            self.id = chat.currentUser.userUid + (chat.participantUser?.userUid ?? UUID().uuidString)
            self.userInfo = .init(
                nameSurname: chat.participantUser?.userNameSurname ?? "Removed Account",
                profileImageURLString: chat.participantUser?.profileImage
            )
            self.topRightText = "12.33"
            self.messageInfo = .init(
                text: chat.lastMessage,
                isRead: chat.isRead
            )
        }
    }
}
