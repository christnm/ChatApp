//
//  ChatLogView.swift
//  ChatApp
//
//  Created by Christian Morales on 2/28/22.
//

import SwiftUI
import Firebase


struct FirebaseConstants{
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
}

struct ChatMessage: Identifiable{
    
    var id: String { documentId }
    
    let documentId: String
    let fromId, toId, text: String
    
    init(documentId: String, data: [String: Any]){
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    
    let chatUser: ChatUser?
    
    init (chatUser: ChatUser?){
        self.chatUser = chatUser
        
        fetchMessage()
        
    }
    
    private func fetchMessage(){
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = chatUser?.uid else {return}
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen message data"
                    print(error)
                    return
                }
                
                
                querySnapshot?.documentChanges.forEach({change in
                    if change.type == .added{
                        let data = change.document.data()
                        self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                    }
                })
                
               
                self.count += 1
                
                

            }
    }
    func handleSend(){
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        
        guard let toId = chatUser?.uid else {
            return
        }
        
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: self.chatText, "timestamp": Timestamp() ] as [String : Any]
        
        let document = FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        document.setData(messageData) { error in
            if let error = error {
                print(error)
                self.errorMessage = "Failed to save message"
                return
            }
            
            self.persistRecentMessage()
            
            self.chatText = ""
            self.count += 1
            
        }
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                print(error)
                self.errorMessage = "Failed to save message"
                return
            }
        }
                
        
    }
    
    private func persistRecentMessage() {
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = self.chatUser?.uid else {return}
        guard let profileImageURL = self.chatUser?.profileImageUrl else {return}
        guard let email = self.chatUser?.email else {return}
        
        let document = FirebaseManager.shared.firestore.collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = [
            "timestamp": Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            "profileImageUrl": profileImageURL,
            "email": email
        ] as [String: Any]
    
        document.setData(data) { error in
            if let error = error{
                self.errorMessage = "Failed to retrive recent message"
                return
            }
        }
    }
    
    @Published var count = 0
}



struct ChatLogView: View{
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?){
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    @ObservedObject var vm: ChatLogViewModel
    
    var body: some View{
        ZStack{
            messagesView
            Text(vm.errorMessage)
            
        }
        
        .navigationTitle(chatUser?.email ?? "")
            .navigationBarTitleDisplayMode(.inline)
//            .navigationBarItems(trailing: Button(action: {
//                vm.count += 1
//            }, label: {
//                Text("Count: \(vm.count)")
//            }))
    }
    
    static let emptyScrollToString = "Empty"
    
    private var messagesView: some View{
        ScrollView{
            ScrollViewReader{ ScrollViewProxy in
                VStack{
                    ForEach(vm.chatMessages){ message in
                        messageView(message: message)
                    }
                    HStack{Spacer()}
                    .id(Self.emptyScrollToString)
                }
                
                .onReceive(vm.$count) { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        ScrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                    }
                    
                }
               
            }
            
            
           
            
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
        .safeAreaInset(edge: .bottom) {
            chatBottomBar
                .background(Color(.systemBackground).ignoresSafeArea())
        }
    }
    
    private var chatBottomBar: some View{
        HStack(spacing:16){
            Image(systemName: "photo.on.rectangle")
                .font(.system(size:45))
                .foregroundColor(Color(.darkGray))
//                TextEditor(text: $chatText)
            TextField("Description", text: $vm.chatText)
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical,8)
            .background(Color.blue)
            .cornerRadius(8)

        }
        .padding(.horizontal)
        .padding(.vertical,8)
    }
}

struct messageView: View {
    
    let message: ChatMessage
    
    var body: some View{
        VStack{
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack{
                    Spacer()
                    HStack{
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding(.horizontal,8)
            }else{
                HStack{
                
                    HStack{
                        Text(message.text)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    Spacer()
                }
                .padding(.horizontal, 8)
            
            }
        }
    }
}


struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            ChatLogView(chatUser: .init(data: ["uid": "ZV67k21xR9Umq4OhllDZZURKrCu2", "email": "christianm9916@gmail.com"]))
        }
        
    }
}
