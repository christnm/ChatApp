//
//  RecentMessages.swift
//  ChatApp
//
//  Created by Christian Morales on 3/22/22.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct RecentMessage: Identifiable {
    
    var id: String{ documentId}
    
    let documentId: String
    let text, fromId, toId: String
    let email, profileImageURL: String
    let timestamp: String
    
    
    init(documentId: String, data: [String: Any ]){
        self.documentId = documentId
        self.text = data["text"] as? String ?? ""
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profileImageURL = data["profileImageUrl"] as? String ?? ""
        self.timestamp = data["timestemp"] as? String ?? ""
    }
    var username: String {
        email.components(separatedBy: "@").first ?? email
    }
    
//    var timeAgo: String {
//        let formatter = RelativeDateTimeFormatter()
//        formatter.unitsStyle = .abbreviated
//        return formatter.localizedString(for: timestamp, relativeTo: Date())
//    }
}
