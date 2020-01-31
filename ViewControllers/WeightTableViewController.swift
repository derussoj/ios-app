//
//  WeightTableViewController.swift
//  Cheers
//
//  Created by Air on 5/16/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class WeightTableViewController: UITableViewController, UITextFieldDelegate {

    var weight:Int!
    @IBOutlet weak var weightTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        weightTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(WeightTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        let defaults = UserDefaults.standard
        
        let weight = defaults.integer(forKey: "weight")
        
        if weight > 0
        {
            weightTextField.text = String(weight)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        tableView.endEditing(true)
        return false
    }
    
    func hideKeyboard()
    {
        tableView.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if identifier == "SaveWeightSelection"
        {
            if weightTextField.text!.isEmpty == false
            {
                let weightDouble:Double = (weightTextField.text! as NSString).doubleValue
                weight = Int(weightDouble)
                
                if weight > 0
                {   
                    return true
                }
                else
                {
                    weightAlert()
                    
                    return false
                }
            }
            else
            {
                weightAlert()
                
                return false
            }
        }
        else
        {
            return true
        }
    }
    
    func weightAlert()
    {
        let alertController = UIAlertController(title: "Error", message: "Your weight must be a number greater than 0.", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // ...
        }
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true) {
            // ...
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        tableView.endEditing(true)
        
        if segue.identifier == "SaveWeightSelection"
        {
            // Always returns at least 0.0, right?
            let weightDouble:Double = (weightTextField.text! as NSString).doubleValue
            weight = Int(weightDouble)
            
            // Shouldn't need to recheck this here.
            if weight > 0
            {
                let defaults = UserDefaults.standard
                defaults.set(weight, forKey: "weight")
            }
        }
    }

}
