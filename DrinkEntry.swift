//
//  DrinkEntry.swift
//  Cheers
//
//  Created by Air on 5/3/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import Foundation
import CoreData

class DrinkEntry: NSManagedObject
{
    // Parse username? objectid?
    @NSManaged var displayName: String
    @NSManaged var type: String
    @NSManaged var breweryName: String?
    @NSManaged var beerName: String?
    @NSManaged var vineyardName: String?
    @NSManaged var wineName: String?
    @NSManaged var vintage: String?
    @NSManaged var abv: NSNumber?
    @NSManaged var volume: NSNumber?
    @NSManaged var volumeUnits: NSNumber?
    @NSManaged var entryMode: NSNumber?
    // @NSManaged var ingredients: NSSet
    @NSManaged var ingredients: NSMutableOrderedSet?
    @NSManaged var effectiveDrinkCount: NSNumber?
    // no session
    @NSManaged var bacEstimation: Bool
    @NSManaged var savedDateTime: Date
    @NSManaged var selectedDateTime: Date
    @NSManaged var universalDateTime: Date
    @NSManaged var locationName: String?
    @NSManaged var locationID: String?
    @NSManaged var locationAddress: String?
    @NSManaged var locationLatitude: String?
    @NSManaged var locationLongitude: String?
    @NSManaged var caption: String?
    // no rating
    @NSManaged var userObjectID: String?
    @NSManaged var drinkObjectID: String?
}

// handled in AddRecentTableViewController in the isEqualTo function
/*
func ==(drinkOne: DrinkEntry, drinkTwo: DrinkEntry) -> Bool
{
    if drinkOne.type != drinkTwo.type
    {
        return false
    }
    else
    {
        if drinkOne.type == "beer"
        {
            return drinkOne.breweryName == drinkTwo.breweryName && drinkOne.beerName == drinkTwo.beerName && drinkOne.locationName == drinkTwo.locationName
        }
        else if drinkOne.type == "wine"
        {
            return drinkOne.vineyardName == drinkTwo.vineyardName && drinkOne.wineName == drinkTwo.wineName && drinkOne.vintage == drinkTwo.vintage && drinkOne.locationName == drinkTwo.locationName
        }
        else if drinkOne.type == "cocktail"
        {
            if drinkOne.entryMode != drinkTwo.entryMode
            {
                return false
            }
            else
            {
                if drinkOne.entryMode == 0
                {
                    return drinkOne.displayName == drinkTwo.displayName && drinkOne.effectiveDrinkCount == drinkTwo.effectiveDrinkCount && drinkOne.locationName == drinkTwo.locationName
                }
                else
                {
                    return drinkOne.displayName == drinkTwo.displayName && drinkOne.ingredients == drinkTwo.ingredients && drinkOne.locationName == drinkTwo.locationName
                }
            }
        }
        else // shots
        {
            if drinkOne.entryMode != drinkTwo.entryMode
            {
                return false
            }
            else
            {
                if drinkOne.entryMode == 0
                {
                    return drinkOne.displayName == drinkTwo.displayName && drinkOne.effectiveDrinkCount == drinkTwo.effectiveDrinkCount && drinkOne.locationName == drinkTwo.locationName
                }
                else
                {
                    return drinkOne.displayName == drinkTwo.displayName && drinkOne.ingredients == drinkTwo.ingredients && drinkOne.locationName == drinkTwo.locationName
                }
            }
        }
    }
}
*/
