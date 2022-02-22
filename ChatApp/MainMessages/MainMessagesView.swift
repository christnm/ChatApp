//
//  MainMessagesView.swift
//  ChatApp
//
//  Created by Christian Morales on 2/21/22.
//

import SwiftUI
import SDWebImageSwiftUI


class MainMessagesViewModel: ObservableObject {
    
    @Published var chatUser: ChatUser?
    
    init(){
        DispatchQueue.main.async {
            self.isUserCurrentlyLogggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        
        fetchCurrentUser()
    }
    
     func fetchCurrentUser(){
        guard let uid =
                FirebaseManager.shared.auth.currentUser?.uid else {return}
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch current user: ", error)
                return
            }
            guard let data = snapshot?.data() else {
            print("Data Not found")
                return
            }
            self.chatUser = .init(data: data)
            
        }
    }
    
    @Published var isUserCurrentlyLogggedOut = false
    
    func handleSignOut(){
        isUserCurrentlyLogggedOut.toggle()
        
        try? FirebaseManager.shared.auth.signOut()
        
    }
}

struct MainMessagesView: View {

    @State var shouldShowLogOutOptions = false
    
    @ObservedObject private var vm = MainMessagesViewModel()

    private var customNavBar: some View {
        HStack(spacing: 16) {
            
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 44)
                            .stroke(Color(.label), lineWidth: 1)
                )
                .shadow(radius: 5)
            VStack(alignment: .leading, spacing: 4) {
                let email = vm.chatUser?.email.replacingOccurrences(of: "@mail.com", with: "") ?? ""
                Text(email)
                    .font(.system(size: 24, weight: .bold))

                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }

            }

            Spacer()
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    print("handle sign out")
                    vm.handleSignOut()
                }),
                    .cancel()
            ])
        }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLogggedOut, onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLogggedOut = false
                self.vm.fetchCurrentUser()
                
            })
        }
    }

    var body: some View {
        NavigationView {

            VStack {
                customNavBar
                messagesView
            }
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }

    private var messagesView: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                VStack {
                    HStack(spacing: 16) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 44)
                                        .stroke(Color(.label), lineWidth: 1)
                            )


                        VStack(alignment: .leading) {
                            Text("Username")
                                .font(.system(size: 16, weight: .bold))
                            Text("Message sent to user")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.lightGray))
                        }
                        Spacer()

                        Text("22d")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)

            }.padding(.bottom, 50)
        }
    }
    
    @State var shouldShowNewMessageScreen = false

    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
                .background(Color.blue)
                .cornerRadius(32)
                .padding(.horizontal)
                .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen, onDismiss: nil) {
            CreateNewMessageView()
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}
