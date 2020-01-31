//
//  AddIngredientsTableViewController.swift
//  Cheers
//
//  Created by Air on 7/4/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData

class AddIngredientsTableViewController: UITableViewController, UITextFieldDelegate
{
    var sendingView: String!
    
    // var ingredients = [Ingredient]()
    var ingredients = [TempIngredient]()
    
    var ingredientName: String? = nil
    var ingredientABV: Double? = nil
    var ingredientVolume: Double? = nil
    var ingredientVolumeUnits: Int = 0
    
    var validABV: Bool? = nil
    var validVolume: Bool? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AddIngredientsTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
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
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !textField.text!.isEmpty
        {
            // abv
            if textField.tag == 1
            {
                if let text = textField.text
                {
                    textField.text = text.substring(to: text.index(before: text.endIndex))
                }
            }
            // volume
            else if textField.tag == 2
            {
                if let text = textField.text
                {
                    textField.text = text.substring(to: text.index(text.endIndex, offsetBy: -3))
                }
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !textField.text!.isEmpty
        {
            // name
            if textField.tag == 0
            {
                ingredientName = textField.text
            }
            // abv
            else if textField.tag == 1
            {
                // checks the input and sets a variable, which is used later during validation
                let numberFormatter = NumberFormatter()
                if let abvDouble = numberFormatter.number(from: textField.text!)?.doubleValue
                {
                    ingredientABV = abvDouble
                    
                    validABV = true
                }
                else
                {
                    validABV = false
                }
                
                textField.text! += "%"
            }
            // volume
            else if textField.tag == 2
            {
                // checks the input and sets a variable, which is used later during validation
                let numberFormatter = NumberFormatter()
                if let volumeDouble = numberFormatter.number(from: textField.text!)?.doubleValue
                {
                    ingredientVolume = volumeDouble
                    
                    validVolume = true
                }
                else
                {
                    validVolume = false
                }
                
                if ingredientVolumeUnits == 0
                {
                    textField.text! += " oz"
                }
                else if ingredientVolumeUnits == 1
                {
                    textField.text! += " ml"
                }
            }
        }
        else
        {
            // volume
            if textField.tag == 2
            {
                let defaults = UserDefaults.standard
                let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
                
                // can be empty when BAC estimation is off
                if bacEstimation == nil || bacEstimation == false
                {
                    validVolume = true
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelToAddIngredients(_ segue:UIStoryboardSegue)
    {
        // Do nothing.
    }
    
    @IBAction func saveVolumeUnitsToAddIngredients(_ segue:UIStoryboardSegue)
    {
        if let volumeUnitsTableViewController = segue.source as? VolumeUnitsTableViewController
        {
            ingredientVolumeUnits = volumeUnitsTableViewController.selectedUnitsIndex!
            
            // the detail label is updated in cellForRowAtIndexPath
            let indexPath = IndexPath(row: 3, section: 0)
            tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
            
            // updates the units shown in the volume text field
            let cells = tableView.visibleCells
            for cell in cells
            {
                if let volumeCell = cell as? IngredientVolumeTableViewCell
                {
                    textFieldDidBeginEditing(volumeCell.textField)
                    textFieldDidEndEditing(volumeCell.textField)
                }
            }
        }
    }
    
    func addIngredient()
    {
        // Validate.
        let validIngredient: Bool = validateIngredient()
        
        if validIngredient == true
        {
            // Add ingredient.
            
            let ingredient = TempIngredient(name: ingredientName!)
            
            // if the volume is valid, set those properties
            
            let defaults = UserDefaults.standard
            let bacEstimation = defaults.bool(forKey: "bacEstimation")
            
            if bacEstimation == true
            {
                ingredient.abv = ingredientABV
                ingredient.volume = ingredientVolume
                ingredient.volumeUnits = ingredientVolumeUnits
            }
            else
            {
                if validVolume == true
                {
                    ingredient.volume = ingredientVolume
                    ingredient.volumeUnits = ingredientVolumeUnits
                }
            }
            
            ingredients.append(ingredient)
            
            _ = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "IngredientCell")
            // tableView.insertSubview(placeholderCell, atIndex: 0)
            // tableView.reloadData()
            let indexPath = IndexPath(row: ingredients.count - 1, section: 2)
            tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.right)
            
            // Clear textfields and ingredient variables.
            let cells = tableView.visibleCells
            for cell in cells
            {
                if let nameCell = cell as? IngredientNameTableViewCell
                {
                    nameCell.textField.text = String()
                }
                else if let abvCell = cell as? IngredientABVTableViewCell
                {
                    abvCell.textField.text = String()
                }
                else if let volumeCell = cell as? IngredientVolumeTableViewCell
                {
                    volumeCell.textField.text = String()
                }
            }
            
            ingredientName = nil
            ingredientABV = nil
            ingredientVolume = nil
            // leave ingredientVolumeUnits
            
            validVolume = nil
            validABV = nil
            
            // If it's the first ingredient (ever) added, let the user know they can swipe to delete.
        }
    }
    
    func validateIngredient() -> Bool
    {
        if ingredientName == nil
        {
            // Alert.
            
            return false
        }
        else if ingredientName!.isEmpty
        {
            // Alert.
            
            return false
        }
        
        let defaults = UserDefaults.standard
        let bacEstimation = defaults.bool(forKey: "bacEstimation")
        
        if bacEstimation == true
        {
            // if ingredientABV == nil
            if validABV == nil
            {
                // ABV was never entered (or at least the text field was empty after trimming).
                // Alert.
                
                return false
            }
            else if validABV == false
            {
                // Alert.
                
                return false
            }
            
            // if ingredientVolume == nil
            if validVolume == nil
            {
                // Volume was never entered (or at least the text field was empty after trimming).
                // Alert.
                
                return false
            }
            else if validVolume == false
            {
                // Alert.
                
                return false
            }
        }
        else
        {
            // Right now, the volume property is set as a number (double). This is also true on Parse.
            // Unless I'm going to switch everything to strings, the volume has to be either blank or a number.
            
            // Nil or true is fine, false is not.
            if validVolume == false
            {
                // Alert.
                
                return false
            }
        }
        
        return true
    }

    @IBAction func cancelAction(_ sender: UIBarButtonItem)
    {
        tableView.endEditing(true)
        
        if sendingView == "AddCocktail"
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
        tableView.endEditing(true)
        
        if validateUserEntries() == true
        {
            if sendingView == "AddCocktail"
            {
                performSegue(withIdentifier: "SaveIngredientsToAddCocktail", sender: self)
            }
            else if sendingView == "AddShot"
            {
                performSegue(withIdentifier: "SaveIngredientsToAddShot", sender: self)
            }
        }
    }
    
    func validateUserEntries() -> Bool
    {
        if ingredients.count == 0
        {
            // Alert.
                
            return false
        }
        
        return true
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return 4
        }
        else if section == 1
        {
            return 1
        }
        else
        {
            return ingredients.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let abvIndexPath = IndexPath(row: 1, section: 0)
        
        if indexPath == abvIndexPath
        {
            let defaults = UserDefaults.standard
            let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
            
            if bacEstimation == nil || bacEstimation == false
            {
                return 0
            }
        }
        
        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell: UITableViewCell
        
        if indexPath.section == 0
        {
            if indexPath.row == 0
            {
                let nameCell = tableView.dequeueReusableCell(withIdentifier: "NameCell", for: indexPath as IndexPath) as! IngredientNameTableViewCell
                nameCell.textField.tag = 0
                nameCell.textField.delegate = self
                
                return nameCell
            }
            else if indexPath.row == 1
            {
                let abvCell = tableView.dequeueReusableCell(withIdentifier: "ABVCell", for: indexPath as IndexPath) as! IngredientABVTableViewCell
                
                abvCell.textField.tag = 1
                abvCell.textField.delegate = self
                
                let defaults = UserDefaults.standard
                let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
                
                if bacEstimation == nil || bacEstimation == false
                {
                    // prevents tabbing to the text field when the cell is collapsed
                    abvCell.textField.isHidden = true
                }
                
                return abvCell
            }
            else if indexPath.row == 2
            {
                let volumeCell = tableView.dequeueReusableCell(withIdentifier: "VolumeCell", for: indexPath as IndexPath) as! IngredientVolumeTableViewCell
                volumeCell.textField.tag = 2
                volumeCell.textField.delegate = self
                
                return volumeCell
            }
            else
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "UnitsCell", for: indexPath as IndexPath) 
                if ingredientVolumeUnits == 0
                {
                    cell.detailTextLabel?.text = "oz"
                }
                else
                {
                    cell.detailTextLabel?.text = "ml"
                }
            }
        }
        else if indexPath.section == 1
        {
            cell = tableView.dequeueReusableCell(withIdentifier: "AddCell", for: indexPath as IndexPath)
        }
        else
        {
            cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath as IndexPath) 
            
            let ingredient = ingredients[indexPath.row] as TempIngredient
            
            let defaults = UserDefaults.standard
            let bacEstimation = defaults.bool(forKey: "bacEstimation")
            
            if bacEstimation == true
            {
                if ingredient.volumeUnits == 0
                {
                    cell.textLabel?.text = "\(ingredient.volume!) oz of \(ingredient.name) (\(ingredient.abv!)% ABV)"
                }
                else
                {
                    cell.textLabel?.text = "\(ingredient.volume!) ml of \(ingredient.name) (\(ingredient.abv!)% ABV)"
                }
            }
            else
            {
                if ingredient.volume != nil
                {
                    if ingredient.volumeUnits == 0
                    {
                        cell.textLabel?.text = "\(ingredient.volume!) oz of \(ingredient.name)"
                    }
                    else
                    {
                        cell.textLabel?.text = "\(ingredient.volume!) ml of \(ingredient.name)"
                    }
                }
                else
                {
                    cell.textLabel?.text = "\(ingredient.name)"
                }
            }
        }
        
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        if indexPath.section == 2
        {
            return true
        }
        else
        {
            return false
        }
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            // Delete the row from the data source
            ingredients.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath as IndexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        // should only be one cell in this section (the "add" cell)
        if indexPath.section == 1
        {
            addIngredient()
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "UnitsSelection"
        {
            if let unitsTableViewController = segue.destination as? VolumeUnitsTableViewController
            {
                unitsTableViewController.sendingView = "AddIngredients"
                
                if ingredientVolumeUnits == 0
                {
                    unitsTableViewController.selectedUnitsIndex = 0
                }
                else
                {
                    unitsTableViewController.selectedUnitsIndex = 1
                }
            }
        }
    }

}
