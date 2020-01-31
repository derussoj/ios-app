//
//  AddShotTableViewController.swift
//  Cheers
//
//  Created by Air on 8/2/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData
import Parse

class AddShotTableViewController: UITableViewController, UITextFieldDelegate
{
    var entryMode: Int = 0
    
    var ingredients = [TempIngredient]()
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var drinksTextField: UITextField!
    
    @IBOutlet weak var entryModeDetailLabel: UILabel!
    @IBOutlet weak var ingredientsDetailLabel: UILabel!
    @IBOutlet weak var timeDetailLabel: UILabel!
    @IBOutlet weak var dateDetailLabel: UILabel!
    @IBOutlet weak var locationDetailLabel: UILabel!
    @IBOutlet weak var captionDetailLabel: UILabel!
    
    var selectedDateTime: Date!
    var locationName: String!
    var locationID: String!
    var locationAddress: String?
    var locationLatitude: String?
    var locationLongitude: String?
    var caption: String!
    
    var shouldLoadRecentDrink: Bool = false
    var recentDrink: DrinkEntry?
    
    var editingDrink: Bool = false
    var drinkBeingEdited: DrinkEntry?
    @IBOutlet weak var navBar: UINavigationItem!
    
    var hasUnsavedChanges: Bool = false
    
    // for the activity indicator
    let activityIndicator = UIActivityIndicatorView()
    let overlay = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        nameTextField.delegate = self
        drinksTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AddShotTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        if entryMode == 0
        {
            entryModeDetailLabel.text = "Quick"
            
            // probably don't need this
            drinksTextField.isHidden = false
        }
        else
        {
            entryModeDetailLabel.text = "Full"
            
            // prevents tabbing to the text field when the cell is collapsed
            drinksTextField.isHidden = true
        }
        
        selectedDateTime = Date()
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = DateFormatter.Style.short
        let selectedTimeString = timeFormatter.string(from: selectedDateTime)
        timeDetailLabel.text = selectedTimeString
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        let selectedDateString = dateFormatter.string(from: selectedDateTime)
        dateDetailLabel.text = selectedDateString
        
        locationDetailLabel.text = " "
        captionDetailLabel.text = " "
        ingredientsDetailLabel.text = " "
        
        if shouldLoadRecentDrink == true
        {
            loadRecentDrink()
        }
        else if editingDrink == true
        {
            loadDrinkBeingEdited()
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
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField)
    {
        hasUnsavedChanges = true
    }
    

    func loadRecentDrink()
    {
        nameTextField.text = recentDrink?.displayName
        
        // !, ? because of how entryMode is declared
        entryMode = recentDrink!.entryMode!.intValue
        if entryMode == 0
        {
            entryModeDetailLabel.text = "Quick"
            
            // probably don't need this
            drinksTextField.isHidden = false
            
            let defaults = UserDefaults.standard
            let bacEstimation = defaults.bool(forKey: "bacEstimation")
            
            if bacEstimation == true && recentDrink?.bacEstimation == true
            {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                    
                drinksTextField.text = numberFormatter.string(from: recentDrink!.effectiveDrinkCount!)
            }
        }
        else
        {
            entryModeDetailLabel.text = "Full"
            
            // prevents tabbing to the text field when the cell is collapsed
            drinksTextField.isHidden = true
            
            let recentIngredientsSet = recentDrink?.ingredients
            let recentIngredientsArray = recentIngredientsSet?.array as! [Ingredient]
            for ingredient in recentIngredientsArray
            {
                let tempIngredient = TempIngredient(name: ingredient.name)
                
                if ingredient.volume != nil
                {
                    tempIngredient.volume = ingredient.volume?.doubleValue
                    tempIngredient.volumeUnits = ingredient.volumeUnits?.intValue
                }
                if ingredient.abv != nil
                {
                    tempIngredient.abv = ingredient.abv?.doubleValue
                }
                
                ingredients.append(tempIngredient)
            }
            
            // Should always be at least 1 ingredient.
            var ingredientsString: String = ingredients[0].name
            
            var i = 1
            let n = ingredients.count
            while i < n
            {
                ingredientsString = "\(ingredientsString), \(ingredients[i].name)"
                
                i += 1
            }
            
            ingredientsDetailLabel.text = ingredientsString
        }
        
        if recentDrink?.locationName != nil && recentDrink?.locationID != nil
        {
            locationName = recentDrink?.locationName
            locationID = recentDrink?.locationID
            
            locationDetailLabel.text = locationName
            
            if let address = recentDrink?.locationAddress
            {
                locationAddress = address
            }
            
            if let latitude = recentDrink?.locationLatitude
            {
                if let longitude = recentDrink?.locationLongitude
                {
                    locationLatitude = latitude
                    locationLongitude = longitude
                }
            }
        }
        
        // ignore the caption?
        
        // Update the view.
        tableView.reloadData()
    }
    
