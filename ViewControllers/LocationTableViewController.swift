//
//  LocationTableViewController.swift
//  Cheers
//
//  Created by Air on 5/25/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreLocation

class LocationTableViewController: UITableViewController, CLLocationManagerDelegate, UISearchBarDelegate {

    let locationManager = CLLocationManager()
    
    var nearbyPlaces = [Place]()

    var shouldFindPlaces: Bool! = true
    
    var nearbySearchInProgress: Bool?
    var textSearchRequested: Bool?
    var userTextQuery: String?

    var messageText: String?
    
    var selectedRow: Int? = nil
    var selectedSection: Int? = nil
    
    var selectedLocationName: String!
    var selectedLocationID: String!
    var selectedLocationAddress: String?
    var selectedLocationLatitude: String?
    var selectedLocationLongitude: String?
    
    var mostRecentLocation: MostRecentLocation!
    
    var sendingView: String!
    
    @IBOutlet weak var locationSearchBar: UISearchBar!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        locationSearchBar.delegate = self
        locationSearchBar.isHidden = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(LocationTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        self.refreshControl?.addTarget(self, action: #selector(LocationTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        // Also check my setting? Is that redundant?
        
        if CLLocationManager.authorizationStatus() == .notDetermined
        {
            locationManager.requestWhenInUseAuthorization()
        }
        else if CLLocationManager.authorizationStatus() == .denied
        {
            locationSearchBar.frame = CGRect(x: locationSearchBar.frame.origin.x, y: locationSearchBar.frame.origin.y, width: locationSearchBar.frame.width, height: 0)
            
            if refreshControl?.isRefreshing == true
            {
                refreshControl?.endRefreshing()
            }
            refreshControl = nil
            
            messageText = "Etto is not authorized to find your location. To change this, please go to Settings -> Privacy -> Location Services."
        }
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func hideKeyboard()
    {
        tableView.endEditing(true)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl)
    {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways
        {
            clearSelection()
            
            if let locationCoordinates: CLLocationCoordinate2D = locationManager.location?.coordinate
            {
                findNearbyPlaces(coordinates: locationCoordinates)
            }
            else
            {
                // As far as I can tell, handleRefresh can only be called if the refreshControl is not refreshing. If the refreshControl was not refreshing and there's no location yet, something went wrong.

                messageText = "Something appears to have gone terribly wrong. We'd recommend going back to the previous page and then trying again."
                
                self.tableView.reloadData()
                
                refreshControl.endRefreshing()
            }
        }
        else
        {
            // Shouldn't be able to reach this code.
            refreshControl.endRefreshing()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        if status == .authorizedWhenInUse || status == .authorizedAlways
        {
            locationSearchBar.isHidden = false
            
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
            
            refreshControl?.beginRefreshing()
            
            locationManager.startUpdatingLocation()
            
            // Is this redundant?
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: "location")
        }
        else if status == .denied
        {
            locationSearchBar.frame = CGRect(x: locationSearchBar.frame.origin.x, y: locationSearchBar.frame.origin.y, width: locationSearchBar.frame.width, height: 0)
            
            if refreshControl?.isRefreshing == true
            {
                refreshControl?.endRefreshing()
            }
            refreshControl = nil
            
            messageText = "Etto is not authorized to find your location. To change this, please go to Settings -> Privacy -> Location Services."
            
            self.tableView.reloadData()
            
            // Is this redundant?
            let defaults = UserDefaults.standard
            defaults.set(false, forKey: "location")
        }

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        // Not sure I can disregard old locations since distanceFilter is now set.
        /*
        // prevents use of a cached location (I think)
        let currentDateTime = Date()
        if let timestamp = manager.location?.timestamp
        {
            // not sure about this time interval
            if currentDateTime.timeIntervalSinceDate(timestamp) < 30
            {
                let locationCoordinates: CLLocationCoordinate2D = manager.location!.coordinate
                
                // Is this really the best way to do this?
                if shouldFindPlaces == true
                {
                    findNearbyPlaces(locationCoordinates)
                }
                
                shouldFindPlaces = false
            }
        }
        */
        
        if let locationCoordinates: CLLocationCoordinate2D = manager.location?.coordinate
        {
            // Is this really the best way to do this?
            if shouldFindPlaces == true
            {
                shouldFindPlaces = false
                
                if textSearchRequested == true && userTextQuery != nil
                {
                    textSearchRequested = false
                    
                    findNearbyPlacesWithSearchText(coordinates: locationCoordinates, searchText: userTextQuery!)
                }
                else
                {
                    findNearbyPlaces(coordinates: locationCoordinates)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error while updating location " + error.localizedDescription)
        
        // Alert? Probably not. This seems to fire too often.
    }
    
    func findNearbyPlaces(coordinates: CLLocationCoordinate2D)
    {
        nearbySearchInProgress = true
        
        let latitude: CLLocationDegrees = coordinates.latitude
        let longitude: CLLocationDegrees = coordinates.longitude
        
        /*
        let placesString: String = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=250&types=bar|restaurant|food|cafe|meal_delivery|meal_takeaway|night_club&sensor=true&key=AIzaSyAEd5i3LuMrBYG6-5JIted5X3CUlCFlULw"
        */
        
        let placesString: String = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=250&sensor=true&key=AIzaSyAEd5i3LuMrBYG6-5JIted5X3CUlCFlULw"
        
        let placesURL = URL(string: placesString)
        
        let session = URLSession.shared
        
        DispatchQueue.global(qos: .userInitiated).async
        {
            let task = session.dataTask(with: placesURL!, completionHandler:
            {
                (data: Data?, response: URLResponse?, error: Error?) -> Void in
                
                if error == nil
                {
                    do
                    {
                        if let jsonDict = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                        {
                            if let results = jsonDict["results"] as? [NSDictionary]
                            {
                                self.nearbyPlaces.removeAll()
                                
                                for result in results
                                {
                                    let place = Place()
                                    
                                    if let name = result["name"] as? String
                                    {
                                        place.name = name
                                    }
                                    
                                    if let id = result["place_id"] as? String
                                    {
                                        place.id = id
                                    }
                                    
                                    if let address = result["vicinity"] as? String
                                    {
                                        place.address = address
                                    }
                                    
                                    if let geometry = result["geometry"] as? NSDictionary
                                    {
                                        if let location = geometry["location"] as? NSDictionary
                                        {
                                            if let lat = location["lat"] as? String
                                            {
                                                if let lng = location["lng"] as? String
                                                {
                                                    place.latitude = lat
                                                    place.longitude = lng
                                                }
                                            }
                                        }
                                    }
                                    
                                    self.nearbyPlaces.append(place)
                                }
                                
                                if self.nearbyPlaces.count == 0
                                {
                                    self.messageText = "Sorry. We weren't able to find any nearby places."
                                }
                                else
                                {
                                    self.validateNearbyPlaces()
                                }
                                
                                DispatchQueue.main.async
                                {
                                    self.nearbySearchCompletion(coordinates: coordinates)
                                }
                            }
                        }
                    }
                    catch let err as NSError
                    {
                        print("JSON error: \(err)")
                        
                        self.messageText = "Mistakes were made. Please try refreshing the page."
                        
                        DispatchQueue.main.async
                        {
                            self.nearbySearchCompletion(coordinates: coordinates)
                        }
                    }
                }
                else
                {
                    print("Google Places error: \(error)")
                    
                    self.messageText = "If we had to guess, we'd say you don't have internet access right now. Otherwise, we're blaming Google for this one. Please try refreshing the page."
                    
                    DispatchQueue.main.async
                    {
                        self.nearbySearchCompletion(coordinates: coordinates)
                    }
                }
            })
            
            task.resume()
        }
    }
    
    func nearbySearchCompletion(coordinates: CLLocationCoordinate2D)
    {
        nearbySearchInProgress = false
        
        if textSearchRequested == true && userTextQuery != nil
        {
            textSearchRequested = false
            
            findNearbyPlacesWithSearchText(coordinates: coordinates, searchText: userTextQuery!)
        }
        else
        {
            tableView.reloadData()
            
            refreshControl?.endRefreshing()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        tableView.endEditing(true)
        
        var searchText = searchBar.text!
        
        searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !searchText.isEmpty
        {
            searchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            
            userTextQuery = searchText
            
            clearSelection()
            
            if let locationCoordinates: CLLocationCoordinate2D = locationManager.location?.coordinate
            {
                if nearbySearchInProgress == false
                {
                    // Pretty sure refreshing would always be false here.
                    // Actually, nevermind. Can start a second text search while the first one is still going.
                    if refreshControl?.isRefreshing == false
                    {
                        self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
                        
                        refreshControl?.beginRefreshing()
                    }
                    
                    findNearbyPlacesWithSearchText(coordinates: locationCoordinates, searchText: userTextQuery!)
                }
                else
                {
                    // No message. The text search will be run in a sec after the nearby search finishes.
                    
                    textSearchRequested = true
                }
            }
            else
            {
                messageText = "Hold on a sec. We haven't found your location yet. Don't worry though. We'll run your search once we have it."
                
                self.tableView.reloadData()
                
                textSearchRequested = true
            }
        }
        else
        {
            // Error message? The search must contain at least one (non-whitespace) character.
            // Don't want to show this in place of nearby results though.
            // Just do an alert?
        }
    }
    
    func findNearbyPlacesWithSearchText(coordinates: CLLocationCoordinate2D, searchText: String)
    {
        let latitude: CLLocationDegrees = coordinates.latitude
        let longitude: CLLocationDegrees = coordinates.longitude
        
        /*
        let placesString: String = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=250&types=bar|restaurant|food|cafe|meal_delivery|meal_takeaway|night_club&sensor=true&key=AIzaSyAEd5i3LuMrBYG6-5JIted5X3CUlCFlULw"
        */
        
        // let placesString: String = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&keyword=\(searchText)&radius=250&sensor=true&key=AIzaSyAEd5i3LuMrBYG6-5JIted5X3CUlCFlULw"
        var placesString: String = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&keyword="
        placesString += searchText
        placesString += "&radius=250&sensor=true&key=AIzaSyAEd5i3LuMrBYG6-5JIted5X3CUlCFlULw"
        
        let placesURL = URL(string: placesString)
        
        let session = URLSession.shared
        
        DispatchQueue.global(qos: .userInitiated).async
        {
            let task = session.dataTask(with: placesURL!, completionHandler:
            {
                (data: Data?, response: URLResponse?, error: Error?) -> Void in
                
                if error == nil
                {
                    do
                    {
                        if let jsonDict = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                        {
                            if let results = jsonDict["results"] as? [NSDictionary]
                            {
                                self.nearbyPlaces.removeAll()
                                
                                for result in results
                                {
                                    let place = Place()
                                    
                                    if let name = result["name"] as? String
                                    {
                                        place.name = name
                                    }
                                    
                                    if let id = result["place_id"] as? String
                                    {
                                        place.id = id
                                    }
                                    
                                    if let address = result["vicinity"] as? String
                                    {
                                        place.address = address
                                    }
                                    
                                    if let geometry = result["geometry"] as? NSDictionary
                                    {
                                        if let location = geometry["location"] as? NSDictionary
                                        {
                                            if let lat = location["lat"] as? String
                                            {
                                                if let lng = location["lng"] as? String
                                                {
                                                    place.latitude = lat
                                                    place.longitude = lng
                                                }
                                            }
                                        }
                                    }
                                    
                                    self.nearbyPlaces.append(place)
                                }
                                
                                if self.nearbyPlaces.count == 0
                                {
                                    self.messageText = "Sorry. We weren't able to find any results that match your search."
                                }
                                else
                                {
                                    self.validateNearbyPlaces()
                                }
                                
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
                    print("Google Places error: \(error)")
                    
                    self.messageText = "If we had to guess, we'd say you don't have internet access right now. Otherwise, we're blaming Google for this one. Please try again."
                    
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
    
    func clearSelection()
    {
        if selectedSection == 1 && selectedRow != nil
        {
            if let cell = tableView.cellForRow(at: IndexPath(row: selectedRow!, section: selectedSection!))
            {
                cell.accessoryType = .none
            }
            
            selectedSection = nil
            selectedRow = nil
        }
    }
    
    func validateNearbyPlaces()
    {
        var invalidPlaceIndices = [Int]()
        
        var i = 0
        let n = nearbyPlaces.count
        while i < n
        {
            if nearbyPlaces[i].name == nil || nearbyPlaces[i].id == nil
            {
                invalidPlaceIndices.append(i)
            }
            
            i += 1
        }
        
        for index in invalidPlaceIndices
        {
            nearbyPlaces.remove(at: index)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            let defaults = UserDefaults.standard
            // if let mostRecentLocation = defaults.objectForKey("mostRecentLocation") as? NSData
            if defaults.object(forKey: "mostRecentLocation") as? Data != nil
            {
                if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways
                {
                    return 1
                }
            }
            
            return 0
        }
        else
        {
            if nearbyPlaces.count == 0
            {
                return 1
            }
            else
            {
                return nearbyPlaces.count
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if indexPath.section == 0
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
            
            let defaults = UserDefaults.standard
            
            if let mostRecentLocation = defaults.object(forKey: "mostRecentLocation") as? Data
            {
                let location = NSKeyedUnarchiver.unarchiveObject(with: mostRecentLocation) as! MostRecentLocation
                
                cell.textLabel?.text = location.name
                
                if let address = location.address
                {
                    cell.detailTextLabel?.text = address
                }
                
                if (indexPath.section == selectedSection && indexPath.row == selectedRow)
                {
                    cell.accessoryType = .checkmark
                }
                else
                {
                    cell.accessoryType = .none
                }
            }
            
            tableView.separatorStyle = .singleLine
            
            return cell
        }
        else
        {
            if nearbyPlaces.count > 0
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
                
                let place = nearbyPlaces[indexPath.row]
                cell.textLabel?.text = place.name
                cell.detailTextLabel?.text = place.address
                
                if (indexPath.section == selectedSection && indexPath.row == selectedRow)
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
                
                // Does this affect other cells? Yep.
                // Only problematic when there's a recent location but no nearby locations.
                tableView.separatorStyle = .none
                
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // clears old checkmark
        if selectedSection != nil && selectedRow != nil
        {
            let cell = tableView.cellForRow(at: IndexPath(row: selectedRow!, section: selectedSection!))
            cell?.accessoryType = .none
        }
        
        selectedRow = indexPath.row
        selectedSection = indexPath.section
        
        // sets new checkmark
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if section == 0
        {
            let defaults = UserDefaults.standard
            if defaults.object(forKey: "mostRecentLocation") as? Data != nil
            {
                if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways
                {
                    return "MOST RECENT"
                }
            }
        }
        else
        {
            if nearbyPlaces.count > 0
            {
                return "NEARBY"
            }
        }
        
        return String()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if section == 0
        {
            let defaults = UserDefaults.standard
            if defaults.object(forKey: "mostRecentLocation") as? Data != nil
            {
                if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways
                {
                    return 40
                }
            }
            
            return CGFloat.leastNormalMagnitude
        }
        else
        {
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        if section == 0
        {
            let defaults = UserDefaults.standard
            if defaults.object(forKey: "mostRecentLocation") as? Data != nil
            {
                if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways
                {
                    return UITableViewAutomaticDimension
                }
            }
            
            return CGFloat.leastNormalMagnitude
        }
        else
        {
            return UITableViewAutomaticDimension
        }
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
        if sendingView == "AddBeer"
        {
            performSegue(withIdentifier: "CancelToAddBeer", sender: self)
        }
        else if sendingView == "AddWine"
        {
            performSegue(withIdentifier: "CancelToAddWine", sender: self)
        }
        else if sendingView == "AddCocktail"
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
        if selectedSection != nil && selectedRow != nil
        {
            if sendingView == "AddBeer"
            {
                performSegue(withIdentifier: "SaveLocationToAddBeer", sender: self)
            }
            else if sendingView == "AddWine"
            {
                performSegue(withIdentifier: "SaveLocationToAddWine", sender: self)
            }
            else if sendingView == "AddCocktail"
            {
                performSegue(withIdentifier: "SaveLocationToAddCocktail", sender: self)
            }
            else if sendingView == "AddShot"
            {
                performSegue(withIdentifier: "SaveLocationToAddShot", sender: self)
            }
        }
        else
        {
            let alertController = UIAlertController(title: "Error", message: "You must select a location. Otherwise, please hit cancel.", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        tableView.endEditing(true)
        
        if segue.identifier == "SaveLocationToAddBeer" || segue.identifier == "SaveLocationToAddWine" || segue.identifier == "SaveLocationToAddCocktail" || segue.identifier == "SaveLocationToAddShot"
        {
            if selectedSection == 0
            {
                let defaults = UserDefaults.standard
                
                if let mostRecentLocation = defaults.object(forKey: "mostRecentLocation") as? Data
                {
                    let location = NSKeyedUnarchiver.unarchiveObject(with: mostRecentLocation) as! MostRecentLocation
                    
                    selectedLocationName = location.name
                    selectedLocationID = location.id
                    
                    if let address = location.address
                    {
                        selectedLocationAddress = address
                    }
                    
                    if let latitude = location.latitude
                    {
                        if let longitude = location.longitude
                        {
                            selectedLocationLatitude = latitude
                            selectedLocationLongitude = longitude
                        }
                    }
                }
            }
            else
            {
                // the existence of selectedRow should be guaranteed by saveAction()
                let place = nearbyPlaces[selectedRow!]
                
                // the existence of .name and .place_id should be guaranteed by validateNearbyPlaces()
                selectedLocationName = place.name!
                selectedLocationID = place.id!
                
                mostRecentLocation = MostRecentLocation(name: selectedLocationName, id: selectedLocationID)
                
                if let address = place.address
                {
                    selectedLocationAddress = address
                    
                    mostRecentLocation.address = selectedLocationAddress
                }
                
                if let latitude = place.latitude
                {
                    if let longitude = place.longitude
                    {
                        selectedLocationLatitude = latitude
                        selectedLocationLongitude = longitude
                        
                        mostRecentLocation.latitude = selectedLocationLatitude
                        mostRecentLocation.longitude = selectedLocationLongitude
                    }
                }
                
                let defaults = UserDefaults.standard
                defaults.set(NSKeyedArchiver.archivedData(withRootObject: mostRecentLocation), forKey: "mostRecentLocation")
            }
        }
    }

}
