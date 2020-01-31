//
//  HistoryDetailsTableViewController.swift
//  Cheers
//
//  Created by Air on 7/24/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData
import Parse
import Firebase

class HistoryDetailsTableViewController: UITableViewController {

    var selectedDrinkEntry: DrinkEntry!
    
    let firebaseRootRef = FIRDatabase.database().reference()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    
    @IBOutlet weak var drinkEntryNameLabel: UILabel!
    @IBOutlet weak var drinkEntrySourceLabel: UILabel!
    @IBOutlet weak var drinkEntryVintageLabel: UILabel!
    @IBOutlet weak var drinkEntryABVLabel: UILabel!
    @IBOutlet weak var drinkEntryVolumeLabel: UILabel!
    @IBOutlet weak var drinkEntryEffectiveDrinksLabel: UILabel!
    @IBOutlet weak var drinkEntryIngredientsLabel: UILabel!
    @IBOutlet weak var drinkEntryDateTimeLabel: UILabel!
    @IBOutlet weak var drinkEntryLocationLabel: UILabel!
    @IBOutlet weak var drinkEntryCaptionLabel: UILabel!
    @IBOutlet weak var drinkEntryCommentsLabel: UILabel!
    
    @IBOutlet weak var commentsCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        setLabels()
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func setLabels()
    {
        if selectedDrinkEntry.type == "beer"
        {
            nameLabel.text = "Beer"
            sourceLabel.text = "Brewery"
            
            drinkEntryNameLabel.text = selectedDrinkEntry.beerName
            drinkEntrySourceLabel.text = selectedDrinkEntry.breweryName
            
            if selectedDrinkEntry.bacEstimation == true
            {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                
                let formattedABV = numberFormatter.string(from: selectedDrinkEntry.abv!)
                let formattedVolume = numberFormatter.string(from: selectedDrinkEntry.volume!)
                
                drinkEntryABVLabel.text = "\(formattedABV!)%"
                if selectedDrinkEntry.volumeUnits == 0
                {
                    drinkEntryVolumeLabel.text = "\(formattedVolume!) oz"
                }
                else
                {
                    drinkEntryVolumeLabel.text = "\(formattedVolume!) ml"
                }
                
            }
        }
        else if selectedDrinkEntry.type == "wine"
        {
            nameLabel.text = "Wine"
            sourceLabel.text = "Vineyard"
            
            drinkEntryNameLabel.text = selectedDrinkEntry.wineName
            drinkEntrySourceLabel.text = selectedDrinkEntry.vineyardName
            drinkEntryVintageLabel.text = selectedDrinkEntry.vintage
            
            if selectedDrinkEntry.bacEstimation == true
            {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                
                let formattedABV = numberFormatter.string(from: selectedDrinkEntry.abv!)
                let formattedVolume = numberFormatter.string(from: selectedDrinkEntry.volume!)
                
                drinkEntryABVLabel.text = "\(formattedABV!)%"
                if selectedDrinkEntry.volumeUnits == 0
                {
                    drinkEntryVolumeLabel.text = "\(formattedVolume!) oz"
                }
                else
                {
                    drinkEntryVolumeLabel.text = "\(formattedVolume!) ml"
                }
                
            }
        }
        else if selectedDrinkEntry.type == "cocktail" || selectedDrinkEntry.type == "shot"
        {
            if selectedDrinkEntry.type == "cocktail"
            {
                nameLabel.text = "Cocktail"
            }
            else if selectedDrinkEntry.type == "shot"
            {
                nameLabel.text = "Shot"
            }
            
            drinkEntryNameLabel.text = selectedDrinkEntry.displayName
            
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            
            if selectedDrinkEntry.entryMode == 0
            {
                drinkEntryEffectiveDrinksLabel.text = numberFormatter.string(from: selectedDrinkEntry.effectiveDrinkCount!)
            }
            else
            {
                // should always be at least 1 ingredient
                var ingredientsString = String()
                
                var i = 0
                let n = selectedDrinkEntry.ingredients!.count
                while i < n
                {
                    // shouldn't fail in this scenario
                    if let ingredient = selectedDrinkEntry.ingredients?.object(at: i) as? Ingredient
                    {
                        if let volume = ingredient.volume
                        {
                            if let formattedVolume = numberFormatter.string(from: volume)
                            {
                                if i == 0
                                {
                                    // if there's a volume, there should be volumeUnits
                                    if ingredient.volumeUnits == 0
                                    {
                                        ingredientsString = "\(ingredient.name) (\(formattedVolume) oz)"
                                    }
                                    // else if ingredient.volumeUnits == 1?
                                    else
                                    {
                                        ingredientsString = "\(ingredient.name) (\(formattedVolume) ml)"
                                    }
                                }
                                else
                                {
                                    // if there's a volume, there should be volumeUnits
                                    if ingredient.volumeUnits == 0
                                    {
                                        ingredientsString = "\(ingredientsString)\n\(ingredient.name) (\(formattedVolume) oz)"
                                    }
                                    // else if ingredient.volumeUnits == 1?
                                    else
                                    {
                                        ingredientsString = "\(ingredientsString)\n\(ingredient.name) (\(formattedVolume) ml)"
                                    }
                                }
                            }
                        }
                        else
                        {
                            if i == 0
                            {
                                ingredientsString = ingredient.name
                            }
                            else
                            {
                                // for some reason, I was using the first one for cocktails and the second one for shots
                                // the second one matches what I'm doing above
                                // ingredientsString = "\(ingredientsString), \(ingredient.name)"
                                ingredientsString = "\(ingredientsString)\n\(ingredient.name)"
                            }
                        }
                    }
                    
                    i += 1
                }
                
                drinkEntryIngredientsLabel.text = ingredientsString
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = NSTimeZone.system
        drinkEntryDateTimeLabel.text = dateFormatter.string(from: selectedDrinkEntry.universalDateTime)
        
        if selectedDrinkEntry.locationName != nil
        {
            drinkEntryLocationLabel.text = selectedDrinkEntry.locationName
        }
        
        if selectedDrinkEntry.caption != nil
        {
            drinkEntryCaptionLabel.text = selectedDrinkEntry.caption
        }
        
        if selectedDrinkEntry.drinkObjectID != nil
        {
            // Set comment detail label to "fetching..."?
            // Progress bar?
            
            drinkEntryCommentsLabel.text = "fetching..."
            commentsCell.isUserInteractionEnabled = false
            // should I change the appearance of the label text too?
            
            fetchComments()
        }
    }
    
    func fetchComments()
    {
        // get commentNumber and comments from Parse
        // and likes?
        // update UI
    }
    
    @IBAction func actionButtonSelected(_ sender: UIBarButtonItem)
    {
        // don't think I need this check anymore
        if objc_getClass("UIAlertController") != nil
        {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                // ...
            }
            alertController.addAction(cancelAction)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                self.deleteDrink()
            }
            alertController.addAction(deleteAction)
            
            let editAction = UIAlertAction(title: "Edit", style: .default) { (action) in
                self.performEditSegue()
            }
            alertController.addAction(editAction)
            
            self.present(alertController, animated: true) {
                // ...
            }
        }
    }
    
