//
//  ParseLike.swift
//  Cheers
//
//  Created by John DeRusso on 11/20/15.
//  Copyright © 2015 Cheers. All rights reserved.
//

import Foundation
import Parse

class ParseLike : PFObject, PFSubclassing
{
    // just going to comment this out for now
    /*
    override class func initialize()
    {
        struct Static
        {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken)
        {
            self.registerSubclass()
        }
    }
    */
    
    static func parseClassName() -> String
    {
        return "ParseLike"
    }
    
    @NSManaged var drinkEntry: ParseDrinkEntry
    @NSManaged var drinkEntryOwner: PFUser
    // is there a better term for this?
    @NSManaged var liker: PFUser
    @NSManaged var universalDateTime: Date
    @NSManaged var localDateTime: Date
    // commenterName for local use?
}
