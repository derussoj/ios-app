//
//  UpdateFollowers.swift
//  Cheers
//
//  Created by John DeRusso on 1/10/16.
//  Copyright © 2016 Cheers. All rights reserved.
//

import Foundation
import CoreData

class UpdateFollowers: NSManagedObject
{
    @NSManaged var currentUserID: String
    @NSManaged var userToUpdateID: String
    @NSManaged var addOrRemove: String
}
