//
//  Location.swift
//  Cheers
//
//  Created by Air on 5/27/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import Foundation

class Place: NSObject
{
    var name: String?
    var id: String?
    var address: String?
    var latitude: String?
    var longitude: String?
}

class MostRecentLocation: NSObject, NSCoding
{
    var name: String
    var id: String
    var address: String?
    var latitude: String?
    var longitude: String?
    
    init (name: String, id: String)
    {
        self.name = name
        self.id = id
        
        super.init()
    }
    
    required init(coder aDecoder: NSCoder)
    {
        name = aDecoder.decodeObject(forKey: "name") as! String
        id = aDecoder.decodeObject(forKey: "id") as! String
        address = aDecoder.decodeObject(forKey: "address") as? String
        latitude = aDecoder.decodeObject(forKey: "latitude") as? String
        longitude = aDecoder.decodeObject(forKey: "longitude") as? String
    }
    
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(id, forKey: "id")
        aCoder.encode(address, forKey: "address")
        aCoder.encode(latitude, forKey: "latitude")
        aCoder.encode(longitude, forKey: "longitude")
    }
}
