//
//  FirebaseDrink.swift
//  Etto
//
//  Created by John DeRusso on 4/23/16.
//  Copyright © 2016 Cheers. All rights reserved.
//

import Foundation

class FirebaseDrink
{
    // should everything but id be optional?
    // see FriendsTVC
    
    var id: String!
    var userID: String!
    
    // only used locally
    var userName: String?
    var userPhoto: String?
    
    var displayName: String!
    
    var type: String!
    
    var breweryName: String?
    var beerName: String?
    
    var vineyardName: String?
    var wineName: String?
    var vintage: String?
    
    var entryMode: Int?
    var ingredients: [FirebaseIngredient]?
    
    var locationName: String?
    var locationID: String?
    var locationAddress: String?
    var locationLatitude: String?
    var locationLongitude: String?
 
    var caption: String?
    
    var commentCount: Int!
    var likeCount: Int!
    
    var os: String!
    
    // convert from string on fetch
    var firebaseTimestamp: Date!
    
    var abv: Double?
    var volume: Double?
    var volumeUnits: Int?
    var effectiveDrinkCount: Double?
    var bacEstimation: Bool!
    
    // convert from string on fetch
    var savedDateTime: Date!
    var selectedDateTime: Date!
    
    init(id: String)
    {
        self.id = id
    }
}
