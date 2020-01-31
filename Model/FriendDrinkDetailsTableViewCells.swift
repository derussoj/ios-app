//
//  FriendDrinkDetailsTableViewCells.swift
//  Cheers
//
//  Created by John DeRusso on 11/3/15.
//  Copyright © 2015 Cheers. All rights reserved.
//

import Foundation

class FDDFriendTableViewCell: UITableViewCell
{
    @IBOutlet weak var friendPhotoImageView: UIImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
}

class FDDNameTableViewCell: UITableViewCell
{
    @IBOutlet weak var cellNameLabel: UILabel!
    @IBOutlet weak var drinkEntryNameLabel: UILabel!
}

class FDDSourceTableViewCell: UITableViewCell
{
    @IBOutlet weak var cellSourceLabel: UILabel!
    @IBOutlet weak var drinkEntrySourceLabel: UILabel!
}

class FDDVintageTableViewCell: UITableViewCell
{
    @IBOutlet weak var drinkEntryVintageLabel: UILabel!
}

class FDDIngredientsTableViewCell: UITableViewCell
{
    @IBOutlet weak var drinkEntryIngredientsLabel: UILabel!
}

class FDDDateTimeTableViewCell: UITableViewCell
{
    @IBOutlet weak var drinkEntryDateTimeLabel: UILabel!
}

class FDDLocationTableViewCell: UITableViewCell
{
    @IBOutlet weak var drinkEntryLocationLabel: UILabel!
}

class FDDCaptionTableViewCell: UITableViewCell
{
    @IBOutlet weak var drinkEntryCaptionLabel: UILabel!
}

class FDDLikesTableViewCell: UITableViewCell
{
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
}

// same class for both the CommentCell and the UserCommentCell
class FDDCommentTableViewCell: UITableViewCell
{
    @IBOutlet weak var commenterImageView: UIImageView!
    @IBOutlet weak var commenterLabel: UILabel!
    @IBOutlet weak var commentTextLabel: UILabel!
    @IBOutlet weak var commentDateTimeLabel: UILabel!
    var comment: ParseComment!
}

class FDDAddCommentTableViewCell: UITableViewCell
{
    @IBOutlet weak var addCommentTextView: UITextView!
}

class FDDEditCommentTableViewCell: UITableViewCell
{
    @IBOutlet weak var editCommentTextView: UITextView!
}
