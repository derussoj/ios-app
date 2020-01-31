//
//  GeneralTableViewController.swift
//  Cheers
//
//  Created by Air on 5/16/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class GeneralTableViewController: UITableViewController {

    @IBOutlet weak var locationSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        let defaults = UserDefaults.standard
        
        let location = defaults.bool(forKey: "location")
        
        locationSwitch.isOn = location
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch)
    {
        let defaults = UserDefaults.standard
        defaults.set(sender.isOn, forKey: "location")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if indexPath.section == 0 && indexPath.row == 0
        {
            locationSwitch.setOn(!locationSwitch.isOn, animated: true)
            switchValueChanged(locationSwitch)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
