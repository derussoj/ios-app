//
//  BACTableViewController.swift
//  Cheers
//
//  Created by Air on 5/10/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class BACTableViewController: UITableViewController {

    @IBOutlet weak var weightCell: UITableViewCell!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var weightDetailLabel: UILabel!
    
    @IBOutlet weak var sexCell: UITableViewCell!
    @IBOutlet weak var sexLabel: UILabel!
    @IBOutlet weak var sexDetailLabel: UILabel!
    
    @IBOutlet weak var bacSwitch: UISwitch!
    
    var alertUser:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        let defaults = UserDefaults.standard
        
        let bacEstimation = defaults.bool(forKey: "bacEstimation")
        
        if bacEstimation == false
        {
            weightCell.isUserInteractionEnabled = false
            weightLabel.isEnabled = false
            weightDetailLabel.isEnabled = false
            
            sexCell.isUserInteractionEnabled = false
            sexLabel.isEnabled = false
            sexDetailLabel.isEnabled = false
        }
        else
        {
            bacSwitch.isOn = true
        }
        
        let weight = defaults.integer(forKey: "weight")
        
        if weight > 0
        {
            weightDetailLabel.text = String(weight)
        }
        
        let sex = defaults.integer(forKey: "sex")
        
        if sex == 0
        {
            sexDetailLabel.text = "Female"
        }
        else
        {
            sexDetailLabel.text = "Male"
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        if let viewControllers = self.navigationController?.viewControllers
        {
            if viewControllers.index(of: self) == nil
            {
                let defaults = UserDefaults.standard
                let weight = defaults.integer(forKey: "weight")
                
                if weight <= 0
                {
                    defaults.set(false, forKey: "bacEstimation")
                    // Clear weight?
                }
            }
        }

        super.viewWillDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if alertUser == true
        {
            weightAlert()
            
            // Set to false?
            alertUser = false
        }
    }
    
    @IBAction func cancelWeightSelection(_ segue:UIStoryboardSegue)
    {
        let defaults = UserDefaults.standard
        let weight = defaults.integer(forKey: "weight")
        
        if weight <= 0
        {
            alertUser = true
        }
    }
    
    func weightAlert()
    {
        let alertController = UIAlertController(title: "Warning", message: "If no valid weight is entered, BAC estimation will be disabled.", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // ...
        }
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true) {
            // ...
        }
    }
    
    @IBAction func saveWeightSelection(_ segue:UIStoryboardSegue)
    {
        if let weightTableViewController = segue.source as? WeightTableViewController
        {
            weightDetailLabel.text = String(weightTableViewController.weight)
        }
    }
    
    @IBAction func cancelSexSelection(_ segue:UIStoryboardSegue)
    {
        // Do nothing.
    }
    
    @IBAction func saveSexSelection(_ segue:UIStoryboardSegue)
    {
        if let sexTableViewController = segue.source as? SexTableViewController
        {
            if sexTableViewController.selectedSexIndex == 0
            {
                sexDetailLabel.text = "Female"
            }
            else
            {
                sexDetailLabel.text = "Male"
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch)
    {
        if sender.isOn
        {
            weightCell.isUserInteractionEnabled = true
            weightLabel.isEnabled = true
            weightDetailLabel.isEnabled = true
            
            sexCell.isUserInteractionEnabled = true
            sexLabel.isEnabled = true
            sexDetailLabel.isEnabled = true
        }
        else
        {
            weightCell.isUserInteractionEnabled = false
            weightLabel.isEnabled = false
            weightDetailLabel.isEnabled = false
            
            sexCell.isUserInteractionEnabled = false
            sexLabel.isEnabled = false
            sexDetailLabel.isEnabled = false
        }
        
        let defaults = UserDefaults.standard
        defaults.set(sender.isOn, forKey: "bacEstimation")
        // Clear weight when BAC estimation is disabled?
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
