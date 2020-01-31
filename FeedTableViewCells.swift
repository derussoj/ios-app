//
//  FeedTableViewCells.swift
//  Cheers
//
//  Created by John DeRusso on 9/15/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import Foundation

class FeedBeerWineTableViewCell: UITableViewCell
{
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userPhotoImageView: UIImageView!
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        cardView.layer.masksToBounds = false
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0.0, height: 1.5)
        
        cardView.layer.shadowPath = UIBezierPath(rect: cardView.bounds).cgPath
        
        cardView.layer.rasterizationScale = UIScreen.main.scale
        cardView.layer.shouldRasterize = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        if selected
        {
            let animation = CABasicAnimation(keyPath: "shadowOpacity")
            animation.fromValue = 0.2
            animation.toValue = 0.0
            animation.duration = 0.15
            animation.autoreverses = true
            cardView.layer.add(animation, forKey: "shadowOpacity")
        }
        
        super.setSelected(selected, animated: animated)
    }
}

class FeedCocktailShotTableViewCell: UITableViewCell
{
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userPhotoImageView: UIImageView!
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        cardView.layer.masksToBounds = false
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0.0, height: 1.5)
        
        cardView.layer.shadowPath = UIBezierPath(rect: cardView.bounds).cgPath
        
        cardView.layer.rasterizationScale = UIScreen.main.scale
        cardView.layer.shouldRasterize = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        if selected
        {
            let animation = CABasicAnimation(keyPath: "shadowOpacity")
            animation.fromValue = 0.2
            animation.toValue = 0.0
            animation.duration = 0.15
            animation.autoreverses = true
            cardView.layer.add(animation, forKey: "shadowOpacity")
        }
        
        super.setSelected(selected, animated: animated)
    }
}
