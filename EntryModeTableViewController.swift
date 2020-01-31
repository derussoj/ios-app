//
//  EntryModeTableViewController.swift
//  Cheers
//
//  Created by Air on 7/2/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class EntryModeTableViewController: UITableViewController {

    var entryModes = ["Quick", "Full"]
    var selectedEntryModeIndex: Int? = nil
    
    var sendingView: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if selectedEntryModeIndex != nil
        {
            tableView.selectRow(at: IndexPath(row: selectedEntryModeIndex!, section: 0), animated: false, scrollPosition: UITableViewScrollPosition.none)
        }
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
        return entryModes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntryModeCell", for: indexPath)

        cell.textLabel?.text = entryModes[indexPath.row]
        
        if indexPath.row == selectedEntryModeIndex
        {
            cell.accessoryType = .checkmark
        }
        else
        {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //Other row is selected - need to deselect it
        if let index = selectedEntryModeIndex
        {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
            cell?.accessoryType = .none
        }
        
        selectedEntryModeIndex = indexPath.row
        
        //update the checkmark for the current row
        let cell = tableView.cellForRow(at: indexPath as IndexPath)
        cell?.accessoryType = .checkmark
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
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem)
    {
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
        if sendingView == "AddCocktail"
        {
            performSegue(withIdentifier: "SaveEntryModeToAddCocktail", sender: self)
        }
        else if sendingView == "AddShot"
        {
            performSegue(withIdentifier: "SaveEntryModeToAddShot", sender: self)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
