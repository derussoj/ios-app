//
//  AddRecentTableViewController.swift
//  Cheers
//
//  Created by Air on 7/12/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData

class AddRecentTableViewController: UITableViewController {

    var recentDrinks = [DrinkEntry]()
    // var selectedDrink = DrinkEntry()
    var selectedDrink: DrinkEntry?
    
    override func viewDidLoad()
    {
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
                recentDrinks = unique(results: results)
                
                // Update UI.
                self.tableView.reloadData()
            }
        }
        catch let error
        {
            print("Could not fetch \(error)")
        }
    }
    
    func unique(results: [DrinkEntry]) -> [DrinkEntry]
    {
        var uniqueResults = [DrinkEntry]()
        
        var i = 0
        
        for result in results
        {
            if uniqueResults.count == 0
            {
                uniqueResults.append(result)
                
                i += 1
            }
            else
            {
                var isUnique: Bool = true
                
                for uniqueResult in uniqueResults
                {
                    if isEqualTo(drink: result, uniqueResult: uniqueResult)
                    {
                        isUnique = false
                    }
                }
                
                if isUnique == true
                {
                    uniqueResults.append(result)
                    
                    i += 1
                    
                    if i == 15
                    {
                        break
                    }
                }
            }
            
            /*
            if !uniqueResults.contains(result)
            {
                uniqueResults.append(result)
                
                i++
                
                if i == 15
                {
                    break
                }
            }
            */
        }
        
        return uniqueResults
    }
    
    func isEqualTo(drink: DrinkEntry, uniqueResult: DrinkEntry) -> Bool
    {
        if drink.type != uniqueResult.type
        {
            return false
        }
        else
        {
            if drink.type == "beer"
            {
                return drink.breweryName == uniqueResult.breweryName && drink.beerName == uniqueResult.beerName && drink.locationName == uniqueResult.locationName
            }
            else if drink.type == "wine"
            {
                return drink.vineyardName == uniqueResult.vineyardName && drink.wineName == uniqueResult.wineName && drink.vintage == uniqueResult.vintage && drink.locationName == uniqueResult.locationName
            }
            else if drink.type == "cocktail"
            {
                if drink.entryMode != uniqueResult.entryMode
                {
                    return false
                }
                else
                {
                    if drink.entryMode == 0
                    {
                        return drink.displayName == uniqueResult.displayName && drink.effectiveDrinkCount == uniqueResult.effectiveDrinkCount && drink.locationName == uniqueResult.locationName
                    }
                    else
                    {
                        return drink.displayName == uniqueResult.displayName && drink.ingredients == uniqueResult.ingredients && drink.locationName == uniqueResult.locationName
                    }
                }
            }
            else // shots
            {
                if drink.entryMode != uniqueResult.entryMode
                {
                    return false
                }
                else
                {
                    if drink.entryMode == 0
                    {
                        return drink.displayName == uniqueResult.displayName && drink.effectiveDrinkCount == uniqueResult.effectiveDrinkCount && drink.locationName == uniqueResult.locationName
                    }
                    else
                    {
                        return drink.displayName == uniqueResult.displayName && drink.ingredients == uniqueResult.ingredients && drink.locationName == uniqueResult.locationName
                    }
                }
            }
        }
    }
    
    @IBAction func cancelToAddRecent(_ segue: UIStoryboardSegue)
    {
        // Do nothing.
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
        return recentDrinks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let drink = recentDrinks[indexPath.row] as DrinkEntry
        
        var icon: UIImage?
        
        if drink.type == "beer"
        {
            icon = UIImage(named: "Beer 250 (green)")
        }
        else if drink.type == "wine"
        {
            icon = UIImage(named: "Wine 250 (green)")
        }
        else if drink.type == "cocktail"
        {
            icon = UIImage(named: "Cocktail 250 (green)")
        }
        else if drink.type == "shot"
        {
            icon = UIImage(named: "Shot 125 (green)")
        }
        
        if let locationName = drink.locationName
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentDrinkWithLocationCell", for: indexPath as IndexPath) as! RecentDrinkWithLocationCell
            
            cell.nameLabel.text = drink.displayName
            cell.locationLabel.text = locationName
            cell.iconImageView.image = icon
            
            return cell
        }
        else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentDrinkCell", for: indexPath as IndexPath) as! RecentDrinkCell
            
            cell.nameLabel.text = drink.displayName
            cell.iconImageView.image = icon
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        selectedDrink = recentDrinks[indexPath.row] as DrinkEntry
        
        if selectedDrink?.type == "beer"
        {
            performSegue(withIdentifier: "LoadRecentBeer", sender: self)
        }
        else if selectedDrink?.type == "wine"
        {
            performSegue(withIdentifier: "LoadRecentWine", sender: self)
        }
        else if selectedDrink?.type == "cocktail"
        {
            performSegue(withIdentifier: "LoadRecentCocktail", sender: self)
        }
        else if selectedDrink?.type == "shot"
        {
            performSegue(withIdentifier: "LoadRecentShot", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60
    }

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
        if segue.identifier == "LoadRecentBeer"
        {
            if let addBeerTableViewController = segue.destination as? AddBeerTableViewController
            {
                addBeerTableViewController.shouldLoadRecentDrink = true
                addBeerTableViewController.recentDrink = selectedDrink
            }
        }
        else if segue.identifier == "LoadRecentWine"
        {
            if let addWineTableViewController = segue.destination as? AddWineTableViewController
            {
                addWineTableViewController.shouldLoadRecentDrink = true
                addWineTableViewController.recentDrink = selectedDrink
            }
        }
        else if segue.identifier == "LoadRecentCocktail"
        {
            if let addCocktailTableViewController = segue.destination as? AddCocktailTableViewController
            {
                addCocktailTableViewController.shouldLoadRecentDrink = true
                addCocktailTableViewController.recentDrink = selectedDrink
            }
        }
        else if segue.identifier == "LoadRecentShot"
        {
            if let addShotTableViewController = segue.destination as? AddShotTableViewController
            {
                addShotTableViewController.shouldLoadRecentDrink = true
                addShotTableViewController.recentDrink = selectedDrink
            }
        }
    }

}
