//
//  VolumeUnitsTableViewController.swift
//  Cheers
//
//  Created by Air on 5/25/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class VolumeUnitsTableViewController: UITableViewController {

    var units = ["oz", "ml"]
    var selectedUnitsIndex: Int? = nil
    
    var sendingView: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if selectedUnitsIndex != nil
        {
            tableView.selectRow(at: IndexPath(row: selectedUnitsIndex!, section: 0), animated: false, scrollPosition: UITableViewScrollPosition.none)
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
        return units.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnitsCell", for: indexPath)
        
        cell.textLabel?.text = units[indexPath.row]
        
        if indexPath.row == selectedUnitsIndex
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
        
        // clears old checkmark
        if let index = selectedUnitsIndex
        {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
            cell?.accessoryType = .none
        }
        
        selectedUnitsIndex = indexPath.row
        
        // sets new checkmark
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
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
        else if sendingView == "AddIngredients"
        {
            performSegue(withIdentifier: "CancelToAddIngredients", sender: self)
        }
    }
    
    @IBAction func saveAction(_ sender: UIBarButtonItem)
    {
        if sendingView == "AddBeer"
        {
            performSegue(withIdentifier: "SaveVolumeUnitsToAddBeer", sender: self)
        }
        else if sendingView == "AddWine"
        {
            performSegue(withIdentifier: "SaveVolumeUnitsToAddWine", sender: self)
        }
        else if sendingView == "AddIngredients"
        {
            performSegue(withIdentifier: "SaveVolumeUnitsToAddIngredients", sender: self)
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
