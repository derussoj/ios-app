//
//  AddWineTableViewController.swift
//  Cheers
//
//  Created by Air on 6/16/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData
import Parse

class AddWineTableViewController: UITableViewController, UITextFieldDelegate
{
    @IBOutlet weak var vineyardTextField: UITextField!
    @IBOutlet weak var wineTextField: UITextField!
    @IBOutlet weak var abvTextField: UITextField!
    @IBOutlet weak var volumeTextField: UITextField!
    
    @IBOutlet weak var vintageDetailLabel: UILabel!
    @IBOutlet weak var unitsDetailLabel: UILabel!
    @IBOutlet weak var timeDetailLabel: UILabel!
    @IBOutlet weak var dateDetailLabel: UILabel!
    @IBOutlet weak var locationDetailLabel: UILabel!
    @IBOutlet weak var captionDetailLabel: UILabel!
    
    @IBOutlet weak var vineyardSearchButton: UIButton!
    @IBOutlet weak var wineSearchButton: UIButton!
    
    var vintage: String!
    var volumeUnits: Int!
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
        
        vineyardTextField.delegate = self
        wineTextField.delegate = self
        abvTextField.delegate = self
        volumeTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AddWineTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        vintage = "Non-Vintage"
        vintageDetailLabel.text = vintage
        
        volumeUnits = 0
        unitsDetailLabel.text = "oz"
        
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
    
    @IBAction func textFieldEditingDidBegin(_ sender: UITextField)
    {
        sender.text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !sender.text!.isEmpty
        {
            if sender == abvTextField
            {
                // sender.text = sender.text?.substring(to: sender.text!.endIndex.predecessor())
                
                if let text = sender.text
                {
                    sender.text = text.substring(to: text.index(before: text.endIndex))
                }
            }
            else if sender == volumeTextField
            {
                // sender.text = sender.text?.substring(to: sender.text!.endIndex.advancedBy(-3))
                
                if let text = sender.text
                {
                    sender.text = text.substring(to: text.index(text.endIndex, offsetBy: -3))
                }
            }
        }
    }
    
    @IBAction func textFieldEditingDidEnd(_ sender: UITextField)
    {
        sender.text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !sender.text!.isEmpty
        {
            if sender == abvTextField
            {
                sender.text! += "%"
            }
            else if sender == volumeTextField
            {
                if volumeUnits == 0
                {
                    sender.text! += " oz"
                }
                else if volumeUnits == 1
                {
                    sender.text! += " ml"
                }
            }
        }
    }
    