    func loadDrinkBeingEdited()
    {
        navBar.title = "Edit Shot"
        
        nameTextField.text = drinkBeingEdited?.displayName
        
        // !, ? because of how entryMode is declared
        entryMode = drinkBeingEdited!.entryMode!.intValue
        
        if entryMode == 0
        {
            entryModeDetailLabel.text = "Quick"
            
            // probably don't need this
            drinksTextField.isHidden = false
            
            let defaults = UserDefaults.standard
            let bacEstimation = defaults.bool(forKey: "bacEstimation")
            
            if bacEstimation == true && drinkBeingEdited?.bacEstimation == true
            {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                    
                drinksTextField.text = numberFormatter.string(from: drinkBeingEdited!.effectiveDrinkCount!)
            }
        }
        else
        {
            entryModeDetailLabel.text = "Full"
            
            // prevents tabbing to the text field when the cell is collapsed
            drinksTextField.isHidden = true
            
            let ingredientsSet = drinkBeingEdited?.ingredients
            let ingredientsArray = ingredientsSet?.array as! [Ingredient]
            for ingredient in ingredientsArray
            {
                let tempIngredient = TempIngredient(name: ingredient.name)
                
                if ingredient.volume != nil
                {
                    tempIngredient.volume = ingredient.volume?.doubleValue
                    tempIngredient.volumeUnits = ingredient.volumeUnits?.intValue
                }
                if ingredient.abv != nil
                {
                    tempIngredient.abv = ingredient.abv?.doubleValue
                }
                
                ingredients.append(tempIngredient)
            }
            
            // Should always be at least 1 ingredient.
            var ingredientsString: String = ingredients[0].name
            
            var i = 1
            let n = ingredients.count
            while i < n
            {
                ingredientsString = "\(ingredientsString), \(ingredients[i].name)"
                
                i += 1
            }
            
            ingredientsDetailLabel.text = ingredientsString
        }
        
        let defaults = UserDefaults.standard
        let bacEstimation = defaults.bool(forKey: "bacEstimation")
        
        if bacEstimation == true
        {
            // universalDateTime or selectedDateTime?
            // if BAC estimation was off when the drink was saved, either one will also match savedDateTime
            selectedDateTime = drinkBeingEdited?.universalDateTime
            
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = DateFormatter.Style.short
            let selectedTimeString = timeFormatter.string(from: selectedDateTime)
            timeDetailLabel.text = selectedTimeString
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.medium
            let selectedDateString = dateFormatter.string(from: selectedDateTime)
            dateDetailLabel.text = selectedDateString
        }
        
        if drinkBeingEdited?.locationName != nil && drinkBeingEdited?.locationID != nil
        {
            locationName = drinkBeingEdited?.locationName
            locationID = drinkBeingEdited?.locationID
            
            locationDetailLabel.text = locationName
            
            if let address = drinkBeingEdited?.locationAddress
            {
                locationAddress = address
            }
            
            if let latitude = drinkBeingEdited?.locationLatitude
            {
                if let longitude = drinkBeingEdited?.locationLongitude
                {
                    locationLatitude = latitude
                    locationLongitude = longitude
                }
            }
        }
        
        if drinkBeingEdited?.caption != nil
        {
            caption = drinkBeingEdited?.caption
            
            captionDetailLabel.text = caption
        }
        
        // Update the view.
        tableView.reloadData()
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem)
    {
        tableView.endEditing(true)
        
        if hasUnsavedChanges == true
        {
            unsavedChangesAlert()
        }
        else
        {
            if editingDrink == true
            {
                performSegue(withIdentifier: "CancelToHistoryDetails", sender: self)
            }
            else if shouldLoadRecentDrink == true
            {
                performSegue(withIdentifier: "CancelToAddRecent", sender: self)
            }
            else
            {
                performSegue(withIdentifier: "CancelToAddDrink", sender: self)
            }
        }
    }
    
    func unsavedChangesAlert()
    {
        let alertController = UIAlertController(title: "Warning", message: "Are you sure you want to cancel? Any information you've entered will be lost.", preferredStyle: .alert)
        
        let NoAction = UIAlertAction(title: "No", style: .default) { (action) in
            // ...
        }
        alertController.addAction(NoAction)
        
        let YesAction = UIAlertAction(title: "Yes", style: .default)
        {
            (action) in
            
            if self.editingDrink == true
            {
                self.performSegue(withIdentifier: "CancelToHistoryDetails", sender: self)
            }
            else if self.shouldLoadRecentDrink == true
            {
                self.performSegue(withIdentifier: "CancelToAddRecent", sender: self)
            }
            else
            {
                self.performSegue(withIdentifier: "CancelToAddDrink", sender: self)
            }
        }
        alertController.addAction(YesAction)
        
        self.present(alertController, animated: true) {
            // ...
        }
    }
    