    func deleteDrink()
    {
        // Delete from Parse
        if let objectID = selectedDrinkEntry.drinkObjectID
        {
            if !objectID.isEmpty
            {
                let currentUser = PFUser.current()
                if currentUser != nil
                {
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
                                    // Delete ingredients
                                    if (parseDrinkEntry.type == "cocktail" || parseDrinkEntry.type == "shot") && parseDrinkEntry.cocktailEntryMode == 1
                                    {
                                        let ingredients = parseDrinkEntry.ingredients
                                        for ingredient in ingredients
                                        {
                                            // I think deleteEventually should be fine?
                                            ingredient.deleteEventually()
                                        }
                                    }
                                                
                                    // I think deleteEventually should be fine?
                                    parseDrinkEntry.deleteEventually()
                                }
                            }
                            else
                            {
                                // Alert.
                                
                                if error != nil
                                {
                                    print("error in deleteDrink: \(error!)")
                                }
                                else
                                {
                                    print("error in deleteDrink: object is nil")
                                }
                            }
                        }
                    }
                }
                else
                {
                    // The drinkEntry has an objectID but the user is no longer logged in
                    // Alert the user that the drinkEntry won't be deleted unless they log back in
                }
            }
        }
        
        
        
        // Do I need an activity indicator now?
        // Probably.
        // Use a minimum duration like on the AddBeer page.
        
        
        
        // Delete from Firebase
        if let objectID = selectedDrinkEntry.drinkObjectID
        {
            if !objectID.isEmpty
            {
                if let uid = FIRAuth.auth()?.currentUser?.uid
                {
                    fetchFriends(uid: uid)
                    {
                        (friendsFetched: Bool, friends: [String]) in
                        
                        if friendsFetched == true
                        {
                            self.fetchFollowers(uid: uid)
                            {
                                (followersFetched: Bool, followers: [String]) in
                                
                                if followersFetched == true
                                {
                                    self.firebaseRootRef.child("drinks/\(objectID)").removeValue()
                                    
                                    
                                    
                                    
                                    
                                    
                                    // also need to delete the drink's ingredients if it has any
                                    
                                    
                                    
                                    
                                    
                                    
                                    self.firebaseRootRef.child("users/\(uid)/drinks/\(objectID)").removeValue()
                                    
                                    
                                    
                                    
                                    
                                    
                                    // During testing only!
                                    self.firebaseRootRef.child("users/\(uid)/feeds/friends/\(objectID)").removeValue()
                                    self.firebaseRootRef.child("users/\(uid)/feeds/followees/\(objectID)").removeValue()
                                    
                                    
                                    
                                    
                                    
                                    
                                    for friendID in friends
                                    {
                                        self.firebaseRootRef.child("users/\(friendID)/feeds/friends/\(objectID)").removeValue()
                                    }
                                    
                                    for followerID in followers
                                    {
                                        self.firebaseRootRef.child("users/\(followerID)/feeds/followees/\(objectID)").removeValue()
                                    }
                                    
                                    self.deleteDrinkLocally()
                                }
                                else
                                {
                                    // stop the activity indicator
                                    // alert
                                }
                            }
                        }
                        else
                        {
                            // stop the activity indicator
                            // alert
                        }
                    }
                }
                else
                {
                    // The drinkEntry has an objectID, but the user is no longer logged in.
                    // Alert the user that the drinkEntry won't be deleted unless they log back in.
                }
            }
            else
            {
                deleteDrinkLocally()
            }
        }
        else
        {
            deleteDrinkLocally()
        }
    }
    
    func fetchFriends(uid: String, completion: @escaping (_ friendsFetched: Bool, _ friends: [String]) -> Void)
    {
        // 10 seconds?
        let timeout = DispatchWorkItem{completion(false, [String]())}
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: timeout)
        
        firebaseRootRef.child("users/\(uid)/friends").observeSingleEvent(of: .value, with:
        {
            snapshot in
            
            timeout.cancel()
            
            var friends = [String]()
                
            if snapshot.value is NSNull
            {
                // Do nothing. This just indicates that the user doesn't have any friends.
            }
            else
            {
                let enumerator = snapshot.children
                
                while let friend = enumerator.nextObject() as? FIRDataSnapshot
                {
                    friends.append(friend.key)
                }
            }
            
            completion(true, friends)
        })
    }
    
    func fetchFollowers(uid: String, completion: @escaping (_ followersFetched: Bool, _ followers: [String]) -> Void)
    {
        // 10 seconds?
        let timeout = DispatchWorkItem{completion(false, [String]())}
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: timeout)
        
        firebaseRootRef.child("users/\(uid)/followers").observeSingleEvent(of: .value, with:
        {
            snapshot in
                
            timeout.cancel()
                
            var followers = [String]()
                
            if snapshot.value is NSNull
            {
                // Do nothing. This just indicates that the user doesn't have any followers.
            }
            else
            {
                let enumerator = snapshot.children
                    
                while let follower = enumerator.nextObject() as? FIRDataSnapshot
                {
                    followers.append(follower.key)
                }
            }
                
            completion(true, followers)
        })
    }
    
    func deleteDrinkLocally()
    {
        // Delete from mostRecentSession
        var mostRecentSession = loadMostRecentSession()
        
        if let index = mostRecentSession.index(of: selectedDrinkEntry)
        {
            mostRecentSession.remove(at: index)
            
            saveMostRecentSession(mostRecentSession: mostRecentSession)
        }
        
        // Delete from Core Data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        managedContext.delete(selectedDrinkEntry as NSManagedObject)
        // When necessary, ingredients are deleted via "Delete Rule" = "Cascade"
        
        do
        {
            try managedContext.save()
        }
        catch let error
        {
            print("Could not delete \(error)")
            
            // Alert? Make a note to try again later?
        }
        
        
        
        
        
        
        // stop the activity indicator
        
        
        
        
        
        
        // Segue back to History
        performSegue(withIdentifier: "DeleteDrinkToHistory", sender: self)
    }
    
    func loadMostRecentSession() -> [DrinkEntry]
    {
        let defaults = UserDefaults.standard
        
        if let mostRecentSessionIDs = defaults.array(forKey: "mostRecentSessionIDs") as? [String]
        {
            var mostRecentSession = [DrinkEntry]()
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            for id in mostRecentSessionIDs
            {
                if let idURL = URL(string: id)
                {
                    if let objectID = managedContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: idURL)
                    {
                        do
                        {
                            if let drinkEntry = try managedContext.existingObject(with: objectID) as? DrinkEntry
                            {
                                mostRecentSession.append(drinkEntry)
                            }
                        }
                        catch let error as NSError
                        {
                            print("Error in loadMostRecentSession: \(error)")
                        }
                    }
                }
            }
            
            return mostRecentSession
        }
        else
        {
            return [DrinkEntry]()
        }
    }
    
    func saveMostRecentSession(mostRecentSession: [DrinkEntry])
    {
        var mostRecentSessionIDs = [String]()
        
        for drinkEntry in mostRecentSession
        {
            // I don't believe I can save the objectID itself to UserDefaults
            mostRecentSessionIDs.append(drinkEntry.objectID.uriRepresentation().absoluteString)
        }
        
        let defaults = UserDefaults.standard
        defaults.set(mostRecentSessionIDs, forKey: "mostRecentSessionIDs")
    }
    
    func performEditSegue()
    {
        if selectedDrinkEntry.type == "beer"
        {
            performSegue(withIdentifier: "EditBeer", sender: self)
        }
        else if selectedDrinkEntry.type == "wine"
        {
            performSegue(withIdentifier: "EditWine", sender: self)
        }
        else if selectedDrinkEntry.type == "cocktail"
        {
            performSegue(withIdentifier: "EditCocktail", sender: self)
        }
        else if selectedDrinkEntry.type == "shot"
        {
            performSegue(withIdentifier: "EditShot", sender: self)
        }
    }
    
    @IBAction func cancelToHistoryDetails(_ segue: UIStoryboardSegue)
    {
        // Do nothing.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let sourceIndexPath = IndexPath(row: 1, section: 0)
        let vintageIndexPath = IndexPath(row: 2, section: 0)
        let abvIndexPath = IndexPath(row: 3, section: 0)
        let volumeIndexPath = IndexPath(row: 4, section: 0)
        let effectiveDrinksIndexPath = IndexPath(row: 5, section: 0)
        
        let locationIndexPath = IndexPath(row: 1, section: 1)
        let captionIndexPath = IndexPath(row: 2, section: 1)
        
        if indexPath == sourceIndexPath && (selectedDrinkEntry.type == "cocktail" || selectedDrinkEntry.type == "shot")
        {
            return 0
        }
        else if indexPath == vintageIndexPath && selectedDrinkEntry.type != "wine"
        {
            return 0
        }
        else if indexPath == abvIndexPath || indexPath == volumeIndexPath
        {
            if selectedDrinkEntry.type == "cocktail" || selectedDrinkEntry.type == "shot" || selectedDrinkEntry.bacEstimation == false
            {
                return 0
            }
        }
        // there's no effective drinks row at all unless the drink type is cocktail or shot
        else if indexPath == effectiveDrinksIndexPath && selectedDrinkEntry.entryMode == 1
        {
            return 0
        }
        else if indexPath == locationIndexPath && selectedDrinkEntry.locationName == nil
        {
            return 0
        }
        else if indexPath == captionIndexPath && selectedDrinkEntry.caption == nil
        {
            return 0
        }
        
        // eliminates the need for else statements above
        return UITableViewAutomaticDimension
    }

    /*
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 0
    }
    */

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // Return the number of rows in the section.
        
        if section == 0
        {
            if selectedDrinkEntry.type != "cocktail" && selectedDrinkEntry.type != "shot"
            {
                if selectedDrinkEntry.bacEstimation == true
                {
                    return 5
                }
                else
                {
                    if selectedDrinkEntry.type == "beer"
                    {
                        return 2
                    }
                    else
                    {
                        return 3
                    }
                }
            }
            else
            {
                if selectedDrinkEntry.entryMode == 0
                {
                    return 6
                }
                else
                {
                    return 7
                }
            }
        }
        else
        {
            var rows = 4
            
            // If there's no drinkObjectID, there shouldn't be any comments.
            // Show the comments cell even when there are no comments? Before fetching is complete?
            if selectedDrinkEntry.drinkObjectID == nil
            {
               rows -= 1
                
                if selectedDrinkEntry.caption == nil
                {
                    rows -= 1
                    
                    if selectedDrinkEntry.locationName == nil
                    {
                        rows -= 1
                    }
                }
            }
            
            return rows
        }
    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
        if segue.identifier == "EditBeer"
        {
            // if let addBeerTableViewController = segue.destinationViewController.topViewController as? AddBeerTableViewController
            if let addBeerTableViewController = segue.destination.childViewControllers[0] as? AddBeerTableViewController
            {
                addBeerTableViewController.editingDrink = true
                addBeerTableViewController.drinkBeingEdited = selectedDrinkEntry
            }
        }
        else if segue.identifier == "EditWine"
        {
            // if let addWineTableViewController = segue.destinationViewController.topViewController as? AddWineTableViewController
            if let addWineTableViewController = segue.destination.childViewControllers[0] as? AddWineTableViewController
            {
                addWineTableViewController.editingDrink = true
                addWineTableViewController.drinkBeingEdited = selectedDrinkEntry
            }
        }
        else if segue.identifier == "EditCocktail"
        {
            // if let addCocktailTableViewController = segue.destinationViewController.topViewController as? AddCocktailTableViewController
            if let addCocktailTableViewController = segue.destination.childViewControllers[0] as? AddCocktailTableViewController
            {
                addCocktailTableViewController.editingDrink = true
                addCocktailTableViewController.drinkBeingEdited = selectedDrinkEntry
            }
        }
        else if segue.identifier == "EditShot"
        {
            // if let addShotTableViewController = segue.destinationViewController.topViewController as? AddShotTableViewController
            if let addShotTableViewController = segue.destination.childViewControllers[0] as? AddShotTableViewController
            {
                addShotTableViewController.editingDrink = true
                addShotTableViewController.drinkBeingEdited = selectedDrinkEntry
            }
        }
    }

}
