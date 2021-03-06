//
//  User.swift
//  ChatGame
//
//  Created by Cuong on 9/8/18.
//  Copyright © 2018 quoccuong. All rights reserved.
//

import Foundation

class User: NSObject {
    var id: String?
    var name: String?
    var email: String?
    var profileImageUrl: String?
    init(dictionary: [String: AnyObject]) {
        self.id = dictionary["id"] as? String
        self.name = dictionary["name"] as? String
        self.email = dictionary["email"] as? String
        self.profileImageUrl = dictionary["profileImageUrl"] as? String
    }
}

