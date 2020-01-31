//
//  AddUsersTableViewController.swift
//  Cheers
//
//  Created by John DeRusso on 12/24/15.
//  Copyright © 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData

class AddUsersTableViewController: UITableViewController, UISearchBarDelegate {

    var users = [PFUser]()
    var messageText: String?
    var hasChanges = false
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    // for the activity indicator
    let activityIndicator = UIActivityIndicatorView()
    let overlay = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        searchBar.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AddUsersTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        refreshControl?.addTarget(self, action: #selector(AddUsersTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
        
        refreshControl?.beginRefreshing()
        
        fetchUsers()
        
        // anything else?
    }
    
    func hideKeyboard()
    {
        tableView.endEditing(true)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl)
    {
        // reperform a search if one was performed?
        
        fetchUsers()
    }
    
    func fetchUsers()
    {
        
        
        
        // set messageText to nil?
        
        
        
        // why is query() optional?
        let query = PFUser.query()!
        query.whereKey("sharing", equalTo: "Public")
        query.order(byDescending: "followerCount")
        
        // Not sure what an appropriate limit is. 25? 50?
        query.limit = 25
        
        // off for testing (so I can follow myself)
        if let currentUserID = PFUser.current()?.objectId
        {
            // query.whereKey("objectId", notEqualTo: currentUserID)
        }
            
        DispatchQueue.global(qos: .userInitiated).async
        {
            do
            {
                if let results = try query.findObjects() as? [PFUser]
                {
                    self.users = results
                    
                    if self.users.count == 0
                    {
                        self.messageText = "\nSorry, it looks like there isn't anyone to follow.\n\n=("
                    }
                }
                else
                {
                    DispatchQueue.main.async
                    {
                        // Not sure how I would actually reach this code.
                        
                        // Set message text.
                    }
                }
            }
            catch let error as NSError
            {
                DispatchQueue.main.async
                {
                    // error? error.description?
                    print(error)
                    
                    // Set message text.
                }
            }
            
            DispatchQueue.main.async
            {
                self.tableView.reloadData()
                
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    @IBAction func followButtonTouchUpInside(_ sender: UIButton)
    {
        if let currentUser = PFUser.current()
        {
            if let cell = sender.superview?.superview as? FPUserTableViewCell
            {
                showActivityIndicator(shouldShow: true)
                
                // indicates that the feed should be refreshed after the segue
                hasChanges = true
                
                // for the cloud code
                var addOrRemove: String
                
                if var followedUsers = currentUser["following"] as? [String]
                {
                    if let index = followedUsers.index(of: cell.user.objectId!)
                    {
                        followedUsers.remove(at: index)
                        
                        addOrRemove = "remove"
                    }
                    else
                    {
                        followedUsers.append(cell.user.objectId!)
                        
                        addOrRemove = "add"
                    }
                    
                    // pretty sure I need this
                    currentUser["following"] = followedUsers
                }
                else
                {
                    // this fires when the user hasn't followed anyone yet, right?
                    
                    var followedUsers = [String]()
                    followedUsers.append(cell.user.objectId!)
                    
                    addOrRemove = "add"
                    
                    currentUser["following"] = followedUsers
                }
    
                DispatchQueue.global(qos: .userInitiated).async
                {
                    do
                    {
                        try currentUser.save()
                            
                        var params = ["userID": cell.user.objectId!]
                        // params["followerID"] = currentUser.objectId!
                        params["addOrRemove"] = addOrRemove
                            
                        do
                        {
                            try PFCloud.callFunction("updateFollowers", withParameters: params)
                        }
                        catch let error as NSError
                        {
                            print("Error in Cloud Code function updateFollowers: \(error)")
                                
                            // in practice, I don't think this code will be reached very often
                            // either I'd have to mess up the cloud code or the user would have to lose internet access in between the functions
                                
                            // save some data locally
                            // on the main page, try to run updateFollowers each time as necessary until it's successful
                            // MainPageViewController
                            self.saveForLater(currentUserID: currentUser.objectId!, userToUpdateID: cell.user.objectId!, addOrRemove: addOrRemove)
                        }
                            
                        DispatchQueue.main.async
                        {
                            if let index = self.tableView.indexPath(for: cell)
                            {
                                // this is safe since the cell.user is not being saved
                                // the actual updating is handled in cloud code
                                let user = self.users[index.row]
                                if let followerCount = user["followerCount"] as? Int
                                {
                                    if addOrRemove == "add"
                                    {
                                        user["followerCount"] = followerCount + 1
                                    }
                                    else
                                    {
                                        user["followerCount"] = followerCount - 1
                                    }
                                }
                                else
                                {
                                    // is this code called when followerCount hasn't yet been set?
                                    
                                    if addOrRemove == "add"
                                    {
                                        user["followerCount"] = 1
                                    }
                                }
                                        
                                self.showActivityIndicator(shouldShow: false)
                                
                                self.tableView.reloadRows(at: [index], with: UITableViewRowAnimation.none)
                            }
                        }
                    }
                    catch let error as NSError
                    {
                        // error? error.description?
                        print(error)
                            
                        DispatchQueue.main.async
                        {
                            self.showActivityIndicator(shouldShow: false)
                                    
                            // Alert.
                        }
                    }
                }
            }
        }
        else
        {
            // Alert.
            // "You must be logged in to follow another user."
            // You don't need to be logged in to reach this page.
        }
    }
    
    func saveForLater(currentUserID: String, userToUpdateID: String, addOrRemove: String)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entity(forEntityName: "UpdateFollowers", in: managedContext)
        let updateFollowers = NSManagedObject(entity: entity!, insertInto:managedContext)
        
        updateFollowers.setValue(currentUserID, forKey: "currentUserID")
        updateFollowers.setValue(userToUpdateID, forKey: "userToUpdateID")
        updateFollowers.setValue(addOrRemove, forKey: "addOrRemove")
        
        do
        {
            try managedContext.save()
        }
        catch let error
        {
            print("Could not save \(error)")
            
            // if it fails here too, fuck it
            // I'll just have to run a check somewhere as a backup
            // when the current user views their followers, check each follower to make sure that follower is actually following the user
            // also check for followers who are not listed
            // can do the same on the following page
            // (all in the background)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        tableView.endEditing(true)
        
        if searchBar.text != nil
        {
            let searchText = searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !searchText.isEmpty
            {
                tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
                
                refreshControl?.beginRefreshing()
                
                searchUsers(searchText: searchText)
                
            }
            else
            {
                // Alert.
                print("search text is empty")
            }
        }
        else
        {
            // empty?
            // test this.
            
            // Alert.
            print("search text is nil")
        }
    }
    
    func searchUsers(searchText: String)
    {
        
        
        
        // set messageText to nil?
        
        
        
        // why is query() optional?
        let query = PFUser.query()!
        query.whereKey("name", contains: searchText)
        query.whereKey("sharing", equalTo: "Public")
        // Maybe?
        // query.orderByDescending("followerCount")

        
        // Not sure what an appropriate limit is. 25? 50?
        query.limit = 25
        
        // off for testing (so I get search results)
        if let currentUserID = PFUser.current()?.objectId
        {
            // query.whereKey("objectId", notEqualTo: currentUserID)
        }
            
        DispatchQueue.global(qos: .userInitiated).async
        {
            do
            {
                if let results = try query.findObjects() as? [PFUser]
                {
                    self.users = results
                        
                    if self.users.count == 0
                    {
                        // self.messageText = "\nSorry, it looks like there isn't anyone to follow.\n\n=("
                        self.messageText = "\nSorry, your search didn't return any results.\n\n=("
                        
                        // explain that the search is sensitive? Yeah, I think so.
                        // capitalization, exact text
                    }
                }
                else
                {
                    DispatchQueue.main.async
                    {
                        // Not sure how I would actually reach this code.
                                
                        // Set message text.
                    }
                }
            }
            catch let error as NSError
            {
                DispatchQueue.main.async
                {
                    // error? error.description?
                    print(error)
                            
                    // Set message text.
                }
            }
                
            DispatchQueue.main.async
            {
                self.tableView.reloadData()
                        
                self.refreshControl?.endRefreshing()
            }
        }
    }

    func showActivityIndicator(shouldShow: Bool)
    {
        if shouldShow == true
        {
            overlay.frame = view.frame
            overlay.center = view.center
            overlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
            
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
            activityIndicator.color = UIColor(red: 56/255.0, green: 207/255.0, blue: 166/255.0, alpha: 1)
            
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
            
            navigationController?.view.addSubview(overlay)
        }
        else
        {
            overlay.removeFromSuperview()
            
            activityIndicator.stopAnimating()
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
        if users.count == 0
        {
            return 1
        }
        else
        {
            return users.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if users.count == 0
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath)
            
            // check for nil?
            cell.textLabel?.text = messageText
            
            tableView.separatorStyle = .none
            
            return cell
        }
        else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! FPUserTableViewCell
            
            let user = users[indexPath.row]
            cell.user = user
            
            if let photo = user["photo"] as? String
            {
                let url = URL(string: photo)
                    
                DispatchQueue.global(qos: .utility).async
                {
                    do
                    {
                        let data = try Data(contentsOf: url!)
                        
                        DispatchQueue.main.async
                        {
                            cell.userPhotoImageView.alpha = 0
                            cell.userPhotoImageView.image = UIImage(data: data)
                            
                            UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations:
                            {
                                cell.userPhotoImageView.alpha = 1
                            },
                            completion: nil)
                        }
                    }
                    catch let error
                    {
                        print("error in cellForRowAt: \(error)")
                        
                        // update photo?
                        // what if the problem is that there's no internet access?
                    }
                }
            }
            else
            {
                // update photo?
            }
            
            if let name = user["name"] as? String
            {
                cell.userNameLabel.text = name
            }
            // else?
            
            if let description = user["description"] as? String
            {
                cell.userDescriptionLabel.text = description
            }
            // else?
            
            if let followerCount = user["followerCount"] as? Int
            {
                if followerCount != 1
                {
                    cell.userFollowerCountLabel.text = "\(followerCount) followers"
                }
                else
                {
                    cell.userFollowerCountLabel.text = "\(followerCount) follower"
                }
            }
            else
            {
                // or maybe just nothing?
                cell.userFollowerCountLabel.text = "0 followers"
            }
            
            if let currentUser = PFUser.current()
            {
                if let followedUsers = currentUser["following"] as? [String]
                {
                    if followedUsers.contains(user.objectId!)
                    {
                        cell.followButton.setImage(UIImage(named: "Checked User Filled-100"), for: UIControlState.normal)
                        
                        // set some sort of variable?
                        // or I could just run this check again later?
                    }
                    else
                    {
                        // leave button?
                        // the default state is the empty image
                    }
                }
                else
                {
                    // this fires when the user hasn't followed anyone yet, right?
                    
                    // leave button?
                    // the default state is the empty image
                }
            }
            // else, error?
            // don't worry about it here and just throw an error when the user tries to follow/unfollow someone?
            
            // add the separators?
            tableView.separatorStyle = .singleLine
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // toggle following on and off
        // with an activity indicator
        
        // or maybe I should only use a button for that
        // show some details when the user is clicked instead?
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
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
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "DoneToFeed"
        {
            if let feedTableViewController = segue.destination as? FriendsTableViewController
            {
                // if there was a change in who the user is following, set shouldRefresh to true
                // probably just going to set a variable to false by default and true any time a user presses the follow user button
                if hasChanges == true
                {
                    feedTableViewController.shouldRefresh = true
                }
                // else, do nothing
                // shouldRefresh is set to false by default
            }
        }
    }

}
