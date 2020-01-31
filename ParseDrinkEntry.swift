//
//  ParseDrinkEntry.swift
//  Cheers
//
//  Created by Air on 5/16/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import Foundation
import Parse

class ParseDrinkEntry : PFObject, PFSubclassing
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
        return "ParseDrinkEntry"
    }
    
    // PFUser?
    @NSManaged var parseUser: PFUser
    @NSManaged var displayName: String
    @NSManaged var type: String
    @NSManaged var breweryName: String
    @NSManaged var beerName: String
    @NSManaged var vineyardName: String
    @NSManaged var wineName: String
    @NSManaged var vintage: String
    @NSManaged var abv: Double
    @NSManaged var volume: Double
    @NSManaged var volumeUnits: Int
    @NSManaged var cocktailEntryMode: Int
    @NSManaged var ingredients: [ParseIngredient]
    @NSManaged var effectiveDrinkCount: Double
    // no session
    @NSManaged var bacEstimation: Bool
    @NSManaged var savedDateTime: Date
    @NSManaged var selectedDateTime: Date
    @NSManaged var universalDateTime: Date
    @NSManaged var locationName: String?
    @NSManaged var locationAddress: String?
    @NSManaged var locationCoordinates: String?
    @NSManaged var locationID: String?
    @NSManaged var caption: String?
    @NSManaged var commentNumber: Int
    @NSManaged var likeCount: Int
    // no rating
    
    @NSManaged var os: String
    
    // Local.
    @NSManaged var friendPhoto: String?
    @NSManaged var friendName: String?
}

class ParseIngredient : PFObject, PFSubclassing
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
        return "ParseIngredient"
    }
    
    @NSManaged var parseIngredientName: String
    @NSManaged var parseIngredientVolume: Double
    @NSManaged var parseIngredientUnits: Int
    @NSManaged var parseIngredientAlcoholContent: Double
    // Type? Brand?
}
