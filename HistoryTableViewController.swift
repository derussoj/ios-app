//
//  HistoryTableViewController.swift
//  Cheers
//
//  Created by Air on 8/19/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData
import Parse

class HistoryTableViewController: UITableViewController {

    var drinkHistory = [DrinkEntry]()
    var cardViewWidth: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // self.view.backgroundColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
        self.view.backgroundColor = UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(HistoryTableViewController.swipedLeft))
        leftSwipeGesture.direction = .left
        self.view.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(HistoryTableViewController.swipedRight))
        rightSwipeGesture.direction = .right
        self.view.addGestureRecognizer(rightSwipeGesture)
        
        self.tabBarController?.view.backgroundColor = UIColor.white
        
        // tableView.estimatedRowHeight = 109
        // tableView.rowHeight = UITableViewAutomaticDimension
        
        // ensures correct shadow width for the cell cardViews
        // the value of 30 is based on the current leading and trailing constraints of 15
        cardViewWidth = UIScreen.main.bounds.width - 30
    }
    
    func swipedLeft()
    {
        guard let tbc = self.tabBarController
            else { return }
        
        guard let fromView = tbc.selectedViewController?.view
            else { return }
        
        guard let toView = tbc.viewControllers?[tbc.selectedIndex + 1].view
            else { return }
        
        fromView.superview?.addSubview(toView)
        
        let offScreenRight = CGAffineTransform(translationX: fromView.frame.width, y: 0)
        let offScreenLeft = CGAffineTransform(translationX: -fromView.frame.width, y: 0)
        
        toView.transform = offScreenRight

        UIView.animate(withDuration: 0.4, animations:
        {
            fromView.transform = offScreenLeft
            toView.transform = CGAffineTransform.identity
        },
        completion:
        {
            finished in
                
            if finished
            {
                fromView.removeFromSuperview()
                    
                tbc.selectedIndex += 1
            }
        })
    }
    
    func swipedRight()
    {
        guard let tbc = self.tabBarController
            else { return }
        
        guard let fromView = tbc.selectedViewController?.view
            else { return }
        
        guard let toView = tbc.viewControllers?[tbc.selectedIndex - 1].view
            else { return }
        
        fromView.superview?.addSubview(toView)
        
        let offScreenRight = CGAffineTransform(translationX: fromView.frame.width, y: 0)
        let offScreenLeft = CGAffineTransform(translationX: -fromView.frame.width, y: 0)
        
        toView.transform = offScreenLeft
        
        UIView.animate(withDuration: 0.4, animations:
        {
            fromView.transform = offScreenRight
            toView.transform = CGAffineTransform.identity
        },
        completion:
        {
            finished in
                
            if finished
            {
                fromView.removeFromSuperview()
                    
                tbc.selectedIndex -= 1
            }
        })
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
        
        // now handled in viewDidLoad
        /*
        // Makes sure cell shadows are the right size.
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        
        // Get and set the "correct" cardView width.
        let firstCellIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        if let firstCell = tableView.cellForRowAtIndexPath(firstCellIndexPath) as? HistoryBeerWineTableViewCell
        {
            cardViewWidth = firstCell.cardView.frame.width
        }
        else if let firstCell = tableView.cellForRowAtIndexPath(firstCellIndexPath) as? HistoryCocktailShotTableViewCell
        {
            cardViewWidth = firstCell.cardView.frame.width
        }
        */
    }
    
    @IBAction func saveEditedDrink(_ segue: UIStoryboardSegue)
    {
        // Do nothing?
    }
    
    @IBAction func deleteDrinkToHistory(_ segue: UIStoryboardSegue)
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
        let drink = drinkHistory[indexPath.row] as DrinkEntry
        
        if drink.type == "beer" || drink.type == "wine"
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryBeerWineCell", for: indexPath) as! HistoryBeerWineTableViewCell
            
            cell.nameLabel.text = drink.displayName
            cell.dateTimeLabel.text = createDateTimeString(i: indexPath.row)
            
            if drink.type == "beer"
            {
                cell.sourceLabel.text = drink.breweryName
                
                cell.iconImageView.image = UIImage(named: "Beer 250 (green)")
            }
            else
            {
                cell.sourceLabel.text = drink.vineyardName
                
                cell.iconImageView.image = UIImage(named: "Wine 250 (green)")
            }
            
            // Makes sure the cardView width is correct.
            if cardViewWidth != nil
            {
                cell.cardView.frame = CGRect(x: cell.cardView.frame.origin.x, y: cell.cardView.frame.origin.y, width: cardViewWidth, height: cell.cardView.frame.height)
            }
            
            return cell
        }
        else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCocktailShotCell", for: indexPath) as! HistoryCocktailShotTableViewCell
            
            cell.nameLabel.text = drink.displayName
            cell.dateTimeLabel.text = createDateTimeString(i: indexPath.row)

            if drink.type == "cocktail"
            {
                cell.iconImageView.image = UIImage(named: "Cocktail 250 (green)")
            }
            else
            {
                cell.iconImageView.image = UIImage(named: "Shot 125 (green)")
            }
            
            // Makes sure the cardView width is correct.
            if cardViewWidth != nil
            {
                cell.cardView.frame = CGRect(x: cell.cardView.frame.origin.x, y: cell.cardView.frame.origin.y, width: cardViewWidth, height: cell.cardView.frame.height)
            }
            
            return cell
        }
    }
    
    func createDateTimeString(i: Int) -> String
    {
        // selected? universal?
        let selectedDateTime = drinkHistory[i].selectedDateTime
        let currentDateTime = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.system

        if NSCalendar.current.isDateInToday(selectedDateTime)
        {
            dateFormatter.timeStyle = DateFormatter.Style.short
        }
        else if currentDateTime.timeIntervalSince(selectedDateTime) < (60 * 60 * 24 * 6)
        {
            dateFormatter.dateFormat = "E, h:mm a"
        }
        else
        {
            dateFormatter.dateFormat = "M/d"
        }
        
        return dateFormatter.string(from: selectedDateTime)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // Need the selected cell so I can pass the selected drink to the details page.
        performSegue(withIdentifier: "DrinkSelection", sender: tableView.cellForRow(at: indexPath))
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return UITableViewAutomaticDimension + 7
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        // Needs to be transparent.
        view.tintColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 0.0)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 109
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
