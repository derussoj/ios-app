//
//  AddBeerTableViewController.swift
//  Cheers
//
//  Created by Air on 2/10/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData
import Parse
import Firebase

class AddBeerTableViewController: UITableViewController, UITextFieldDelegate
{
    @IBOutlet weak var breweryTextField: UITextField!
    @IBOutlet weak var beerTextField: UITextField!
    @IBOutlet weak var abvTextField: UITextField!
    @IBOutlet weak var volumeTextField: UITextField!
    
    @IBOutlet weak var brewerySearchButton: UIButton!
    @IBOutlet weak var beerSearchButton: UIButton!
    
    @IBOutlet weak var unitsDetailLabel: UILabel!
    @IBOutlet weak var timeDetailLabel: UILabel!
    @IBOutlet weak var dateDetailLabel: UILabel!
    @IBOutlet weak var locationDetailLabel: UILabel!
    @IBOutlet weak var captionDetailLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
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
    
    // let firebaseRootRef = Firebase(url: "https://glowing-inferno-7505.firebaseio.com")
    let firebaseRootRef = FIRDatabase.database().reference()
    // var friends: [NSDictionary]?
    // var followers: [NSDictionary]?
    // var friends: [String]?
    // var followers: [String]?
    var friends = [String]()
    var followers = [String]()
    var userDataFetched: Bool = false
    // var userFriendDataFetched = false
    // var userFollowerDataFetched = false
    
    // for the activity indicator
    let activityIndicator = UIActivityIndicatorView()
    let overlay = UIView()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        breweryTextField.delegate = self
        beerTextField.delegate = self
        abvTextField.delegate = self
        volumeTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AddBeerTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
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
        
        if let userID = FIRAuth.auth()?.currentUser?.uid
        {
            fetchUserData(userID)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        if let userID = FIRAuth.auth()?.currentUser?.uid
        {
            firebaseRootRef.child("users/\(userID)").removeAllObservers()
        }
        else
        {
            // Do nothing?
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
        sender.text = sender.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if !sender.text!.isEmpty
        {
            if sender == abvTextField
            {
                sender.text = sender.text?.substring(to: sender.text!.characters.index(before: sender.text!.endIndex))
            }
            else if sender == volumeTextField
            {
                sender.text = sender.text?.substring(to: sender.text!.characters.index(sender.text!.endIndex, offsetBy: -3))
            }
        }
    }
    
    @IBAction func textFieldEditingDidEnd(_ sender: UITextField)
    {
        sender.text = sender.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
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
        breweryTextField.text = recentDrink?.breweryName
        beerTextField.text = recentDrink?.beerName
        
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
        navBar.title = "Edit Beer"
        
        breweryTextField.text = drinkBeingEdited?.breweryName
        beerTextField.text = drinkBeingEdited?.beerName
        
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
    
    func fetchUserData(_ uid: String)
    {
        /*
        firebaseRootRef.childByAppendingPath("users/\(uid)").observeSingleEventOfType(.Value, withBlock:
        {
            snapshot in
                
            timer.invalidate()
                
            if snapshot.value is NSNull
            {
                // Do nothing?
            }
            else
            {
                if let snapshotValue = snapshot.value as? NSDictionary
                {
                    // [NSDictionary] or just NSDictionary?
                    
                    if let userFriends = snapshotValue["friends"] as? [NSDictionary]
                    {
                        self.friends = userFriends
                    }
                    
                    if let userFollowers = snapshotValue["followers"] as? [NSDictionary]
                    {
                        self.followers = userFollowers
                    }
                    
                    self.userDataFetched = true
                }
                else
                {
                    // Do nothing?
                }
            }
        })
        
        firebaseRootRef.childByAppendingPath("users/\(uid)/friends").queryOrderedByKey().observeEventType(.ChildAdded, withBlock:
        {
            snapshot in
            
            timer.invalidate()
            
            if snapshot.value is NSNull
            {
                // Do nothing?
                
                print("friends snapshot is null")
            }
            else
            {
                print(snapshot.key)
                
                self.friends?.append(snapshot.key)
                
                self.userDataFetched = true
            }
        })
        
        firebaseRootRef.childByAppendingPath("users/\(uid)/friends").observeSingleEventOfType(.Value, withBlock:
        {
            snapshot in
            
            timer.invalidate()
            
            if snapshot.value is NSNull
            {
                // Do nothing?
            }
            else
            {
                /*
                if let snapshots = snapshot.children.allObjects as? [FDataSnapshot]
                {
                    for friend in snapshots
                    {
                        print(friend.key)
                    }
                }
                
                for friend in snapshot.children.allObjects as! [FDataSnapshot]
                {
                    print(friend.key)
                }
                */
                
                let enumerator = snapshot.children
                
                while let friend = enumerator.nextObject() as? FDataSnapshot
                {
                    print(friend.key)
                    
                    self.friends.append(friend.key)
                }
            }
            
            self.userFriendDataFetched = true
        })
        */
        