    @IBAction func saveAction(_ sender: UIBarButtonItem)
    {
        tableView.endEditing(true)
        
        if validateUserEntries() == true
        {
            showActivityIndicator(shouldShow: true)
            
            if editingDrink == true
            {
                DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async
                {
                    // Edit Parse drink entry
                    if let objectID = self.drinkBeingEdited?.drinkObjectID
                    {
                        if !objectID.isEmpty
                        {
                            let currentUser = PFUser.current()
                            if currentUser != nil
                            {
                                self.editParseDrink(objectID: objectID)
                            }
                            else
                            {
                                // The drinkEntry has an objectID but the user is no longer logged in
                                // Alert the user that the drinkEntry won't be edited unless they log back in
                                
                                // Also, break the function here?
                            }
                        }
                    }
                    
                    DispatchQueue.main.async
                    {
                        // Edit local drink entry
                        self.editLocalDrink()
                        
                        self.showActivityIndicator(shouldShow: false)
                        
                        self.performSegue(withIdentifier: "SaveEditedDrink", sender: self)
                    }
                }
            }
            else
            {
                // For consistency.
                let dateTimeNow = Date()
                
                var objectID: String = String()
                
                DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async
                {
                    let currentUser = PFUser.current()
                    if currentUser != nil
                    {
                        objectID = self.saveDrinkToParse(currentDateTime: dateTimeNow)
                    }
                    
                    DispatchQueue.main.async
                    {
                        // What should I pass in for the objectID when there's no Parse user? Empty string?
                        self.saveDrinkLocally(currentDateTime: dateTimeNow, objectID: objectID)
                        
                        self.showActivityIndicator(shouldShow: false)
                        
                        self.performSegue(withIdentifier: "SaveDrink", sender: self)
                    }
                }
            }
        }
    }
    
    func validateUserEntries() -> Bool
    {
        trimTextFields()
        
        if nameTextField.text!.isEmpty
        {
            // Alert
            
            return false
        }
        
        if entryMode == 1
        {
            // Probably don't need the less than.
            if ingredients.count <= 0
            {
                // Alert
                
                return false
            }
        }
        
        let defaults = UserDefaults.standard
        let bacEstimation = defaults.bool(forKey: "bacEstimation")
        
        if bacEstimation == true && entryMode == 0
        {
            if drinksTextField.text!.isEmpty
            {
                // Alert
                
                return false
            }
            
            let numberFormatter = NumberFormatter()
            if let drinksDouble = numberFormatter.number(from: drinksTextField.text!)?.doubleValue
            {
                // I guess 0 is fine? Why not?
                if drinksDouble < 0
                {
                    // Alert
                    
                    return false
                }
            }
            else
            {
                // Alert
                
                return false
            }
        }

        return true
    }
    
