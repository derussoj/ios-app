//
//  MoreTableViewController.swift
//  Cheers
//
//  Created by John DeRusso on 9/29/15.
//  Copyright © 2015 Cheers. All rights reserved.
//

import UIKit

class MoreTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(MoreTableViewController.swipedRight))
        rightSwipeGesture.direction = .right
        self.view.addGestureRecognizer(rightSwipeGesture)
        
        self.tabBarController?.view.backgroundColor = UIColor.white
    }
    
    func swipedRight()
    {
        guard let tbc = self.tabBarController
            else { return }
        
        guard let fromView = tbc.selectedViewController?.view
            else { return }
        
        guard let toView = tbc.viewControllers?[tbc.selectedIndex - 1].view
            else { return }
        
        fromView.superview?.addSubview(toView)
        
        let offScreenRight = CGAffineTransform(translationX: fromView.frame.width, y: 0)
        let offScreenLeft = CGAffineTransform(translationX: -fromView.frame.width, y: 0)
        
        toView.transform = offScreenLeft
        
        UIView.animate(withDuration: 0.4, animations:
        {
            fromView.transform = offScreenRight
            toView.transform = CGAffineTransform.identity
        },
        completion:
        {
            finished in
                
            if finished
            {
                fromView.removeFromSuperview()
                    
                tbc.selectedIndex -= 1
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
