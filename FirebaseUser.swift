//
//  FirebaseUser.swift
//  Etto
//
//  Created by John DeRusso on 4/23/16.
//  Copyright © 2016 Cheers. All rights reserved.
//

import Foundation

class FirebaseUser
{
    var id: String!
    var facebookID: String?
    var name: String?
    var photo: String?
    var sharing: String?
    
    init(id: String)
    {
        self.id = id
    }
}
