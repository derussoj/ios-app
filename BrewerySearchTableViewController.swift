//
//  BrewerySearchTableViewController.swift
//  Cheers
//
//  Created by Air on 6/10/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class BrewerySearchTableViewController: UITableViewController, UISearchBarDelegate {

    var searchText: String!
    
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(BrewerySearchTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        refreshControl?.addTarget(self, action: #selector(BrewerySearchTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.backgroundColor = UIColor.white
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
        
        refreshControl?.beginRefreshing()
        
        brewerySearch()
    }
    
    func hideKeyboard()
    {
        tableView.endEditing(true)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl)
    {
        if !searchText.isEmpty
        {
            brewerySearch()
        }
        else
        {
            // set messageText
            
            tableView.reloadData()
            
            refreshControl.endRefreshing()
        }
    }
    
    func brewerySearch()
    {
        let searchString = "https://api.brewerydb.com/v2/search?key=f02a42ac8c77312548597a9bd7ef4d23&format=json&type=brewery&q=\(searchText!)"
        
        // Need a brewery beer search somewhere.
        
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
                                    self.messageText = "Sorry. We weren't able to find any breweries that match your search."
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
                                
                                self.messageText = "Sorry. We weren't able to find any breweries that match your search."
                                
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
            searchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            
            tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
            
            refreshControl?.beginRefreshing()
            
            brewerySearch()
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
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "BreweryBeerSelection"
        {
            if let selectedCell = sender as? UITableViewCell
            {
                if let selectedIndexPath = tableView.indexPath(for: selectedCell)
                {
                    let selectedResult = searchResults[selectedIndexPath.row]
                    
                    if let breweryBeerSearchTableViewController = segue.destination as? BreweryBeerSearchTableViewController
                    {
                        breweryBeerSearchTableViewController.selectedBreweryID = selectedResult["id"] as? String
                        breweryBeerSearchTableViewController.selectedBrewery = selectedResult["name"] as? String
                    }
                }
            }
        }
    }

}
