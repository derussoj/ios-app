//
//  VintageTableViewController.swift
//  Cheers
//
//  Created by Air on 6/26/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class VintageTableViewController: UITableViewController, UITextFieldDelegate {

    var vintage: String!
    
    @IBOutlet weak var vintageSwitch: UISwitch!
    @IBOutlet weak var vintageLabel: UILabel!
    
    @IBOutlet weak var yearCell: UITableViewCell!
    @IBOutlet weak var yearTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        yearTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(VintageTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        if vintage == "Non-Vintage"
        {
            vintageSwitch.isOn = false
            vintageLabel.text = "Non-Vintage"
            
            yearCell.isUserInteractionEnabled = false
            yearCell.isHidden = true
            yearCell.alpha = 0
        }
        else
        {
            vintageSwitch.isOn = true
            vintageLabel.text = "Vintage"
            
            yearTextField.text = vintage
        }
    }
    
    func hideKeyboard()
    {
        tableView.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        tableView.endEditing(true)
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch)
    {
        if sender.isOn
        {
            yearCell.isHidden = false
            
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations:
            {
                self.yearCell.alpha = 1
            }, completion: nil)
            
            yearCell.isUserInteractionEnabled = true

            vintageLabel.text = "Vintage"
        }
        else
        {
            yearCell.isUserInteractionEnabled = false
            
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations:
            {
                self.yearCell.alpha = 0
            }, completion: nil)

            vintageLabel.text = "Non-Vintage"
        }
        
        // Clear the text field when the switch is toggled off?
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if indexPath.section == 0 && indexPath.row == 0
        {
            vintageSwitch.setOn(!vintageSwitch.isOn, animated: true)
            switchValueChanged(vintageSwitch)
        }
        
        if indexPath.section == 1 && indexPath.row == 0
        {
            yearTextField.becomeFirstResponder()
        }
    }

    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if identifier == "SaveVintageToAddWine"
        {
            if vintageSwitch.isOn
            {
                yearTextField.text = yearTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if yearTextField.text!.isEmpty
                {
                    // Alert
                    
                    return false
                }
                else
                {
                    let vintageDouble: Double = (yearTextField.text! as NSString).doubleValue
                    let vintageInt: Int = Int(vintageDouble)
                    
                    if vintageInt <= 0
                    {
                        // Alert
                        
                        return false
                    }
                }
            }
        }

        return true
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        tableView.endEditing(true)
        
        if segue.identifier == "SaveVintageToAddWine"
        {
            // Check the switch?
            
            if vintageSwitch.isOn
            {
                // Trimmed and validated above.
                vintage = yearTextField.text
            }
            else
            {
                vintage = "Non-Vintage"
            }
        }
    }

}
