//
//  HistoryTableViewCells.swift
//  Cheers
//
//  Created by Air on 8/19/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import Foundation

class HistoryBeerWineTableViewCell: UITableViewCell
{
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        cardView.layer.masksToBounds = false
        cardView.layer.shadowOpacity = 0.2
        // cardView.layer.shadowOffset = CGSizeMake(2.0, 2.0)
        cardView.layer.shadowOffset = CGSize(width: 0.0, height: 1.5)
        // default cardView.layer.shadowRadius (3)
                
        cardView.layer.shadowPath = UIBezierPath(rect: cardView.bounds).cgPath
        // cardView.layer.shadowPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 345, height: 94)).CGPath

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
            // animation.duration = 0.25
            animation.duration = 0.15
            animation.autoreverses = true
            cardView.layer.add(animation, forKey: "shadowOpacity")
            // cardView.layer.shadowOpacity = 0.0
        }
        
        super.setSelected(selected, animated: animated)
    }
}

class HistoryCocktailShotTableViewCell: UITableViewCell
{
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    
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
