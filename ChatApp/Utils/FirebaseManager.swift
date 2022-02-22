//
//  FirebaseManager.swift
//  ChatApp
//
//  Created by Christian Morales on 2/21/22.
//

import Foundation

import Firebase

class FirebaseManager: NSObject {
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    static let shared = FirebaseManager()
    override init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        self.storage = Storage.storage()
        super.init()
    }
}
