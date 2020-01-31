//
//  BeerSearchTableViewController.swift
//  Cheers
//
//  Created by Air on 6/7/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class BeerSearchTableViewController: UITableViewController, UISearchBarDelegate {

    var searchText: String!
    
    var selectedIndex: Int? = nil
    
    var selectedBrewery: String!
    var selectedBeer: String!
    var selectedABV: String?
    
    var searchResults = [NSDictionary]()
    
    var messageText: String?
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        searchBar.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(BeerSearchTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        refreshControl?.addTarget(self, action: #selector(BeerSearchTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.backgroundColor = UIColor.white
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
        
        refreshControl?.beginRefreshing()
        
        beerSearch()
    }
    
    func hideKeyboard()
    {
        tableView.endEditing(true)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl)
    {
        if !searchText.isEmpty
        {
            clearSelection()
            
            beerSearch()
        }
        else
        {
            // set messageText

            tableView.reloadData()
            
            refreshControl.endRefreshing()
        }
    }
    
    func clearSelection()
    {
        if selectedIndex != nil
        {
            if let cell = tableView.cellForRow(at: IndexPath(row: selectedIndex!, section: 0))
            {
                cell.accessoryType = .none
            }
            
            selectedIndex = nil
        }
    }
    
    func beerSearch()
    {
        let searchString = "https://api.brewerydb.com/v2/search?key=f02a42ac8c77312548597a9bd7ef4d23&format=json&type=beer&withBreweries=Y&q=\(searchText!)"
        
        let searchURL = URL(string: searchString)
        
        let session = URLSession.shared
                
        // Higher priority.
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async
        {
            let task = session.dataTask(with: searchURL!, completionHandler:
            {
                (data: Data?, response: URLResponse?, error: Error?) -> Void in
                
                if error == nil
                {
                    do
                    {
                        if let jsonDict = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                        {
                            // data?
                            // if let results = jsonDict["data"] as? NSArray
                            if let results = jsonDict["data"] as? [NSDictionary]
                            {
                                self.searchResults = results
                                
                                // this code isn't actually reached when there are no results
                                // see the else statement below
                                if self.searchResults.count == 0
                                {
                                    self.messageText = "Sorry. We weren't able to find any beers that match your search."
                                }
                                
                                DispatchQueue.main.async
                                {
                                    self.tableView.reloadData()
                                    
                                    self.refreshControl?.endRefreshing()
                                }
                            }
                            else
                            {
                                // need to clear the searchResults
                                self.searchResults = []
                                
                                self.messageText = "Sorry. We weren't able to find any beers that match your search."
                                
                                DispatchQueue.main.async
                                {
                                    self.tableView.reloadData()
                                    
                                    self.refreshControl?.endRefreshing()
                                }
                            }
                        }
                    }
                    catch let err as NSError
                    {
                        print("JSON error: \(err)")
                        
                        self.messageText = "Mistakes were made. Please try again."
                        
                        DispatchQueue.main.async
                        {
                            self.tableView.reloadData()
                            
                            self.refreshControl?.endRefreshing()
                        }
                    }
                }
                else
                {
                    print("BreweryDB error: \(error)")
                    
                    self.messageText = "If we had to guess, we'd say you don't have internet access right now. Please try again."
                    
                    DispatchQueue.main.async
                    {
                        self.tableView.reloadData()
                        
                        self.refreshControl?.endRefreshing()
                    }
                }
            })
                    
            task.resume()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        tableView.endEditing(true)
        
        searchText = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !searchText.isEmpty
        {
            clearSelection()
            
            searchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            
            tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
            
            refreshControl?.beginRefreshing()
            
            beerSearch()
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
        if searchResults.count > 0
        {
            return searchResults.count
        }
        else
        {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if searchResults.count > 0
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
            
            let result = searchResults[indexPath.row]
            
            cell.textLabel?.text = result["name"] as? String
            
            let breweryList = result["breweries"] as? [NSDictionary]
            // let brewery: NSDictionary = breweryList!.first!
            if let brewery = breweryList?.first
            {
                cell.detailTextLabel?.text = brewery["name"] as? String
            }
            
            if indexPath.row == selectedIndex
            {
                cell.accessoryType = .checkmark
            }
            else
            {
                cell.accessoryType = .none
            }
            
            tableView.separatorStyle = .singleLine
            
            return cell
        }
        else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath)
            
            cell.textLabel?.text = messageText
            
            tableView.separatorStyle = .none
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // clears old checkmark
        if let index = selectedIndex
        {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
            cell?.accessoryType = .none
        }
        
        selectedIndex = indexPath.row
        
        // sets new checkmark
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
    }

    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if identifier == "SaveBeerSelection"
        {
            if selectedIndex == nil
            {
                alert()
                
                return false
            }
        }
        
        return true
    }
    
    func alert()
    {
        let alertController = UIAlertController(title: "Error", message: "You must select a beer. Otherwise, please hit cancel.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "SaveBeerSelection"
        {
            // should never be nil
            // see shouldPerformSegueWithIdentifier
            if selectedIndex != nil
            {
                let selectedResult = searchResults[selectedIndex!]
                
                selectedBeer = selectedResult["name"] as? String
                
                let breweryList = selectedResult["breweries"] as? [NSDictionary]
                let brewery: NSDictionary = breweryList!.first!
                selectedBrewery = brewery["name"] as? String
                
                if let abv = selectedResult["abv"] as? String
                {
                    selectedABV = abv
                }

            }
        }
    }

}