    func loadRecentDrink()
    {
        vineyardTextField.text = recentDrink?.vineyardName
        wineTextField.text = recentDrink?.wineName
        
        vintage = recentDrink?.vintage
        vintageDetailLabel.text = vintage
        
        let defaults = UserDefaults.standard
        let bacEstimation = defaults.bool(forKey: "bacEstimation")
        
        if bacEstimation == true && recentDrink?.bacEstimation == true
        {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
                
            abvTextField.text = numberFormatter.string(from: recentDrink!.abv!)
            // adds a % to the abvTextField text
            textFieldEditingDidEnd(abvTextField)
                
            volumeTextField.text = numberFormatter.string(from: recentDrink!.volume!)
                
            volumeUnits = recentDrink?.volumeUnits!.intValue
            if volumeUnits == 0
            {
                unitsDetailLabel.text = "oz"
            }
            else
            {
                unitsDetailLabel.text = "ml"
            }
                
            // adds the units to the volumeTextField text
            textFieldEditingDidEnd(volumeTextField)
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
    }
    
    func loadDrinkBeingEdited()
    {
        navBar.title = "Edit Wine"
        
        vineyardTextField.text = drinkBeingEdited?.vineyardName
        wineTextField.text = drinkBeingEdited?.wineName

        vintage = drinkBeingEdited?.vintage
        vintageDetailLabel.text = vintage
        
        // Display data consistent with the global bacEstimation setting rather than the drink's bacEstimation setting?
        // If BAC estimation was on but is now off, the plan is to erase that data during saving, right?
        let defaults = UserDefaults.standard
        let bacEstimation = defaults.bool(forKey: "bacEstimation")
        
        if bacEstimation == true
        {
            if drinkBeingEdited?.bacEstimation == true
            {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                    
                abvTextField.text = numberFormatter.string(from: drinkBeingEdited!.abv!)
                // adds a % to the abvTextField text
                textFieldEditingDidEnd(abvTextField)
                    
                volumeTextField.text = numberFormatter.string(from: drinkBeingEdited!.volume!)
                    
                volumeUnits = drinkBeingEdited?.volumeUnits?.intValue
                if volumeUnits == 0
                {
                    unitsDetailLabel.text = "oz"
                }
                else
                {
                    unitsDetailLabel.text = "ml"
                }
                    
                // adds the units to the volumeTextField text
                textFieldEditingDidEnd(volumeTextField)
            }
                
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
                DispatchQueue.global(qos: .userInitiated).async
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
                                    
                DispatchQueue.global(qos: .userInitiated).async
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
        
        if vineyardTextField.text!.isEmpty
        {
            // Alert
            
            return false
        }
        else if wineTextField.text!.isEmpty
        {
            // Alert
            
            return false
        }
        
        // I don't think the vintage can fail. Non-vintage by default. Validated on its own page?
        
        let defaults = UserDefaults.standard
        let bacEstimation = defaults.bool(forKey: "bacEstimation")
        
        if bacEstimation == true
        {
            if abvTextField.text!.isEmpty
            {
                // Alert
                    
                return false
            }
            else if volumeTextField.text!.isEmpty
            {
                // Alert
                    
                return false
            }
            
            if let text = abvTextField.text
            {
                let abv = Double(text.substring(to: text.index(before: text.endIndex)))
                
                if abv == nil
                {
                    // Alert
                    
                    return false
                }
                else if abv! < 0
                {
                    // Alert
                    
                    return false
                }
                else if abv == 0
                {
                    // Suggest the user turn BAC estimation off for just this drink.
                    // (Still need an option for that.)
                    
                    return false
                }
            }
            else
            {
                // Alert
                
                return false
            }
            
            if let text = volumeTextField.text
            {
                let volume = Double(text.substring(to: text.index(text.endIndex, offsetBy: -3)))
                
                if volume == nil
                {
                    // Alert
                    
                    return false
                }
                else if volume! < 0
                {
                    // Alert
                    
                    return false
                }
                else if volume == 0
                {
                    // Suggest the user turn BAC estimation off for just this drink.
                    // (Still need an option for that.)
                    
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
        vineyardTextField.text = vineyardTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        wineTextField.text = wineTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let defaults = UserDefaults.standard
        let bacEstimation = defaults.bool(forKey: "bacEstimation")
        
        if bacEstimation == true
        {
            abvTextField.text = abvTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            volumeTextField.text = volumeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    @IBAction func cancelToAddWine(_ segue:UIStoryboardSegue)
    {
        // Do nothing.
    }
    
    @IBAction func saveVintageToAddWine(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let vintageTableViewController = segue.source as? VintageTableViewController
        {
            vintage = vintageTableViewController.vintage
            
            vintageDetailLabel.text = vintage
        }
    }
    
    @IBAction func saveVolumeUnitsToAddWine(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let volumeUnitsTableViewController = segue.source as? VolumeUnitsTableViewController
        {
            volumeUnits = volumeUnitsTableViewController.selectedUnitsIndex
            
            if volumeUnits == 0
            {
                unitsDetailLabel.text = "oz"
            }
            else
            {
                unitsDetailLabel.text = "ml"
            }
            
            // updates the units shown in the volume text field
            textFieldEditingDidBegin(volumeTextField)
            textFieldEditingDidEnd(volumeTextField)
        }
    }
    
    @IBAction func saveTimeToAddWine(_ segue:UIStoryboardSegue)
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
    
    @IBAction func saveDateToAddWine(_ segue:UIStoryboardSegue)
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
    
    @IBAction func saveLocationToAddWine(_ segue:UIStoryboardSegue)
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
    
    @IBAction func saveCaptionToAddWine(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let captionTableViewController = segue.source as? CaptionTableViewController
        {
            caption = captionTableViewController.caption
            
            captionDetailLabel.text = caption
        }
    }
    
    @IBAction func saveVineyardToAddWine(_ segue:UIStoryboardSegue)
    {
        // Incorporate updates made on the AddBeer page
        /*
        if let vineyardWineSearchTableViewController = segue.sourceViewController as? VineyardWineSearchTableViewController
        {
            vineyardTextField.text = vineyardWineSearchTableViewController.selectedVineyard
            wineTextField.text = vineyardWineSearchTableViewController.selectedWine
            abvTextField.text = vineyardWineSearchTableViewController.selectedABV
        }
        */
    }
    
    @IBAction func saveWineToAddWine(_ segue:UIStoryboardSegue)
    {
        // Incorporate updates made on the AddBeer page
        /*
        if let wineSearchTableViewController = segue.sourceViewController as? WineSearchTableViewController
        {
            vineyardTextField.text = wineSearchTableViewController.selectedVineyard
            wineTextField.text = wineSearchTableViewController.selectedWine
            abvTextField.text = wineSearchTableViewController.selectedABV
        }
        */
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // Return the number of rows in the section.
        
        let defaults = UserDefaults.standard
        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
        // let bacEstimation: Bool = false
        
        if section == 0
        {
            if bacEstimation == true
            {
                return 6
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
        
        let timeIndexPath = IndexPath(row: 0, section: 1)
        let dateIndexPath = IndexPath(row: 1, section: 1)
        
        if bacEstimation != true
        {
            if indexPath == timeIndexPath || indexPath == dateIndexPath
            {
                return 0
            }
        }
        
        return UITableViewAutomaticDimension
    }

    // Override to support conditional editing of the table view.
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        if indexPath.section == 0
        {
            if indexPath.row == 0 || indexPath.row == 1 || indexPath.row == 3 || indexPath.row == 4
            {
                return true
            }
        }
        else if indexPath.section == 1
        {
            if indexPath.row == 2 || indexPath.row == 3
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
                
            if indexPath.section == 0
            {
                if indexPath.row == 0
                {
                    self.vineyardTextField.text = String()
                }
                else if indexPath.row == 1
                {
                    self.wineTextField.text = String()
                }
                else if indexPath.row == 3
                {
                    self.abvTextField.text = String()
                }
                else if indexPath.row == 4
                {
                    self.volumeTextField.text = String()
                }
            }
            else if indexPath.section == 1
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
        if indexPath.section == 0
        {
            if indexPath.row == 0
            {
                vineyardTextField.becomeFirstResponder()
            }
            else if indexPath.row == 1
            {
                wineTextField.becomeFirstResponder()
            }
            else if indexPath.row == 3
            {
                abvTextField.becomeFirstResponder()
            }
            else if indexPath.row == 4
            {
                volumeTextField.becomeFirstResponder()
            }
        }
    }
    
    @IBAction func searchTouchDown(_ sender: UIButton)
    {
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations:
        {
            sender.alpha = 0.2
        }, completion: nil)
    }
    
    @IBAction func searchTouchUp(_ sender: UIButton)
    {
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations:
        {
            sender.alpha = 1
        }, completion: nil)
    }

    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if identifier == "VineyardSelection"
        {
            vineyardTextField.text = vineyardTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if vineyardTextField.text?.isEmpty == true
            {
                // Alert
                
                return false
            }
        }
        else if identifier == "WineSelection"
        {
            wineTextField.text = wineTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if wineTextField.text?.isEmpty == true
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
        if segue.identifier == "VintageSelection"
        {
            if let vintageTableViewController = segue.destination as? VintageTableViewController
            {
                vintageTableViewController.vintage = vintage
            }
        }
        
        else if segue.identifier == "UnitsSelection"
        {
            if let unitsTableViewController = segue.destination as? VolumeUnitsTableViewController
            {
                unitsTableViewController.sendingView = "AddWine"
                
                if unitsDetailLabel.text == "oz"
                {
                    unitsTableViewController.selectedUnitsIndex = 0
                }
                else
                {
                    unitsTableViewController.selectedUnitsIndex = 1
                }
            }
        }
            
        else if segue.identifier == "TimeSelection"
        {
            if let timeViewController = segue.destination as? TimeViewController
            {
                timeViewController.sendingView = "AddWine"
                
                timeViewController.selectedTime = selectedDateTime
            }
        }
            
        else if segue.identifier == "DateSelection"
        {
            if let dateViewController = segue.destination as? DateViewController
            {
                dateViewController.sendingView = "AddWine"
                
                dateViewController.selectedDate = selectedDateTime
            }
        }
            
        else if segue.identifier == "LocationSelection"
        {
            if let locationTableViewController = segue.destination as? LocationTableViewController
            {
                locationTableViewController.sendingView = "AddWine"
            }
        }
            
        else if segue.identifier == "CaptionEntry"
        {
            if let captionTableViewController = segue.destination as? CaptionTableViewController
            {
                captionTableViewController.sendingView = "AddWine"
                
                captionTableViewController.caption = caption
            }
        }
            
        else if segue.identifier == "VineyardSelection"
        {
            /*
            if let vineyardSearchTableViewController = segue.destinationViewController.topViewController as? VineyardSearchTableViewController
            {
                var vineyardText = vineyardTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                
                // Validate this above?
                vineyardText = vineyardText.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
                
                vineyardSearchTableViewController.searchText = vineyardText
            }
            */
        }
            
        else if segue.identifier == "WineSelection"
        {
            /*
            if let wineSearchTableViewController = segue.destinationViewController.topViewController as? WineSearchTableViewController
            {
                var wineText = wineTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                
                // Validate this above?
                wineText = wineText.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
                
                wineSearchTableViewController.searchText = wineText
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
        
        drinkEntry.displayName = wineTextField.text!
        drinkEntry.vineyardName = vineyardTextField.text!
        drinkEntry.wineName = wineTextField.text!
        drinkEntry.vintage = vintage
        
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
        
        drinkEntry.type = "wine"
        drinkEntry.os = "iOS"
        
        if bacEstimation == true
        {
            // the ABV and volume textFields were already validated in validateUserEntries()
            
            let abvText = abvTextField.text!
            let abv = Double(abvText.substring(to: abvText.index(before: abvText.endIndex)))!
            
            let volumeText = volumeTextField.text!
            let volume = Double(volumeText.substring(to: volumeText.index(volumeText.endIndex, offsetBy: -3)))!
            
            var effectiveDrinkCount: Double
            if volumeUnits == 0
            {
                effectiveDrinkCount = abv * volume / 60
            }
            else
            {
                effectiveDrinkCount = abv * (volume / 29.5735295625) / 60
            }
            
            drinkEntry.abv = abv
            drinkEntry.volume = volume
            drinkEntry.volumeUnits = volumeUnits
            drinkEntry.effectiveDrinkCount = effectiveDrinkCount
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
        let entity =  NSEntityDescription.entity(forEntityName: "DrinkEntry", in: managedContext)
        let drinkEntry = NSManagedObject(entity: entity!, insertInto:managedContext)
        
        drinkEntry.setValue(wineTextField.text, forKey: "displayName")
        drinkEntry.setValue(vineyardTextField.text, forKey: "vineyardName")
        drinkEntry.setValue(wineTextField.text, forKey: "wineName")
        drinkEntry.setValue(vintage, forKey: "vintage")
        
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
        
        drinkEntry.setValue("wine", forKey: "type")
        
        let currentUser = PFUser.current()
        if currentUser != nil
        {
            drinkEntry.setValue(currentUser!.objectId, forKey: "userObjectID")
            drinkEntry.setValue(objectID, forKey: "drinkObjectID")
        }
        
        if bacEstimation == true
        {
            // the ABV and volume textFields were already validated in validateUserEntries()
            
            let abvText = abvTextField.text!
            let abv = Double(abvText.substring(to: abvText.index(before: abvText.endIndex)))!
            
            let volumeText = volumeTextField.text!
            let volume = Double(volumeText.substring(to: volumeText.index(volumeText.endIndex, offsetBy: -3)))!
            
            var effectiveDrinkCount: Double
            if volumeUnits == 0
            {
                effectiveDrinkCount = abv * volume / 60
            }
            else
            {
                effectiveDrinkCount = abv * (volume / 29.5735295625) / 60
            }
            
            drinkEntry.setValue(abv, forKey: "abv")
            drinkEntry.setValue(volume, forKey: "volume")
            drinkEntry.setValue(volumeUnits, forKey: "volumeUnits")
            drinkEntry.setValue(effectiveDrinkCount, forKey: "effectiveDrinkCount")
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
    
    // no longer used
    func editParseDrink(objectID: String)
    {
        // Fetch drink
        let query = PFQuery(className: "ParseDrinkEntry")
            
        DispatchQueue.global(qos: .userInitiated).async
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
                        // Update drink
                        parseDrinkEntry.displayName = self.wineTextField.text!
                        parseDrinkEntry.vineyardName = self.vineyardTextField.text!
                        parseDrinkEntry.wineName = self.wineTextField.text!
                        parseDrinkEntry.vintage = self.vintage
                        
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
                        
                        if bacEstimation == true
                        {
                            // the ABV and volume textFields were already validated in validateUserEntries()
                            
                            let abvText = self.abvTextField.text!
                            let abv = Double(abvText.substring(to: abvText.index(before: abvText.endIndex)))!
                            
                            let volumeText = self.volumeTextField.text!
                            let volume = Double(volumeText.substring(to: volumeText.index(volumeText.endIndex, offsetBy: -3)))!
                            
                            var effectiveDrinkCount: Double
                            if self.volumeUnits == 0
                            {
                                effectiveDrinkCount = abv * volume / 60
                            }
                            else
                            {
                                effectiveDrinkCount = abv * (volume / 29.5735295625) / 60
                            }
                            
                            parseDrinkEntry.abv = abv
                            parseDrinkEntry.volume = volume
                            parseDrinkEntry.volumeUnits = self.volumeUnits
                            parseDrinkEntry.effectiveDrinkCount = effectiveDrinkCount
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
                            parseDrinkEntry.remove(forKey: "abv")
                            parseDrinkEntry.remove(forKey: "volume")
                            parseDrinkEntry.remove(forKey: "volumeUnits")
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
                // Update drink
                drinkEntry.setValue(wineTextField.text, forKey: "displayName")
                drinkEntry.setValue(vineyardTextField.text, forKey: "vineyardName")
                drinkEntry.setValue(wineTextField.text, forKey: "wineName")
                drinkEntry.setValue(vintage, forKey: "vintage")
                
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
                
                if bacEstimation == true
                {
                    // the ABV and volume textFields were already validated in validateUserEntries()
                    
                    let abvText = abvTextField.text!
                    let abv = Double(abvText.substring(to: abvText.index(before: abvText.endIndex)))!
                    
                    let volumeText = volumeTextField.text!
                    let volume = Double(volumeText.substring(to: volumeText.index(volumeText.endIndex, offsetBy: -3)))!
                    
                    var effectiveDrinkCount: Double
                    if volumeUnits == 0
                    {
                        effectiveDrinkCount = abv * volume / 60
                    }
                    else
                    {
                        effectiveDrinkCount = abv * (volume / 29.5735295625) / 60
                    }
                    
                    drinkEntry.setValue(abv, forKey: "abv")
                    drinkEntry.setValue(volume, forKey: "volume")
                    drinkEntry.setValue(volumeUnits, forKey: "volumeUnits")
                    drinkEntry.setValue(effectiveDrinkCount, forKey: "effectiveDrinkCount")
                    drinkEntry.setValue(true, forKey: "bacEstimation")
                    
                    // I guess there's no reason to have both? Should I save the current timezone?
                    drinkEntry.setValue(selectedDateTime, forKey: "selectedDateTime")
                    drinkEntry.setValue(selectedDateTime, forKey: "universalDateTime")
                }
                else
                {
                    // See above
                    drinkEntry.setValue(nil, forKey: "abv")
                    drinkEntry.setValue(nil, forKey: "volume")
                    drinkEntry.setValue(nil, forKey: "volumeUnits")
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
                catch let error
                {
                    print("Could not save \(error)")
                }
            }
            catch let error
            {
                print("Could not fetch \(error)")
            }
        }
    }


}
