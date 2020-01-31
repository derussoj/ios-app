//
//  CaptionTableViewController.swift
//  Cheers
//
//  Created by Air on 5/30/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class CaptionTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var captionTextField: UITextField!
    
    var caption: String!
    
    var sendingView: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        captionTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CaptionTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)

        if caption != nil
        {
            captionTextField.text = caption
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if indexPath.section == 0 && indexPath.row == 0
        {
            captionTextField.becomeFirstResponder()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cancelAction(_ sender: UIBarButtonItem)
    {
        if sendingView == "AddBeer"
        {
            performSegue(withIdentifier: "CancelToAddBeer", sender: self)
        }
        else if sendingView == "AddWine"
        {
            performSegue(withIdentifier: "CancelToAddWine", sender: self)
        }
        else if sendingView == "AddCocktail"
        {
            performSegue(withIdentifier: "CancelToAddCocktail", sender: self)
        }
        else if sendingView == "AddShot"
        {
            performSegue(withIdentifier: "CancelToAddShot", sender: self)
        }
    }
    
    @IBAction func saveAction(_ sender: UIBarButtonItem)
    {
        if sendingView == "AddBeer"
        {
            performSegue(withIdentifier: "SaveCaptionToAddBeer", sender: self)
        }
        else if sendingView == "AddWine"
        {
            performSegue(withIdentifier: "SaveCaptionToAddWine", sender: self)
        }
        else if sendingView == "AddCocktail"
        {
            performSegue(withIdentifier: "SaveCaptionToAddCocktail", sender: self)
        }
        else if sendingView == "AddShot"
        {
            performSegue(withIdentifier: "SaveCaptionToAddShot", sender: self)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        tableView.endEditing(true)
        
        if segue.identifier == "SaveCaptionToAddBeer" || segue.identifier == "SaveCaptionToAddWine" || segue.identifier == "SaveCaptionToAddCocktail" || segue.identifier == "SaveCaptionToAddShot"
        {
            // Validate above. Or maybe the user needs to be able to clear it? Can clear by swiping.
            
            caption = captionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

}