    func trimTextFields()
    {
        nameTextField.text = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let defaults = UserDefaults.standard
        let bacEstimation = defaults.bool(forKey: "bacEstimation")
        
        if bacEstimation == true && entryMode == 0
        {
            drinksTextField.text = drinksTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func showActivityIndicator(shouldShow: Bool)
    {
        if shouldShow == true
        {
            overlay.frame = view.frame
            overlay.center = view.center
            overlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
            
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
            activityIndicator.color = UIColor(red: 56/255.0, green: 207/255.0, blue: 166/255.0, alpha: 1)
            
            let container = UIView()
            container.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            container.center = CGPoint(x: overlay.frame.size.width / 2, y: overlay.frame.size.height / 2)
            container.backgroundColor = UIColor.white
            container.layer.cornerRadius = 10
            container.clipsToBounds = true
            
            activityIndicator.center = CGPoint(x: container.frame.size.width / 2, y: container.frame.size.height / 2)
            
            container.addSubview(activityIndicator)
            overlay.addSubview(container)
            
            activityIndicator.startAnimating()
            
            navigationController?.view.addSubview(overlay)
        }
        else
        {
            overlay.removeFromSuperview()
            
            activityIndicator.stopAnimating()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelToAddShot(_ segue:UIStoryboardSegue)
    {
        // Do nothing.
    }
    
    @IBAction func saveEntryModeToAddShot(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let entryModeTableViewController = segue.source as? EntryModeTableViewController
        {
            entryMode = entryModeTableViewController.selectedEntryModeIndex!
            
            if entryMode == 0
            {
                entryModeDetailLabel.text = "Quick"
                
                // in case the entry mode is switched from full to quick
                drinksTextField.isHidden = false
            }
            else
            {
                entryModeDetailLabel.text = "Full"
                
                // prevents tabbing to the text field when the cell is collapsed
                drinksTextField.isHidden = true
            }
            
            // Update the view.
            tableView.reloadData()
        }
    }
    
    @IBAction func saveIngredientsToAddShot(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let addIngredientsTableViewController = segue.source as? AddIngredientsTableViewController
        {
            ingredients = addIngredientsTableViewController.ingredients
            
            // Should always be at least 1 ingredient.
            var ingredientsString: String = ingredients[0].name
            
            var i = 1
            let n = ingredients.count
            while i < n
            {
                ingredientsString = "\(ingredientsString), \(ingredients[i].name)"
                
                i += 1
            }
            
            ingredientsDetailLabel.text = ingredientsString
        }
    }
    
    @IBAction func saveTimeToAddShot(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let timeViewController = segue.source as? TimeViewController
        {
            // Can I use the same variable for the time and date?
            selectedDateTime = timeViewController.selectedTime
            
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = DateFormatter.Style.short
            let selectedTimeString = timeFormatter.string(from: selectedDateTime)
            timeDetailLabel.text = selectedTimeString
        }
    }
    
    @IBAction func saveDateToAddShot(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let dateViewController = segue.source as? DateViewController
        {
            // Can I use the same variable for the time and date?
            selectedDateTime = dateViewController.selectedDate
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.medium
            let selectedDateString = dateFormatter.string(from: selectedDateTime)
            dateDetailLabel.text = selectedDateString
        }
    }
    
    @IBAction func saveLocationToAddShot(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let locationTableViewController = segue.source as? LocationTableViewController
        {
            locationName = locationTableViewController.selectedLocationName
            locationID = locationTableViewController.selectedLocationID
            
            locationDetailLabel.text = locationName
            
            if let address = locationTableViewController.selectedLocationAddress
            {
                locationAddress = address
            }
            
            if let latitude = locationTableViewController.selectedLocationLatitude
            {
                if let longitude = locationTableViewController.selectedLocationLongitude
                {
                    locationLatitude = latitude
                    locationLongitude = longitude
                }
            }
            
            // If it's the first time, use an Alert to let users know about swiping to clear.
        }
    }
    
    @IBAction func saveCaptionToAddShot(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let captionTableViewController = segue.source as? CaptionTableViewController
        {
            caption = captionTableViewController.caption
            
            captionDetailLabel.text = caption
        }
    }
    
    @IBAction func saveShotToAddShot(_ segue:UIStoryboardSegue)
    {
        /*
        if let shotSearchTableViewController = segue.sourceViewController as? ShotSearchTableViewController
        {
        // Get selected shot from shotSearchTableViewController and update the name and ingredients.
        }
        */
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let defaults = UserDefaults.standard
        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
        
        if section == 0
        {
            return 1
        }
        else if section == 1
        {
            if entryMode == 0
            {
                if bacEstimation == true
                {
                    return 2
                }
                else
                {
                    return 1
                }
            }
            else
            {
                return 3
            }
        }
        else
        {
            return 4
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let defaults = UserDefaults.standard
        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
        
        let timeIndexPath = IndexPath(row: 0, section: 2)
        let dateIndexPath = IndexPath(row: 1, section: 2)
        
        if bacEstimation == false
        {
            if indexPath == timeIndexPath || indexPath == dateIndexPath
            {
                return 0
            }
        }
        
        let drinksIndexPath = IndexPath(row: 1, section: 1)
        
        if entryMode == 1
        {
            if indexPath == drinksIndexPath
            {
                return 0
            }
        }
        
        return UITableViewAutomaticDimension
    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }
    */

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        if indexPath.section == 1
        {
            if indexPath.row == 0
            {
                return true
            }
            else if indexPath.row == 1
            {
                return true
            }
            else if indexPath.row == 2
            {
                return true
            }
        }
        else if indexPath.section == 2
        {
            if indexPath.row == 2
            {
                return true
            }
            else if indexPath.row == 3
            {
                return true
            }
        }
        
        return false
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // Nothing.
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let clearAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Clear", handler:
        {
            (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
                
            if indexPath.section == 1
            {
                if indexPath.row == 0
                {
                    self.nameTextField.text = String()
                }
                else if indexPath.row == 1
                {
                    self.drinksTextField.text = String()
                }
                else if indexPath.row == 2
                {
                    self.ingredients.removeAll()
                    self.ingredientsDetailLabel.text = " "
                }
            }
            else if indexPath.section == 2
            {
                if indexPath.row == 2
                {
                    self.locationDetailLabel.text = " "
                    self.locationName = nil
                    self.locationID = nil
                    self.locationAddress = nil
                    self.locationLatitude = nil
                    self.locationLongitude = nil
                }
                else if indexPath.row == 3
                {
                    self.captionDetailLabel.text = " "
                    self.caption = nil
                }
            }
                
            // Animation.
            self.tableView.setEditing(false, animated: true)
        })
        
        clearAction.backgroundColor = UIColor(red: 0.298, green: 0.831, blue: 0.686, alpha: 1)
        
        return [clearAction]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if indexPath.section == 1
        {
            if indexPath.row == 0
            {
                nameTextField.becomeFirstResponder()
            }
            else if indexPath.row == 1
            {
                drinksTextField.becomeFirstResponder()
            }
        }
    }

    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        // Is this going to be a thing? Probably fine if it's empty actually.
        if identifier == "ShotSelection"
        {
            nameTextField.text = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if nameTextField.text!.isEmpty == true
            {
                // Alert
                
                return false
            }
        }
        
        return true
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "EntryModeSelection"
        {
            if let entryModeTableViewController = segue.destination as? EntryModeTableViewController
            {
                entryModeTableViewController.sendingView = "AddShot"
                
                entryModeTableViewController.selectedEntryModeIndex = entryMode
            }
        }
            
        else if segue.identifier == "AddIngredients"
        {
            if let addIngredientsTableViewController = segue.destination as? AddIngredientsTableViewController
            {
                addIngredientsTableViewController.sendingView = "AddShot"
                
                addIngredientsTableViewController.ingredients = ingredients
            }
        }
            
        else if segue.identifier == "TimeSelection"
        {
            if let timeViewController = segue.destination as? TimeViewController
            {
                timeViewController.sendingView = "AddShot"
                
                timeViewController.selectedTime = selectedDateTime
            }
        }
            
        else if segue.identifier == "DateSelection"
        {
            if let dateViewController = segue.destination as? DateViewController
            {
                dateViewController.sendingView = "AddShot"
                
                dateViewController.selectedDate = selectedDateTime
            }
        }
            
        else if segue.identifier == "LocationSelection"
        {
            if let locationTableViewController = segue.destination as? LocationTableViewController
            {
                locationTableViewController.sendingView = "AddShot"
            }
        }
            
        else if segue.identifier == "CaptionEntry"
        {
            if let captionTableViewController = segue.destination as? CaptionTableViewController
            {
                captionTableViewController.sendingView = "AddShot"
                
                captionTableViewController.caption = caption
            }
        }
            
        // Not sure about this one. See above.
        else if segue.identifier == "ShotSelection"
        {
            /*
            if let shotSearchTableViewController = segue.destinationViewController.topViewController as? ShotSearchTableViewController
            {
                var shotText = nameTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
                // Validate this above?
                shotText = shotText.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            
                shotSearchTableViewController.searchText = shotText
            }
            */
        }
    }
    
    // no longer used
    func saveDrinkToParse(currentDateTime: Date) -> String
    {
        let defaults = UserDefaults.standard
        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
        
        let drinkEntry = ParseDrinkEntry()
        
        drinkEntry.parseUser = PFUser.current()!
        
        drinkEntry.displayName = nameTextField.text!
        drinkEntry.cocktailEntryMode = entryMode
        
        if locationName != nil && locationID != nil
        {
            drinkEntry.locationName = locationName
            drinkEntry.locationID = locationID
            
            if locationAddress != nil
            {
                drinkEntry.locationAddress = locationAddress
            }
            
            // to stop the errors until this function is commented out
            if locationLatitude != nil && locationLongitude != nil
            {
                drinkEntry.locationCoordinates = "\(locationLatitude), \(locationLongitude)"
            }
        }
        
        if caption != nil
        {
            drinkEntry.caption = caption
        }
        drinkEntry.commentNumber = 0
        drinkEntry.likeCount = 0
        
        drinkEntry.type = "shot"
        drinkEntry.os = "iOS"
        
        if entryMode == 0 && bacEstimation == true
        {
            drinkEntry.effectiveDrinkCount = (drinksTextField.text! as NSString).doubleValue
        }
        else if entryMode == 1
        {
            // Convert the ingredients.
            var parseIngredients = [ParseIngredient]()
            for ingredient in ingredients
            {
                let parseIngredient = ParseIngredient()
                parseIngredient.parseIngredientName = ingredient.name
                if ingredient.volume != nil
                {
                    parseIngredient.parseIngredientVolume = ingredient.volume!
                    parseIngredient.parseIngredientUnits = ingredient.volumeUnits!
                }
                if ingredient.abv != nil
                {
                    parseIngredient.parseIngredientAlcoholContent = ingredient.abv!
                }
                
                parseIngredients.append(parseIngredient)
            }
            
            drinkEntry.ingredients = parseIngredients
            
            if bacEstimation == true
            {
                let effectiveDrinks = calculateEffectiveDrinkCount()
                
                drinkEntry.effectiveDrinkCount = effectiveDrinks
            }
        }
        
        if bacEstimation == true
        {
            // drinkEntry.bacEstimation = true
            // Otherwise, this won't work on iOS 7.1
            drinkEntry["bacEstimation"] = true
            
            drinkEntry.savedDateTime = currentDateTime
            // Do I even use the selectedDateTime for anything? Should I save the current timezone?
            drinkEntry.selectedDateTime = selectedDateTime
            drinkEntry.universalDateTime = selectedDateTime
        }
        else
        {
            // drinkEntry.bacEstimation = false
            // Otherwise, this won't work on iOS 7.1
            drinkEntry["bacEstimation"] = false
            
            drinkEntry.savedDateTime = currentDateTime
            // Do I even use the selectedDateTime for anything? Should I save the current timezone?
            drinkEntry.selectedDateTime = currentDateTime
            drinkEntry.universalDateTime = currentDateTime
        }
        
        do
        {
            try drinkEntry.save()
        }
        catch
        {
            drinkEntry.saveEventually()
        }
        
        if let objectID: String = drinkEntry.objectId
        {
            print("objectID is \(objectID)")
            
            return objectID
        }
        else
        {
            print("objectID is nil")
            
            return String()
        }
    }
    
    func saveDrinkLocally(currentDateTime: Date, objectID: String)
    {
        let defaults = UserDefaults.standard
        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let drinkEntity =  NSEntityDescription.entity(forEntityName: "DrinkEntry", in: managedContext)
        let drinkEntry = NSManagedObject(entity: drinkEntity!, insertInto: managedContext)
        
        drinkEntry.setValue(nameTextField.text, forKey: "displayName")
        drinkEntry.setValue(entryMode, forKey: "entryMode")
        
        if locationName != nil && locationID != nil
        {
            drinkEntry.setValue(locationName, forKey: "locationName")
            drinkEntry.setValue(locationID, forKey: "locationID")
            
            if locationAddress != nil
            {
                drinkEntry.setValue(locationAddress, forKey: "locationAddress")
            }
            
            if locationLatitude != nil && locationLongitude != nil
            {
                drinkEntry.setValue(locationLatitude, forKey: "locationLatitude")
                drinkEntry.setValue(locationLongitude, forKey: "locationLongitude")
            }
        }
        
        if caption != nil
        {
            drinkEntry.setValue(caption, forKey: "caption")
        }
        
        drinkEntry.setValue("shot", forKey: "type")
        
        let currentUser = PFUser.current()
        if currentUser != nil
        {
            drinkEntry.setValue(currentUser!.objectId, forKey: "userObjectID")
            drinkEntry.setValue(objectID, forKey: "drinkObjectID")
        }
        
        if entryMode == 0 && bacEstimation == true
        {
            drinkEntry.setValue((drinksTextField.text! as NSString).doubleValue, forKey: "effectiveDrinkCount")
        }
        else if entryMode == 1
        {
            let ingredientsSet = drinkEntry.mutableOrderedSetValue(forKey: "ingredients")
            for ingredient in ingredients
            {
                let ingredientEntity =  NSEntityDescription.entity(forEntityName: "Ingredient", in: managedContext)
                let newIngredient = NSManagedObject(entity: ingredientEntity!, insertInto: managedContext)
                
                newIngredient.setValue(ingredient.name, forKey: "name")
                if ingredient.volume != nil
                {
                    newIngredient.setValue(ingredient.volume!, forKey: "volume")
                    newIngredient.setValue(ingredient.volumeUnits!, forKey: "volumeUnits")
                }
                if ingredient.abv != nil
                {
                    newIngredient.setValue(ingredient.abv!, forKey: "abv")
                }
                
                ingredientsSet.add(newIngredient)
            }
            
            if bacEstimation == true
            {
                let effectiveDrinks = calculateEffectiveDrinkCount()
                
                drinkEntry.setValue(effectiveDrinks, forKey: "effectiveDrinkCount")
            }
        }
        
        if bacEstimation == true
        {
            drinkEntry.setValue(true, forKey: "bacEstimation")
            
            drinkEntry.setValue(currentDateTime, forKey: "savedDateTime")
            // I guess there's no reason to have both? Should I save the current timezone?
            drinkEntry.setValue(selectedDateTime, forKey: "selectedDateTime")
            drinkEntry.setValue(selectedDateTime, forKey: "universalDateTime")
        }
        else
        {
            drinkEntry.setValue(false, forKey: "bacEstimation")
            
            drinkEntry.setValue(currentDateTime, forKey: "savedDateTime")
            // I guess there's no reason to have both? Should I save the current timezone?
            drinkEntry.setValue(currentDateTime, forKey: "selectedDateTime")
            drinkEntry.setValue(currentDateTime, forKey: "universalDateTime")
        }
        
        do
        {
            try managedContext.save()
        }
        catch let error
        {
            print("Could not save \(error)")
        }
    }
    
    func calculateEffectiveDrinkCount() -> Double
    {
        var effectiveDrinks: Double = 0
        
        for ingredient in ingredients
        {
            var ingredientEffectiveDrinks: Double
            if ingredient.volumeUnits == 0
            {
                ingredientEffectiveDrinks = ingredient.volume! * ingredient.abv! / 60
            }
            else
            {
                ingredientEffectiveDrinks = (ingredient.volume! / 29.5735295625) * ingredient.abv! / 60
            }
            
            effectiveDrinks += ingredientEffectiveDrinks
        }
        
        return effectiveDrinks
    }
    
    // no longer used
    func editParseDrink(objectID: String)
    {
        // Fetch drink
        let query = PFQuery(className: "ParseDrinkEntry")
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async
        {
            query.getObjectInBackground(withId: objectID)
            {
                (object: PFObject?, error: Error?) -> Void in
                        
                if error == nil && object != nil
                {
                    // if there's no error and no object, the object was already deleted?
                    // the object must have been saved if it has an ID
                            
                    if let parseDrinkEntry = object as? ParseDrinkEntry
                    {
                        // Delete old ingredients
                        if parseDrinkEntry.cocktailEntryMode == 1
                        {
                            let oldIngredients = parseDrinkEntry.ingredients
                            for ingredient in oldIngredients
                            {
                                ingredient.deleteEventually()
                            }
                        }
                        
                        // Update drink
                        parseDrinkEntry.displayName = self.nameTextField.text!
                        parseDrinkEntry.cocktailEntryMode = self.entryMode
                        
                        if self.locationName != nil && self.locationID != nil
                        {
                            parseDrinkEntry.locationName = self.locationName
                            parseDrinkEntry.locationID = self.locationID
                            
                            if self.locationAddress != nil
                            {
                                parseDrinkEntry.locationAddress = self.locationAddress
                            }
                            else
                            {
                                parseDrinkEntry.remove(forKey: "locationAddress")
                            }
                            
                            // to stop the errors until this function is commented out
                            if self.locationLatitude != nil && self.locationLongitude != nil
                            {
                                parseDrinkEntry.locationCoordinates = "\(self.locationLatitude), \(self.locationLongitude)"
                            }
                            else
                            {
                                parseDrinkEntry.remove(forKey: "locationCoordinates")
                            }
                        }
                        else
                        {
                            // What if these weren't set originally? Will it fail? Do I need to check for a value first?
                            parseDrinkEntry.remove(forKey: "locationName")
                            parseDrinkEntry.remove(forKey: "locationID")
                            parseDrinkEntry.remove(forKey: "locationAddress")
                            parseDrinkEntry.remove(forKey: "locationCoordinates")
                        }
                        
                        if self.caption != nil
                        {
                            parseDrinkEntry.caption = self.caption
                        }
                        else
                        {
                            // See above
                            parseDrinkEntry.remove(forKey: "caption")
                        }
                        
                        let defaults = UserDefaults.standard
                        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
                        
                        if self.entryMode == 0
                        {
                            // See above
                            parseDrinkEntry.remove(forKey: "ingredients")
                            
                            if bacEstimation == true
                            {
                                parseDrinkEntry.effectiveDrinkCount = (self.drinksTextField.text! as NSString).doubleValue
                            }
                        }
                        else
                        {
                            // Convert the ingredients.
                            var parseIngredients = [ParseIngredient]()
                            for ingredient in self.ingredients
                            {
                                let parseIngredient = ParseIngredient()
                                parseIngredient.parseIngredientName = ingredient.name
                                if ingredient.volume != nil
                                {
                                    parseIngredient.parseIngredientVolume = ingredient.volume!
                                    parseIngredient.parseIngredientUnits = ingredient.volumeUnits!
                                }
                                if ingredient.abv != nil
                                {
                                    parseIngredient.parseIngredientAlcoholContent = ingredient.abv!
                                }
                                
                                parseIngredients.append(parseIngredient)
                            }
                            
                            parseDrinkEntry.ingredients = parseIngredients
                            
                            if bacEstimation == true
                            {
                                parseDrinkEntry.effectiveDrinkCount = self.calculateEffectiveDrinkCount()
                            }
                        }
                        
                        if bacEstimation == true
                        {
                            // drinkEntry.bacEstimation = true
                            // Otherwise, this won't work on iOS 7.1
                            parseDrinkEntry["bacEstimation"] = true
                            
                            // Do I even use the selectedDateTime for anything? Should I save the current timezone?
                            parseDrinkEntry.selectedDateTime = self.selectedDateTime
                            parseDrinkEntry.universalDateTime = self.selectedDateTime
                        }
                        else
                        {
                            // See above
                            parseDrinkEntry.remove(forKey: "effectiveDrinkCount")
                            
                            // drinkEntry.bacEstimation = false
                            // Otherwise, this won't work on iOS 7.1
                            parseDrinkEntry["bacEstimation"] = false
                            
                            // Do I even use the selectedDateTime for anything? Should I save the current timezone?
                            // This is redundant if bacEstimation was off when the drink was first saved
                            parseDrinkEntry.selectedDateTime = parseDrinkEntry.savedDateTime
                            parseDrinkEntry.universalDateTime = parseDrinkEntry.savedDateTime
                        }
                        
                        // No hurry since I don't need to receive an objectID back?
                        parseDrinkEntry.saveEventually()
                    }
                }
                else
                {
                    // Alert.
                    
                    if error != nil
                    {
                        print("error in editParseDrink: \(error!)")
                    }
                    else
                    {
                        print("error in editParseDrink: object is nil")
                    }
                }
            }
        }
    }
    
    func editLocalDrink()
    {
        // Fetch drink
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        if let objectID = drinkBeingEdited?.objectID
        {
            do
            {
                let drinkEntry = try managedContext.existingObject(with: objectID)
                // Delete old ingredients
                if let oldEntryMode = drinkEntry.value(forKey: "entryMode") as? Int
                {
                    if oldEntryMode == 1
                    {
                        if let oldIngredients = drinkEntry.value(forKey: "ingredients") as? NSMutableOrderedSet
                        {
                            for ingredient in oldIngredients
                            {
                                // managedContext.deleteObject(ingredient as! NSManagedObject)
                                managedContext.delete(ingredient as! Ingredient)
                            }
                        }
                    }
                }
                
                // Update drink
                drinkEntry.setValue(nameTextField.text, forKey: "displayName")
                drinkEntry.setValue(entryMode, forKey: "entryMode")
                
                if locationName != nil && locationID != nil
                {
                    drinkEntry.setValue(locationName, forKey: "locationName")
                    drinkEntry.setValue(locationID, forKey: "locationID")
                    
                    // if locationAddress is nil, the property will be removed (as it should be)
                    drinkEntry.setValue(locationAddress, forKey: "locationAddress")
                    
                    if locationLatitude != nil && locationLongitude != nil
                    {
                        drinkEntry.setValue(locationLatitude, forKey: "locationLatitude")
                        drinkEntry.setValue(locationLongitude, forKey: "locationLongitude")
                    }
                    else
                    {
                        drinkEntry.setValue(nil, forKey: "locationLatitude")
                        drinkEntry.setValue(nil, forKey: "locationLongitude")
                    }
                }
                else
                {
                    // Does this work? Why even bother checking for nil above then?
                    // Check to see if there's already a value set? If there's not, no need to update.
                    drinkEntry.setValue(nil, forKey: "locationName")
                    drinkEntry.setValue(nil, forKey: "locationID")
                    drinkEntry.setValue(nil, forKey: "locationAddress")
                    drinkEntry.setValue(nil, forKey: "locationLatitude")
                    drinkEntry.setValue(nil, forKey: "locationLongitude")
                }
                
                if caption != nil
                {
                    drinkEntry.setValue(caption, forKey: "caption")
                }
                else
                {
                    // See above
                    drinkEntry.setValue(nil, forKey: "caption")
                }
                
                let defaults = UserDefaults.standard
                let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
                
                if entryMode == 0
                {
                    // See above
                    drinkEntry.setValue(nil, forKey: "ingredients")
                    
                    if bacEstimation == true
                    {
                        drinkEntry.setValue((drinksTextField.text! as NSString).doubleValue, forKey: "effectiveDrinkCount")
                    }
                }
                else
                {
                    let ingredientsSet = drinkEntry.mutableOrderedSetValue(forKey: "ingredients")
                    for ingredient in ingredients
                    {
                        let ingredientEntity =  NSEntityDescription.entity(forEntityName: "Ingredient", in: managedContext)
                        let newIngredient = NSManagedObject(entity: ingredientEntity!, insertInto: managedContext)
                        
                        newIngredient.setValue(ingredient.name, forKey: "name")
                        if ingredient.volume != nil
                        {
                            newIngredient.setValue(ingredient.volume!, forKey: "volume")
                            newIngredient.setValue(ingredient.volumeUnits!, forKey: "volumeUnits")
                        }
                        if ingredient.abv != nil
                        {
                            newIngredient.setValue(ingredient.abv!, forKey: "abv")
                        }
                        
                        ingredientsSet.add(newIngredient)
                    }
                    
                    if bacEstimation == true
                    {
                        drinkEntry.setValue(calculateEffectiveDrinkCount(), forKey: "effectiveDrinkCount")
                    }
                }
                
                if bacEstimation == true
                {
                    drinkEntry.setValue(true, forKey: "bacEstimation")
                    
                    // I guess there's no reason to have both? Should I save the current timezone?
                    drinkEntry.setValue(selectedDateTime, forKey: "selectedDateTime")
                    drinkEntry.setValue(selectedDateTime, forKey: "universalDateTime")
                }
                else
                {
                    // See above
                    drinkEntry.setValue(nil, forKey: "effectiveDrinkCount")
                    
                    drinkEntry.setValue(false, forKey: "bacEstimation")
                    
                    // I guess there's no reason to have both? Should I save the current timezone?
                    // This is redundant if bacEstimation was off when the drink was first saved
                    drinkEntry.setValue(drinkEntry.value(forKey: "savedDateTime"), forKey: "selectedDateTime")
                    drinkEntry.setValue(drinkEntry.value(forKey: "savedDateTime"), forKey: "universalDateTime")
                }
                
                do
                {
                    try managedContext.save()
                }
                catch let saveError
                {
                    print("Could not save \(saveError)")
                }
            }
            catch let fetchError
            {
                print("Could not fetch \(fetchError)")
            }
        }
    }


}