        firebaseRootRef.child("users/\(uid)").observeSingleEvent(of: .value, with:
        {
            snapshot in
                
            if snapshot.value is NSNull
            {
                // Do nothing?
                // It really shouldn't be null on this page.
                // Log the user out?
            }
            else
            {
                let friendsSnapshot = snapshot.childSnapshot(forPath: "friends")
                let friendsEnumerator = friendsSnapshot.children
                
                while let friend = friendsEnumerator.nextObject() as? FIRDataSnapshot
                {
                    print(friend.key)
                    
                    self.friends.append(friend.key)
                }
                
                let followersSnapshot = snapshot.childSnapshot(forPath: "followers")
                let followersEnumerator = followersSnapshot.children
                
                while let follower = followersEnumerator.nextObject() as? FIRDataSnapshot
                {
                    print(follower.key)
                    
                    self.followers.append(follower.key)
                }
                
                self.userDataFetched = true
            }
        })
    }
    
    func fetchUserDataDuringSave(_ uid: String)
    {
        // 10 seconds? Maybe longer?
        let timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(AddBeerTableViewController.removeFirebaseObserver), userInfo: nil, repeats: false)
        
        firebaseRootRef.child("users/\(uid)").observeSingleEvent(of: .value, with:
        {
            snapshot in
                
            timer.invalidate()
                
            if snapshot.value is NSNull
            {
                // Do nothing?
                // It really shouldn't be null on this page.
                // Log the user out?
                
                if self.activityIndicator.isAnimating
                {
                    self.showActivityIndicator(false)
                }
                
                // Alert.
            }
            else
            {
                let friendsSnapshot = snapshot.childSnapshot(forPath: "friends")
                let friendsEnumerator = friendsSnapshot.children
                    
                while let friend = friendsEnumerator.nextObject() as? FIRDataSnapshot
                {
                    print(friend.key)
                        
                    self.friends.append(friend.key)
                }
                    
                let followersSnapshot = snapshot.childSnapshot(forPath: "followers")
                let followersEnumerator = followersSnapshot.children
                    
                while let follower = followersEnumerator.nextObject() as? FIRDataSnapshot
                {
                    print(follower.key)
                        
                    self.followers.append(follower.key)
                }
                    
                self.userDataFetched = true
                
                self.saveAction(self.saveButton)
            }
        })
    }
    
    func removeFirebaseObserver()
    {
        if let userID = FIRAuth.auth()?.currentUser?.uid
        {
            firebaseRootRef.child("users/\(userID)").removeAllObservers()
        }
        else
        {
            // Do nothing?
        }
        
        if activityIndicator.isAnimating
        {
            showActivityIndicator(false)
        }
        
        // Alert.
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
            if editingDrink == true
            {
                if let objectID = drinkBeingEdited?.drinkObjectID
                {
                    if !objectID.isEmpty
                    {
                        if FIRAuth.auth()?.currentUser != nil
                        {
                            if activityIndicator.isAnimating == false
                            {
                                showActivityIndicator(true)
                            }
                            
                            editFirebaseDrink(objectID)
                            
                            editLocalDrink()
                            
                            let time = DispatchTime.now() + Double(Int64(0.6 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                            DispatchQueue.main.asyncAfter(deadline: time)
                            {
                                self.showActivityIndicator(false)
                                
                                self.performSegue(withIdentifier: "SaveDrink", sender: self)
                            }
                        }
                        else
                        {
                            // The drinkEntry has an objectID but the user is no longer logged in
                            // Alert the user that the drinkEntry won't be edited unless they log back in
                            
                            // Alert.
                        }
                    }
                }
                else
                {
                    editLocalDrink()
                    
                    performSegue(withIdentifier: "SaveDrink", sender: self)
                }
            }
            else
            {
                // For consistency.
                let dateTimeNow = Date()
                
                var objectID: String = String()
                
                if let user = FIRAuth.auth()?.currentUser
                {
                    if activityIndicator.isAnimating == false
                    {
                        showActivityIndicator(true)
                    }
                    
                    if userDataFetched == true
                    {
                        objectID = saveDrinkToFirebase(dateTimeNow, uid: user.uid)
                        
                        saveDrinkLocally(dateTimeNow, objectID: objectID)
                        
                        let time = DispatchTime.now() + Double(Int64(0.6 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: time)
                        {
                            self.showActivityIndicator(false)
                            
                            self.performSegue(withIdentifier: "SaveDrink", sender: self)
                        }
                    }
                    else
                    {
                        // the user's data should be cached locally so I wouldn't expect this code to be reached often
                        
                        print("user data not fetched prior to saving")
                        
                        firebaseRootRef.child("users/\(user.uid)").removeAllObservers()
                        
                        // fetches the user's data
                        // if successful, saveAction is called
                        // otherwise, an alert is presented
                        fetchUserDataDuringSave(user.uid)
                    }
                }
                else
                {
                    saveDrinkLocally(dateTimeNow, objectID: objectID)
                    
                    performSegue(withIdentifier: "SaveDrink", sender: self)
                }
            }
        }
    }
    
    func validateUserEntries() -> Bool
    {
        trimTextFields()
        
        if breweryTextField.text!.isEmpty
        {
            // Alert
            
            return false
        }
        else if beerTextField.text!.isEmpty
        {
            // Alert
            
            return false
        }
        
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
        breweryTextField.text = breweryTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        beerTextField.text = beerTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        let defaults = UserDefaults.standard
        let bacEstimation = defaults.bool(forKey: "bacEstimation")
        
        if bacEstimation == true
        {
            abvTextField.text = abvTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            volumeTextField.text = volumeTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    
    func showActivityIndicator(_ shouldShow: Bool)
    {
        if shouldShow == true
        {
            overlay.frame = view.frame
            overlay.center = view.center
            overlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
            
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
            activityIndicator.color = UIColor(red: 56/255.0, green: 207/255.0, blue: 166/255.0, alpha: 1)
            
            /*
            let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurredContainer: UIVisualEffectView = UIVisualEffectView(effect: blurEffect)
            blurredContainer.frame = CGRectMake(0, 0, 80, 80)
            blurredContainer.center = CGPointMake(overlay.frame.size.width / 2, overlay.frame.size.height / 2)
            blurredContainer.layer.cornerRadius = 10
            blurredContainer.clipsToBounds = true
            */
            
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
            
            overlay.alpha = 0
            
            navigationController?.view.addSubview(overlay)
            
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations:
            {
                self.overlay.alpha = 1
            },
            completion: nil)
        }
        else
        {
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations:
            {
                self.overlay.alpha = 0
            },
            completion:
            {
                finished in
                
                if finished
                {
                    self.overlay.removeFromSuperview()
                    
                    self.activityIndicator.stopAnimating()
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelToAddBeer(_ segue:UIStoryboardSegue)
    {
        // Do nothing.
    }
    
    @IBAction func saveVolumeUnitsToAddBeer(_ segue:UIStoryboardSegue)
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
    
    @IBAction func saveTimeToAddBeer(_ segue:UIStoryboardSegue)
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
    
    @IBAction func saveDateToAddBeer(_ segue:UIStoryboardSegue)
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
    
    @IBAction func saveLocationToAddBeer(_ segue:UIStoryboardSegue)
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
    
    @IBAction func saveCaptionToAddBeer(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let captionTableViewController = segue.source as? CaptionTableViewController
        {
            caption = captionTableViewController.caption
            
            captionDetailLabel.text = caption
        }
    }
    
    @IBAction func saveBreweryBeerSelection(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let breweryBeerSearchTableViewController = segue.source as? BreweryBeerSearchTableViewController
        {
            breweryTextField.text = breweryBeerSearchTableViewController.selectedBrewery
            beerTextField.text = breweryBeerSearchTableViewController.selectedBeer
            
            if breweryBeerSearchTableViewController.selectedABV != nil
            {
                abvTextField.text = breweryBeerSearchTableViewController.selectedABV!
                
                // adds a % to the abvTextField text
                textFieldEditingDidEnd(abvTextField)
            }
        }
    }
    
    @IBAction func saveBeerSelection(_ segue:UIStoryboardSegue)
    {
        hasUnsavedChanges = true
        
        if let beerSearchTableViewController = segue.source as? BeerSearchTableViewController
        {
            breweryTextField.text = beerSearchTableViewController.selectedBrewery
            beerTextField.text = beerSearchTableViewController.selectedBeer
            
            if beerSearchTableViewController.selectedABV != nil
            {
                abvTextField.text = beerSearchTableViewController.selectedABV
                
                // adds a % to the abvTextField text
                textFieldEditingDidEnd(abvTextField)
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        
        let defaults = UserDefaults.standard
        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
        // let bacEstimation: Bool = false
        
        if section == 0
        {
            if bacEstimation == true
            {
                return 5
            }
            else
            {
                return 2
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
            if indexPath.row == 0 || indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3
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
        {(action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            
            if indexPath.section == 0
            {
                if indexPath.row == 0
                {
                    self.breweryTextField.text = String()
                }
                else if indexPath.row == 1
                {
                    self.beerTextField.text = String()
                }
                else if indexPath.row == 2
                {
                    self.abvTextField.text = String()
                }
                else if indexPath.row == 3
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
                breweryTextField.becomeFirstResponder()
            }
            else if indexPath.row == 1
            {
                beerTextField.becomeFirstResponder()
            }
            else if indexPath.row == 2
            {
                abvTextField.becomeFirstResponder()
            }
            else if indexPath.row == 3
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
    
    @IBAction func searchTouchUpInside(_ sender: UIButton)
    {
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations:
        {
            sender.alpha = 1
        }, completion: nil)
    }
    
    @IBAction func searchTouchUpOutside(_ sender: UIButton)
    {
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations:
        {
            sender.alpha = 1
        }, completion: nil)
    }
    
    @IBAction func searchTouchCancel(_ sender: UIButton)
    {
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations:
        {
            sender.alpha = 1
        }, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if identifier == "BrewerySelection"
        {
            breweryTextField.text = breweryTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if breweryTextField.text!.isEmpty == true
            {
                // Alert
                
                return false
            }
        }
        else if identifier == "BeerSelection"
        {
            beerTextField.text = beerTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if beerTextField.text!.isEmpty == true
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
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "UnitsSelection"
        {
            if let unitsTableViewController = segue.destination as? VolumeUnitsTableViewController
            {
                unitsTableViewController.sendingView = "AddBeer"
                
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
                timeViewController.sendingView = "AddBeer"
                
                timeViewController.selectedTime = selectedDateTime
            }
        }
        
        else if segue.identifier == "DateSelection"
        {
            if let dateViewController = segue.destination as? DateViewController
            {
                dateViewController.sendingView = "AddBeer"
                
                dateViewController.selectedDate = selectedDateTime
            }
        }
            
        else if segue.identifier == "LocationSelection"
        {
            if let locationTableViewController = segue.destination as? LocationTableViewController
            {
                locationTableViewController.sendingView = "AddBeer"
            }
        }
        
        else if segue.identifier == "CaptionEntry"
        {
            if let captionTableViewController = segue.destination as? CaptionTableViewController
            {
                captionTableViewController.sendingView = "AddBeer"
                
                captionTableViewController.caption = caption
            }
        }
         
        else if segue.identifier == "BrewerySelection"
        {
            // if let brewerySearchTableViewController = segue.destinationViewController.topViewController as? BrewerySearchTableViewController
            if let brewerySearchTableViewController = segue.destination.childViewControllers[0] as? BrewerySearchTableViewController
            {
                var breweryText = breweryTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                // Validate this above?
                breweryText = breweryText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                
                brewerySearchTableViewController.searchText = breweryText
            }
        }
        
        else if segue.identifier == "BeerSelection"
        {
            // if let beerSearchTableViewController = segue.destinationViewController.topViewController as? BeerSearchTableViewController
            if let beerSearchTableViewController = segue.destination.childViewControllers[0] as? BeerSearchTableViewController
            {
                var beerText = beerTextField.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                // Validate this above?
                beerText = beerText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                
                beerSearchTableViewController.searchText = beerText
            }
        }
    }
    
    // no longer used
    /*
    func saveDrinkToParse(_ currentDateTime: Date) -> String
    {
        let defaults = UserDefaults.standard
        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
        
        let drinkEntry = ParseDrinkEntry()
        
        drinkEntry.parseUser = PFUser.current()!
        
        drinkEntry.displayName = beerTextField.text!
        drinkEntry.breweryName = breweryTextField.text!
        drinkEntry.beerName = beerTextField.text!
        
        if locationName != nil && locationID != nil
        {
            drinkEntry.locationName = locationName
            drinkEntry.locationID = locationID
            
            if locationAddress != nil
            {
                drinkEntry.locationAddress = locationAddress
            }
            
            if locationCoordinates != nil
            {
                drinkEntry.locationCoordinates = locationCoordinates
            }
        }
        
        if caption != nil
        {
            drinkEntry.caption = caption
        }
        drinkEntry.commentNumber = 0
        drinkEntry.likeCount = 0

        drinkEntry.type = "beer"
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
        
        /*
        drinkEntry.saveInBackgroundWithBlock
        {
            (success: Bool, error: NSError?) -> Void in
            
            if (success)
            {
                // The object has been saved.

                // Bool?
            }
            else
            {
                // There was a problem, check error.description
                println(error?.description)
                
                // Alert?
                
                // Bool?
                
                // Save eventually?
            }
        }
        */
        
        /*
        let success: Bool = drinkEntry.save()
        if success == false
        {
            drinkEntry.saveEventually()
        }
        */
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
    */
    
    func saveDrinkToFirebase(_ currentDateTime: Date, uid: String) -> String
    {
        let defaults = UserDefaults.standard
        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
        
        var drinkEntry = [String: Any]()
        
        // in place of drinkEntry.parseUser
        // do I need to store more user data? check the code for the feed
        // if I did, it wouldn't stay up to date
        // that's going to be a lot of fetching
        // persist data locally for my friends and the people I follow?
        drinkEntry["userID"] = uid
        
        drinkEntry["displayName"] = beerTextField.text!
        drinkEntry["breweryName"] = breweryTextField.text!
        drinkEntry["beerName"] = beerTextField.text!
        
        if locationName != nil && locationID != nil
        {
            drinkEntry["locationName"] = locationName
            drinkEntry["locationID"] = locationID
            
            if locationAddress != nil
            {
                drinkEntry["locationAddress"] = locationAddress
            }
            
            if locationLatitude != nil && locationLongitude != nil
            {
                drinkEntry["locationLatitude"] = locationLatitude
                drinkEntry["locationLongitude"] = locationLongitude
            }
        }
        
        if caption != nil
        {
            drinkEntry["caption"] = caption
        }
        drinkEntry["commentNumber"] = 0
        drinkEntry["likeCount"] = 0
        
        drinkEntry["type"] = "beer"
        drinkEntry["os"] = "iOS"
        
        // need to double check this
        // also, what am I using it for?
        // currently, it's not updated when editing a drink so I guess it's pretty much equivalent to savedDateTime
        // drinkEntry["firebaseTimestamp"] = ".sv"
        // drinkEntry["firebaseTimestamp"] = FirebaseServerValue.timestamp()
        drinkEntry["firebaseTimestamp"] = FIRServerValue.timestamp()
        
        let dateFormatter = DateFormatter()
        // spacing? no spacing? mostly concerned about sorting when fetching
        dateFormatter.dateFormat = "yyyy MM dd HH mm ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
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
            
            drinkEntry["abv"] = abv
            drinkEntry["volume"] = volume
            drinkEntry["volumeUnits"] = volumeUnits
            drinkEntry["effectiveDrinkCount"] = effectiveDrinkCount
            
            drinkEntry["bacEstimation"] = true
            
            drinkEntry["savedDateTime"] = dateFormatter.string(from: currentDateTime)
            // going with one selected, universal date/time
            drinkEntry["selectedDateTime"] = dateFormatter.string(from: selectedDateTime)
        }
        else
        {
            drinkEntry["bacEstimation"] = false
            
            drinkEntry["savedDateTime"] = dateFormatter.string(from: currentDateTime)
            // going with one selected, universal date/time
            drinkEntry["selectedDateTime"] = dateFormatter.string(from: currentDateTime)
        }
        
        // dateFormatter.dateFormat = "yyyyMMddHHmmss"
        // let drinkID = authData.uid + "." + dateFormatter.stringFromDate(currentDateTime)
        // firebaseRootRef.childByAppendingPath("drinks/\(drinkID)").setValue(drinkEntry)
        
        // firebaseRootRef.childByAppendingPath("drinks").childByAutoId().setValue(drinkEntry)
        
        let drinkRef = firebaseRootRef.child("drinks").childByAutoId()
        
        drinkRef.setValue(drinkEntry)
        
        let drinkID = drinkRef.key
        
        print("drinkID is \(drinkID)")
        
        let data = [drinkID : "true"]
        
        firebaseRootRef.child("users/\(uid)/drinks").updateChildValues(data)
        
        
        
        
        
        
        // For testing only!
        firebaseRootRef.child("users/\(uid)/feeds/friends").updateChildValues(data)
        firebaseRootRef.child("users/\(uid)/feeds/followees").updateChildValues(data)
        
        
        
        
        
        for friendID in friends
        {
            firebaseRootRef.child("users/\(friendID)/feeds/friends").updateChildValues(data)
        }
        
        for followerID in followers
        {
            firebaseRootRef.child("users/\(followerID)/feeds/followees").updateChildValues(data)
        }
        
        return drinkID
    }
    
    func saveDrinkLocally(_ currentDateTime: Date, objectID: String)
    {
        let defaults = UserDefaults.standard
        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entity(forEntityName: "DrinkEntry", in: managedContext)
        let drinkEntry = NSManagedObject(entity: entity!, insertInto:managedContext)
        
        if let userID = FIRAuth.auth()?.currentUser?.uid
        {
            drinkEntry.setValue(userID, forKey: "userObjectID")
            drinkEntry.setValue(objectID, forKey: "drinkObjectID")
        }
        
        drinkEntry.setValue(beerTextField.text, forKey: "displayName")
        drinkEntry.setValue(breweryTextField.text, forKey: "breweryName")
        drinkEntry.setValue(beerTextField.text, forKey: "beerName")
        
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
        
        drinkEntry.setValue("beer", forKey: "type")
        
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
    /*
    func editParseDrink(_ objectID: String)
    {
        // Fetch drink
        let query = PFQuery(className: "ParseDrinkEntry")
        
        // var drinkEntry = ParseDrinkEntry()
        
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
                        // drinkEntry = parseDrinkEntry
                        
                        // Update drink
                        parseDrinkEntry.displayName = self.beerTextField.text!
                        parseDrinkEntry.breweryName = self.breweryTextField.text!
                        parseDrinkEntry.beerName = self.beerTextField.text!
                        
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
                            
                            if self.locationCoordinates != nil
                            {
                                parseDrinkEntry.locationCoordinates = self.locationCoordinates
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
                            parseDrinkEntry.remove(forKey: "locationAddress")
                            parseDrinkEntry.remove(forKey: "locationCoordinates")
                            parseDrinkEntry.remove(forKey: "locationID")
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
    */
    
    func editFirebaseDrink(_ objectID: String)
    {
        let defaults = UserDefaults.standard
        let bacEstimation: Bool? = defaults.bool(forKey: "bacEstimation")
        
        var drinkEntry = [String: Any]()
        
        drinkEntry["displayName"] = beerTextField.text!
        drinkEntry["breweryName"] = breweryTextField.text!
        drinkEntry["beerName"] = beerTextField.text!
        
        if locationName != nil && locationID != nil
        {
            drinkEntry["locationName"] = locationName
            drinkEntry["locationID"] = locationID
            
            // if locationAddress is nil, the property will be removed (as it should be)
            drinkEntry["locationAddress"] = locationAddress
            
            if locationLatitude != nil && locationLongitude != nil
            {
                drinkEntry["locationLatitude"] = locationLatitude
                drinkEntry["locationLongitude"] = locationLongitude
            }
            else
            {
                drinkEntry["locationLatitude"] = nil
                drinkEntry["locationLongitude"] = nil
            }
        }
        else
        {
            drinkEntry["locationName"] = nil
            drinkEntry["locationID"] = nil
            drinkEntry["locationAddress"] = nil
            drinkEntry["locationLatitude"] = nil
            drinkEntry["locationLongitude"] = nil
        }
        
        if caption != nil
        {
            drinkEntry["caption"] = caption
        }
        else
        {
            drinkEntry["caption"] = nil
        }
        
        let dateFormatter = DateFormatter()
        // spacing? no spacing? mostly concerned about sorting when fetching
        dateFormatter.dateFormat = "yyyy MM dd HH mm ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
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
            
            drinkEntry["abv"] = abv
            drinkEntry["volume"] = volume
            drinkEntry["volumeUnits"] = volumeUnits
            drinkEntry["effectiveDrinkCount"] = effectiveDrinkCount
            
            drinkEntry["bacEstimation"] = true
            
            drinkEntry["selectedDateTime"] = dateFormatter.string(from: selectedDateTime)
        }
        else
        {
            drinkEntry["abv"] = nil
            drinkEntry["volume"] = nil
            drinkEntry["volumeUnits"] = nil
            drinkEntry["effectiveDrinkCount"] = nil

            drinkEntry["bacEstimation"] = false
            
            // This is redundant if bacEstimation was off when the drink was first saved
            // Also, this shouldn't fail
            if let savedDateTime = drinkBeingEdited?.savedDateTime
            {
                drinkEntry["selectedDateTime"] = dateFormatter.string(from: savedDateTime)
            }
            else
            {
                // try re-fetching the local data? unfortunately, the local drink fetch can fail
                // try fetching the Firebase data? in that case, I'll need some async code
                // save the data I have and try asynchronously updating just the selectedDateTime?
                
                // maybe just not even worry about it?
                // generate an error report of some sort?
            }
        }
        
        firebaseRootRef.child("drinks/\(objectID)").updateChildValues(drinkEntry)
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
                drinkEntry.setValue(beerTextField.text, forKey: "displayName")
                drinkEntry.setValue(breweryTextField.text, forKey: "breweryName")
                drinkEntry.setValue(beerTextField.text, forKey: "beerName")
                
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
