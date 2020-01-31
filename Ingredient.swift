//
//  Ingredient.swift
//  Cheers
//
//  Created by Air on 7/1/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import Foundation
import CoreData

class Ingredient: NSManagedObject
{
    @NSManaged var name: String
    @NSManaged var volume: NSNumber?
    @NSManaged var volumeUnits: NSNumber?
    @NSManaged var abv: NSNumber?
    // Type? Brand?    
}

class TempIngredient: NSObject
{
    var name: String!
    var volume: Double?
    var volumeUnits: Int?
    var abv: Double?
    
    // init (name: String, volume: Double, volumeUnits: Int, abv: Double)
    init (name: String)
    {
        super.init()
        self.name = name
        // self.volume = volume
        // self.volumeUnits = volumeUnits
        // self.abv = abv
    }
}
