//
//  HistoryViewController.swift
//  Cheers
//
//  Created by Air on 5/4/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData
import Parse

class HistoryViewController: UITableViewController {

    var drinkHistory = [DrinkEntry]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName:"DrinkEntry")
        fetchRequest.fetchLimit = 50
        
        // universalDateTime?
        let sortDescriptor = NSSortDescriptor(key: "selectedDateTime", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do
        {
            let fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
            
            // if let results = fetchedResults
            if let results = fetchedResults as? [DrinkEntry]
            {
                drinkHistory = results
                
                // Update UI.
                self.tableView.reloadData()
            }
        }
        catch let error
        {
            print("Could not fetch \(error)")
        }
    }
    
    @IBAction func saveEditedDrink(_ segue: UIStoryboardSegue)
    {
        // Do nothing?
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return drinkHistory.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DrinkCell", for: indexPath)

        let drink = drinkHistory[indexPath.row] as DrinkEntry
        cell.textLabel?.text = drink.displayName
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = NSTimeZone.system
        
        cell.detailTextLabel?.text = dateFormatter.string(from: drink.selectedDateTime)

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            let drinkEntry = drinkHistory[indexPath.row]
            
            // Delete from Parse
            if let objectID = drinkEntry.drinkObjectID
            {
                if !objectID.isEmpty
                {
                    if PFUser.current() != nil
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
                                    // return?
                                    
                                    if error != nil
                                    {
                                        print("error in commit: \(error!)")
                                    }
                                    else
                                    {
                                        print("error in commit: object is nil")
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        // The drinkEntry has an objectID but the user is no longer logged in
                        // Alert the user that the drinkEntry won't be deleted unless they log back in
                        // return?
                    }
                }
            }
            
            // Delete from mostRecentSession
            /*
            let defaults = UserDefaults.standard
            if let data = defaults.object(forKey: "mostRecentSession") as? Data
            {
                if var mostRecentSession = NSKeyedUnarchiver.unarchiveObject(with: data) as? [DrinkEntry]
                {
                    if let index = mostRecentSession.index(of: drinkEntry)
                    {
                        mostRecentSession.remove(at: index)
                        
                        defaults.setValue(NSKeyedArchiver.archivedData(withRootObject: mostRecentSession), forKey: "mostRecentSession")
                    }
                }
            }
            */
            var mostRecentSession = loadMostRecentSession()
            
            if let index = mostRecentSession.index(of: drinkEntry)
            {
                mostRecentSession.remove(at: index)
                
                saveMostRecentSession(mostRecentSession: mostRecentSession)
            }
            
            // Delete from Core Data
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext            
            managedContext.delete(drinkEntry as NSManagedObject)
            // When necessary, ingredients are deleted via "Delete Rule" = "Cascade"
            
            do
            {
                try managedContext.save()
            }
            catch let error
            {
                print("Could not delete \(error)")
            }
            
            // Delete from drinkHistory
            drinkHistory.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        /*
        else if editingStyle == .Insert
        {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        */
    }
    
    func saveMostRecentSession(mostRecentSession: [DrinkEntry])
    {
        var mostRecentSessionIDs = [URL]()
        
        for drinkEntry in mostRecentSession
        {
            // I don't believe I can save the objectID itself to UserDefaults
            mostRecentSessionIDs.append(drinkEntry.objectID.uriRepresentation())
        }
        
        let defaults = UserDefaults.standard
        defaults.set(mostRecentSessionIDs, forKey: "mostRecentSessionIDs")
    }
    
    func loadMostRecentSession() -> [DrinkEntry]
    {
        let defaults = UserDefaults.standard
        
        if let mostRecentSessionIDs = defaults.array(forKey: "mostRecentSessionIDs") as? [URL]
        {
            var mostRecentSession = [DrinkEntry]()
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            for idURL in mostRecentSessionIDs
            {
                if let id = managedContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: idURL)
                {
                    do
                    {
                        if let drinkEntry = try managedContext.existingObject(with: id) as? DrinkEntry
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
            
            return mostRecentSession
        }
        else
        {
            return [DrinkEntry]()
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
        if segue.identifier == "DrinkSelection"
        {
            if let selectedCell = sender as? UITableViewCell
            {
                if let selectedIndexPath = tableView.indexPath(for: selectedCell)
                {
                    let selectedResult = drinkHistory[selectedIndexPath.row]
                    
                    if let historyDetailsTableViewController = segue.destination as? HistoryDetailsTableViewController
                    {
                        historyDetailsTableViewController.selectedDrinkEntry = selectedResult
                    }
                }
            }
        }
    }

}
