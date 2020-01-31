//
//  FollowPeopleTableViewCells.swift
//  Cheers
//
//  Created by John DeRusso on 1/1/16.
//  Copyright © 2016 Cheers. All rights reserved.
//

import Foundation

class FPUserTableViewCell: UITableViewCell
{
    @IBOutlet weak var userPhotoImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userDescriptionLabel: UILabel!
    @IBOutlet weak var userFollowerCountLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    // Should come in handy.
    var user: PFUser!
}
