//
//  AddRecentTableViewCells.swift
//  Cheers
//
//  Created by John DeRusso on 10/3/15.
//  Copyright © 2015 Cheers. All rights reserved.
//

import Foundation

class RecentDrinkCell: UITableViewCell
{
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
}

class RecentDrinkWithLocationCell: UITableViewCell
{
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
}