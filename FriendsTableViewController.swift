//
//  FriendsTableViewController.swift
//  Cheers
//
//  Created by Air on 6/1/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import Parse
import Firebase

class FriendsTableViewController: UITableViewController {

    // var drinkList = [ParseDrinkEntry]()
    var drinkList = [FirebaseDrink]()
    
    var cardViewWidth: CGFloat!
    
    var messageText = String()
    var messageTextArray = [String]()
    
    var friendsWithUpdatedPhotos = [PFUser]()
    var usersWithUpdatedNames = [String]()
    var usersWithUpdatedPhotos = [String]()
    
    var shouldRefresh = false
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var previousSelectedSegmentIndex = 0
    var allDrinkList = [ParseDrinkEntry]()
    var friendsDrinkList = [ParseDrinkEntry]()
    var followingDrinkList = [ParseDrinkEntry]()
    
    // let firebaseRootRef = Firebase(url: "https://glowing-inferno-7505.firebaseio.com")
    let firebaseRootRef = FIRDatabase.database().reference()
    var facebookFriendIDs = [String]()
    // var friendFeedDrinkIDs = [String]()
    var friendFeedDrinks = [FirebaseDrink]()
    // var followingFeedDrinkIDs = [String]()
    var followeeFeedDrinks = [FirebaseDrink]()
    // var firebaseFriendIDs = [String]()
    var firebaseFriends = [FirebaseUser]()
    // var followingIDs = [String]()
    var followees = [FirebaseUser]()
    var usableFriendFeedDrinks = [FirebaseDrink]()
    var usableFolloweeFeedDrinks = [FirebaseDrink]()
    var allUsableDrinks = [FirebaseDrink]()
    var lastBatchFetchedAndChecked: Int?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // self.view.backgroundColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
        self.view.backgroundColor = UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(FriendsTableViewController.swipedLeft))
        leftSwipeGesture.direction = .left
        self.view.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(FriendsTableViewController.swipedRight))
        rightSwipeGesture.direction = .right
        self.view.addGestureRecognizer(rightSwipeGesture)
        
        self.tabBarController?.view.backgroundColor = UIColor.white
        
        self.refreshControl?.addTarget(self, action: #selector(FriendsTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        // tableView.estimatedRowHeight = 154
        // tableView.rowHeight = UITableViewAutomaticDimension
        
        // ensures correct shadow width for the cell cardViews
        // the value of 30 is based on the current leading and trailing constraints of 15
        cardViewWidth = UIScreen.main.bounds.width - 30
        
        // no longer used
        /*
        if PFUser.currentUser() != nil
        {
            refreshControl?.beginRefreshing()
            
            // fetchDrinks()
            fetchAllDrinks()
        }
        else
        {
            // Suggest the user create an account/log in?
            // Set messageText? (and reload the tableView?)
        }
        */
        
        // should I add a timer?
        if let uid = FIRAuth.auth()?.currentUser?.uid
        {
            refreshControl?.beginRefreshing()
            
            fetchFacebookFriends()
            {
                (friendsFetched: Bool) in
                
                // just pass the variable in to fetchFirebaseData? (along with the uid)
                // I can still get the drinks of the people the user is following at least
                // some sort of message or alert? that may already be taken care of in cellForRowAtIndexPath
                
                self.fetchFirebaseData(uid: uid, friendsFetched: friendsFetched)
                {
                    (error: String?) in
                    
                    self.fillMessageTextArray(error: error, friendsFetched: friendsFetched)
                    
                    self.tableView.reloadData()
                    
                    if self.refreshControl?.isRefreshing == true
                    {
                        self.refreshControl?.endRefreshing()
                    }
                    
                    if friendsFetched == false
                    {
                        // Alert
                        // "Unfortunately, we couldn’t retrieve the data we needed from Facebook so we won’t be able to show you any of your friends’ drinks. However, we did still check for drinks for the people you follow."
                    }
                    
                    // observe childAdded for each feed? (depending on friendsFetched)
                }
            }
        }
        else
        {
            messageTextArray.removeAll()
            
            // all segment
            messageTextArray.append("\nTo see drinks from your friends and the people you follow, please log in by going to More -> Social.")
            
            // friends segment
            messageTextArray.append("\nTo see drinks from your friends and the people you follow, please log in by going to More -> Social.")
            
            // following segment
            messageTextArray.append("\nTo see drinks from your friends and the people you follow, please log in by going to More -> Social.")
            
            // no need to reload here
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        // If it's been a while since the last refresh, refresh automatically.
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
    
    func handleRefresh(refreshControl: UIRefreshControl)
    {
        // no longer used
        /*
        if PFUser.currentUser() != nil
        {
            // beginRefreshing is called when the user pulls down
            // endRefreshing is called within fetchDrinks
            // fetchDrinks()
            fetchAllDrinks()
        }
        else
        {
            refreshControl.endRefreshing()
            
            // Suggest the user create an account/log in?
            // Set messageText? (and reload the tableView?)
        }
        */
        
        // the following should be consistent with viewDidLoad
        // should I add a timer?
        if let uid = FIRAuth.auth()?.currentUser?.uid
        {
            // no need to call refreshControl.beginRefreshing
            // the refreshControl is already refreshing
            
            fetchFacebookFriends()
            {
                (friendsFetched: Bool) in
                
                // just pass the variable in to fetchFirebaseData? (along with the uid)
                // I can still get the drinks of the people the user is following at least
                // some sort of message or alert? that may already be taken care of in cellForRowAtIndexPath
                    
                self.fetchFirebaseData(uid: uid, friendsFetched: friendsFetched)
                {
                    (error: String?) in
                    
                    self.fillMessageTextArray(error: error, friendsFetched: friendsFetched)
                    
                    self.tableView.reloadData()
                    
                    if refreshControl.isRefreshing == true
                    {
                        refreshControl.endRefreshing()
                    }
                    
                    if friendsFetched == false
                    {
                        // Alert
                        // "Unfortunately, we couldn’t retrieve the data we needed from Facebook so we won’t be able to show you any of your friends’ drinks. However, we did still check for drinks for the people you follow."
                    }
                    
                    // observe childAdded for each feed? (depending on friendsFetched)
                    // unless this was already taken care of in viewDidLoad
                    // set a variable on success and check it here?
                }
            }
        }
        else
        {
            messageTextArray.removeAll()
            
            // all segment
            messageTextArray.append("\nTo see drinks from your friends and the people you follow, please log in by going to More -> Social.")
            
            // friends segment
            messageTextArray.append("\nTo see drinks from your friends and the people you follow, please log in by going to More -> Social.")
            
            // following segment
            messageTextArray.append("\nTo see drinks from your friends and the people you follow, please log in by going to More -> Social.")
            
            tableView.reloadData()
            
            if refreshControl.isRefreshing == true
            {
                refreshControl.endRefreshing()
            }
        }
    }
    
    func fillMessageTextArray(error: String?, friendsFetched: Bool)
    {
        messageTextArray.removeAll()
        
        if error != nil
        {
            if error == "nullUserSnapshot"
            {
                // all segment
                messageTextArray.append("\nHonestly, we're not sure how this happened. Clearly though, something has gone terribly, terribly wrong.")
                
                // friends segment
                messageTextArray.append("\nHonestly, we're not sure how this happened. Clearly though, something has gone terribly, terribly wrong.")
                
                // following segment
                messageTextArray.append("\nHonestly, we're not sure how this happened. Clearly though, something has gone terribly, terribly wrong.")
            }
            // else?
        }
        else if friendsFetched == false
        {
            // These messages will only be visible when drinkList.count == 0.
            
            // all segment
            if followees.count == 0
            {
                messageTextArray.append("\nSorry, it looks like there are no drinks to display. You may want to consider following some users. To get started, hit the + button in the upper right-hand corner.")
            }
            else
            {
                messageTextArray.append("\nSorry, it looks like there are no drinks to display. You may want to consider following some additional users. To get started, hit the + button in the upper right-hand corner.")
            }
            
            // friends segment
            messageTextArray.append("\nSorry, it looks like there are no drinks to display.")
            
            // following segment
            if followees.count == 0
            {
                messageTextArray.append("\nSorry, it looks like there are no drinks to display. You may want to consider following some users. To get started, hit the + button in the upper right-hand corner.")
            }
            else
            {
                messageTextArray.append("\nSorry, it looks like there are no drinks to display. You may want to consider following some additional users. To get started, hit the + button in the upper right-hand corner.")
            }
        }
        else
        {
            // These messages will only be visible when drinkList.count == 0.
            
            // all segment
            if followees.count == 0
            {
                if firebaseFriends.count == 0
                {
                    messageTextArray.append("\nSorry, it looks like there are no drinks to display. Feel free to encourage your friends to try Etto. Also, you may want to consider following some users. To get started, hit the + button in the upper right-hand corner.")
                }
                else
                {
                    messageTextArray.append("\nSorry, it looks like there are no drinks to display. Feel free to encourage more of your friends to try Etto. Also, you may want to consider following some users. To get started, hit the + button in the upper right-hand corner.")
                }
            }
            else
            {
                if firebaseFriends.count == 0
                {
                    messageTextArray.append("\nSorry, it looks like there are no drinks to display. Feel free to encourage your friends to try Etto. Also, you may want to consider following some additional users. To get started, hit the + button in the upper right-hand corner.")
                }
                else
                {
                    messageTextArray.append("\nSorry, it looks like there are no drinks to display. Feel free to encourage more of your friends to try Etto. Also, you may want to consider following some additional users. To get started, hit the + button in the upper right-hand corner.")
                }
            }
            
            // friends segment
            if firebaseFriends.count == 0
            {
                messageTextArray.append("\nSorry, it looks like there are no drinks to display. Feel free to encourage your friends to try Etto.")
            }
            else
            {
                messageTextArray.append("\nSorry, it looks like there are no drinks to display. Feel free to encourage more of your friends to try Etto.")
            }
            
            // following segment
            if followees.count == 0
            {
                messageTextArray.append("\nSorry, it looks like there are no drinks to display. You may want to consider following some users. To get started, hit the + button in the upper right-hand corner.")
            }
            else
            {
                messageTextArray.append("\nSorry, it looks like there are no drinks to display. You may want to consider following some additional users. To get started, hit the + button in the upper right-hand corner.")
            }
        }
    }
    
    // no longer used
    /*
    func fetchAllDrinks()
    {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))
        {
            PFCloud.callFunctionInBackground("getFriendsDrinks", withParameters: ["token" : FBSDKAccessToken.currentAccessToken().tokenString])
            {
                (response: AnyObject?, error: NSError?) -> Void in
     
                if error == nil
                {
                    if let drinks = response as? [ParseDrinkEntry]
                    {
                        // Set the name and photo.
                        for drink in drinks
                        {
                            if let name = drink.parseUser.valueForKey("name") as? String
                            {
                                drink.friendName = name
                            }
                            if let photo = drink.parseUser.valueForKey("photo") as? String
                            {
                                drink.friendPhoto = photo
                            }
                        }
                                
                        dispatch_async(dispatch_get_main_queue())
                        {
                            self.friendsDrinkList = drinks
                            self.allDrinkList = drinks
                                        
                            if self.friendsDrinkList.count == 0
                            {
                                // or, more so, there are no shared drinks?
                                self.messageText = "\nSorry, it looks like you don't have any friends.\n\n=("
                            }
                                        
                            // self.tableView.reloadData()
                            
                            // self.refreshControl?.endRefreshing()
                            
                            self.fetchFollowingDrinks()
                        }
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue())
                        {
                            // set messageText
                                        
                            // self.tableView.reloadData()
                                        
                            // self.refreshControl?.endRefreshing()
                            
                            // send error forward
                            self.fetchFollowingDrinks()
                        }
                    }
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue())
                    {
                        self.messageText = "\nSorry, we couldn't fetch any drinks.\n\n(We tried really hard!)"
                                    
                        // self.tableView.reloadData()
                                    
                        // self.refreshControl?.endRefreshing()
                                    
                        print(error?.description)
                        
                        // send error forward
                        self.fetchFollowingDrinks()
                    }
                }
            }
        }
    }
    */
    
    // no longer used
    /*
    func fetchFriendsDrinks()
    {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))
        {
            PFCloud.callFunctionInBackground("getFriendsDrinks", withParameters: ["token" : FBSDKAccessToken.currentAccessToken().tokenString])
            {
                (response: AnyObject?, error: NSError?) -> Void in
                        
                if error == nil
                {
                    if let drinks = response as? [ParseDrinkEntry]
                    {
                        // Set the name and photo.
                        for drink in drinks
                        {
                            if let name = drink.parseUser.valueForKey("name") as? String
                            {
                                drink.friendName = name
                            }
                            if let photo = drink.parseUser.valueForKey("photo") as? String
                            {
                                drink.friendPhoto = photo
                            }
                        }
                                
                        dispatch_async(dispatch_get_main_queue())
                        {
                            self.friendsDrinkList = drinks
                            self.allDrinkList = drinks
                            
                            if self.friendsDrinkList.count == 0
                            {
                                // or, more so, there are no shared drinks?
                                self.messageText = "\nSorry, it looks like you don't have any friends.\n\n=("
                            }
                            
                            self.tableView.reloadData()
                            
                            // now handled in viewDidLoad
                            /*
                            // Makes sure cell shadows are the right size.
                            self.tableView.setNeedsLayout()
                            self.tableView.layoutIfNeeded()
                            
                            // Get and set the "correct" cardView width.
                            let firstCellIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                            if let firstCell = self.tableView.cellForRowAtIndexPath(firstCellIndexPath) as? FeedBeerWineTableViewCell
                            {
                                self.cardViewWidth = firstCell.cardView.frame.width
                            }
                            else if let firstCell = self.tableView.cellForRowAtIndexPath(firstCellIndexPath) as? FeedCocktailShotTableViewCell
                            {
                                self.cardViewWidth = firstCell.cardView.frame.width
                            }
                            */
                                        
                            self.refreshControl?.endRefreshing()
                        }
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue())
                        {
                            // set messageText
                        
                            self.tableView.reloadData()
                        
                            self.refreshControl?.endRefreshing()
                        }
                    }
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue())
                    {
                        self.messageText = "\nSorry, we couldn't fetch any drinks.\n\n(We tried really hard!)"
                        
                        self.tableView.reloadData()
                        
                        self.refreshControl?.endRefreshing()
                        
                        print(error?.description)
                    }
                }
            }
        }
    }
    */
    
    // no longer used
    /*
    func fetchFollowingDrinks()
    {
        if let currentUser = PFUser.currentUser()
        {
            if let following = currentUser["following"] as? [String]
            {
                var users = [PFUser]()
                
                for userID in following
                {
                    // let user = PFUser(withoutDataWithObjectId: userID)
                    let user = PFUser(outDataWithObjectId: userID)
                    
                    users.append(user)
                }
                
                let query = ParseDrinkEntry.query()
                query?.whereKey("parseUser", containedIn: users)
                query?.includeKey("parseUser")
                query?.includeKey("ingredients")
                // use a higher limit and only show some?
                query?.limit = 25
                query?.orderByDescending("universalDateTime")
                
                query?.findObjectsInBackgroundWithBlock
                {
                    (objects: [PFObject]?, error: NSError?) -> Void in
                    
                    if error == nil
                    {
                        if let drinks = objects as? [ParseDrinkEntry]
                        {
                            for drink in drinks
                            {
                                if let name = drink.parseUser.valueForKey("name") as? String
                                {
                                    drink.friendName = name
                                }
                                if let photo = drink.parseUser.valueForKey("photo") as? String
                                {
                                    drink.friendPhoto = photo
                                }
                            }
                            
                            self.followingDrinkList = drinks
                            
                            // set messageText if drinks.count == 0?
                            
                            self.allDrinkList = self.friendsDrinkList + self.followingDrinkList
                            self.allDrinkList.sortInPlace({$0.universalDateTime.compare($1.universalDateTime) == NSComparisonResult.OrderedDescending})
                            // limit to 25? only load 25 at first?
                            
                            // all
                            if self.segmentedControl.selectedSegmentIndex == 0
                            {
                                self.drinkList = self.allDrinkList
                            }
                            // friends
                            else if self.segmentedControl.selectedSegmentIndex == 1
                            {
                                self.drinkList = self.friendsDrinkList
                            }
                            // following
                            else
                            {
                                self.drinkList = self.followingDrinkList
                            }
                            
                            self.tableView.reloadData()
                            
                            self.refreshControl?.endRefreshing()
                        }
                        else
                        {
                            // Alert? Set messageText?
                            
                            self.tableView.reloadData()
                            
                            self.refreshControl?.endRefreshing()
                        }
                    }
                    else
                    {
                        // Alert? Set messageText?
                        
                        self.tableView.reloadData()
                        
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
            else
            {
                // Alert? Set messageText?
                
                self.tableView.reloadData()
                
                self.refreshControl?.endRefreshing()
            }
        }
        else
        {
            // Alert? Set messageText?
            
            self.tableView.reloadData()
            
            self.refreshControl?.endRefreshing()
        }
    }
    */
    
    func fetchFacebookFriends(completion: @escaping (_ friendsFetched: Bool) -> Void)
    {
        DispatchQueue.main.async
        {
            let request: FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "/me/friends", parameters: nil, httpMethod: "GET")
            
            request.start(completionHandler:
            {
                (connection, result, error) -> Void in
                
                var friendsFetched = false
                
                if error == nil
                {
                    if let results = result as? NSDictionary
                    {
                        if let friends = results.object(forKey: "data") as? [NSDictionary]
                        {
                            for friend in friends
                            {
                                if var id = friend.object(forKey: "id") as? String
                                {
                                    // Firebase's uid is "service:serviceID"
                                    // so... "facebook:facebookID"
                                    id = "facebook:" + id
                                    
                                    self.facebookFriendIDs.append(id)
                                }
                            }
                            
                            friendsFetched = true
                        }
                    }
                }
                
                completion(friendsFetched)
            })
        }
    }
    
    func fetchFirebaseData(uid: String, friendsFetched: Bool, completion: @escaping (_ error: String?) -> Void)
    {
        // 10 seconds? Maybe longer?
        let timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(FriendsTableViewController.removeFirebaseObserver), userInfo: nil, repeats: false)
        
        firebaseRootRef.child("users/\(uid)").observeSingleEvent(of: .value, with:
        {
            snapshot in
            
            timer.invalidate()
            
            if snapshot.value is NSNull
            {
                // the error is handled in the calling function
                completion("nullUserSnapshot")
            }
            else
            {
                // Is there any issue passing dispatchGroup to a function?
                // If there is, use a global variable, I guess.
                let dispatchGroup = DispatchGroup()
                
                if friendsFetched == true
                {
                    let friendFeedSnapshot = snapshot.childSnapshot(forPath: "feeds/friends")
                    let friendFeedEnumerator = friendFeedSnapshot.children
                    
                    while let drink = friendFeedEnumerator.nextObject() as? FIRDataSnapshot
                    {
                        self.friendFeedDrinks.append(FirebaseDrink(id: drink.key))
                    }
                    
                    let friendsSnapshot = snapshot.childSnapshot(forPath: "friends")
                    let friendsEnumerator = friendsSnapshot.children
                    
                    while let friend = friendsEnumerator.nextObject() as? FIRDataSnapshot
                    {
                        self.firebaseFriends.append(FirebaseUser(id: friend.key))
                    }
                    
                    self.compareFriends(uid: uid)
                    
                    
                    
                    
                    
                    
                    // Testing!
                    self.firebaseFriends.append(FirebaseUser(id: uid))
                    
                    
                    
                    
                    
                    
                    // need the names, photos and sharing settings
                    // what happens if this takes too long?
                    if self.firebaseFriends.count > 0
                    {
                        self.fetchUserData(dispatchGroup: dispatchGroup, friendsOrFollowees: "friends")
                    }
                    
                    if self.friendFeedDrinks.count > 1000
                    {
                        self.trimFeed(uid: uid, friendsOrFollowees: "friends")
                    }
                    
                    // I'm hoping this provides chronological sorting (with the newest object at index 0).
                    // self.friendFeedDrinks.sortInPlace({$0.id.caseInsensitiveCompare($1.id) == NSComparisonResult.OrderedDescending})
                    self.friendFeedDrinks.sort(by: {$0.id.compare($1.id) == ComparisonResult.orderedDescending})
                }
                
                let followeeFeedSnapshot = snapshot.childSnapshot(forPath: "feeds/followees")
                let followeeFeedEnumerator = followeeFeedSnapshot.children
                
                while let drink = followeeFeedEnumerator.nextObject() as? FIRDataSnapshot
                {
                    self.followeeFeedDrinks.append(FirebaseDrink(id: drink.key))
                }
                
                let followeesSnapshot = snapshot.childSnapshot(forPath: "followees")
                let followeesEnumerator = followeesSnapshot.children
                
                while let followee = followeesEnumerator.nextObject() as? FIRDataSnapshot
                {
                    self.followees.append(FirebaseUser(id: followee.key))
                }
                
                
                
                
                
                
                // Testing!
                self.followees.append(FirebaseUser(id: uid))
                
                
                
                
                
                
                // need the names, photos and sharing settings
                // what happens if this takes too long?
                self.fetchUserData(dispatchGroup: dispatchGroup, friendsOrFollowees: "followees")
                
                if self.followeeFeedDrinks.count > 1000
                {
                    self.trimFeed(uid: uid, friendsOrFollowees: "followees")
                }
                
                // I'm hoping this provides chronological sorting (with the newest object at index 0).
                // self.followeeFeedDrinks.sortInPlace({$0.id.caseInsensitiveCompare($1.id) == NSComparisonResult.OrderedDescending})
                self.followeeFeedDrinks.sort(by: {$0.id.compare($1.id) == ComparisonResult.orderedDescending})
                
                
                
                // need a way to cancel stuff if fetching runs too long
                
                
                
                dispatchGroup.notify(queue: DispatchQueue.main, execute:
                {
                    // check for errors?
                    // possible error locations...
                    // nothing from fetchDrinks
                    // nothing from compareFriends
                    // nothing from fetchUserData
                    // nothing from trimFeed
                    // check the rest
                    
                    self.fetchDrinks(friendsOrFollowees: "followees", batch: 0, usableDrinksPreviouslyFetched: 0)
                    {
                        if friendsFetched == true
                        {
                            self.fetchDrinks(friendsOrFollowees: "friends", batch: 0, usableDrinksPreviouslyFetched: 0)
                            {
                                self.allUsableDrinks = self.usableFolloweeFeedDrinks + self.usableFriendFeedDrinks
                                
                                self.allUsableDrinks.sort(by: {$0.selectedDateTime.compare($1.selectedDateTime) == ComparisonResult.orderedDescending})
                                
                                // I should probably sort usableFolloweeFeedDrinks and usableFriendFeedDrinks too
                                // I may as well do that before setting allUsableDrinks
                                
                                if self.segmentedControl.selectedSegmentIndex == 0
                                {
                                    self.drinkList = self.allUsableDrinks
                                }
                                else if self.segmentedControl.selectedSegmentIndex == 1
                                {
                                    self.drinkList = self.usableFriendFeedDrinks
                                }
                                else if self.segmentedControl.selectedSegmentIndex == 2
                                {
                                    self.drinkList = self.usableFolloweeFeedDrinks
                                }
                                
                                completion(nil)
                            }
                        }
                        else
                        {
                            self.allUsableDrinks = self.usableFolloweeFeedDrinks
                            self.allUsableDrinks.sort(by: {$0.selectedDateTime.compare($1.selectedDateTime) == ComparisonResult.orderedDescending})
                            
                            // I should probably sort usableFolloweeFeedDrinks too
                            // actually, if I do that first, I shouldn't need to sort allUsableDrinks
                            
                            if self.segmentedControl.selectedSegmentIndex == 0
                            {
                                self.drinkList = self.allUsableDrinks
                            }
                            else if self.segmentedControl.selectedSegmentIndex == 1
                            {
                                self.drinkList = self.usableFriendFeedDrinks
                            }
                            else if self.segmentedControl.selectedSegmentIndex == 2
                            {
                                self.drinkList = self.usableFolloweeFeedDrinks
                            }
                            
                            completion(nil)
                        }
                    }
                })
                
                
                
                
                // start working from here
                // or maybe dispatch_group_notify
                
                // maybe I should... download a batch of drinks, put the users in an array, fetch the user data, check for usable drinks, and download another batch if necessary
                // instead of... fetching data for all possible users, downloading a batch of drinks, checking for usable drinks, and fetching another batch if necessary
                // the first option involves more function calls: 1 drink fetch and 1 user fetch for each batch
                // but potentially less data (i.e., fewer actually fetches): only data for the relevant users is being downloaded
                // with enough friends or followees, you won't need data for each one in order to display 25/50 drinks
                
                // would switching affect my Facebook call? any of the trim functions? anything else?
                
                
                
                
                // have I checked to make sure the user is still friends with/following each drink's user?
                // I should be able to do that in checkForUsableDrinks
                
                
                
            }
        })
    }
        
    func removeFirebaseObserver()
    {
        if let currentUser = FIRAuth.auth()?.currentUser
        {
            firebaseRootRef.child("users/\(currentUser.uid)").removeAllObservers()
        }
        
        DispatchQueue.main.async
        {
            // something about timing out?
            // self.messageText = "\nSorry, we couldn't fetch any drinks.\n\n(We tried really hard!)"
            
            self.tableView.reloadData()
            
            if self.refreshControl?.isRefreshing == true
            {
                self.refreshControl?.endRefreshing()
            }
            
            // will this actually stop the fetch?
            // as in, does removing the observer prevent all the code from running?
            
            // actually, this is useless anyway since the user's data is also stored locally
            // I guess I should move timer.invalidate() to dispatch_group_notify
            
            // even if the code still runs, the UI should at least display an error message for a bit
            
            // I could test this by starting an observer, running some code (in the observer), stopping the observer (from within the observer), and then running more code (in the observer)
        }
    }
    
    func compareFriends(uid: String)
    {
        var firebaseFriendIDs = [String]()
        for friend in firebaseFriends
        {
            firebaseFriendIDs.append(friend.id)
        }
        
        // facebookFriendIDs.sortInPlace({$0.caseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
        facebookFriendIDs.sort(by: {$0.compare($1) == ComparisonResult.orderedAscending})
        
        // firebaseFriendIDs.sortInPlace({$0.caseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})
        firebaseFriendIDs.sort(by: {$0.compare($1) == ComparisonResult.orderedAscending})
        
        // if facebookFriendIDs == firebaseFriendIDs, do nothing, right?
        
        if firebaseFriendIDs != facebookFriendIDs
        {
            var removed = [String]()
            
            for id in firebaseFriendIDs
            {
                if !facebookFriendIDs.contains(id)
                {
                    removed.append(id)
                    
                    if let index = firebaseFriends.index(where: {$0.id == id})
                    {
                        firebaseFriends.remove(at: index)
                    }
                }
            }
            
            var added = [String]()
            
            for id in facebookFriendIDs
            {
                if !firebaseFriendIDs.contains(id)
                {
                    added.append(id)
                    
                    firebaseFriends.append(FirebaseUser(id: id))
                }
            }
            
            if removed.count > 0
            {
                for id in removed
                {
                    // update current user's data
                    firebaseRootRef.child("users/\(uid)/friends/\(id)").removeValue()
                    
                    // update friend's data
                    firebaseRootRef.child("users/\(id)/friends/\(uid)").removeValue()
                    
                    // if the feed ends up being empty (or mostly empty) or there are no drinks displayed (or almost none)...
                    // manually fetch drinks from the user's friends and people the user is following to repopulate the feed
                    // not yet sure where I should check that
                    // or if I should bother
                }
            }
            
            if added.count > 0
            {
                // would also need to update friendFeedDrinks (and sort?)
                // it looks like I'm going to need to make some asynchronous calls
                // this data may not be available to the user immediately then
                
                // let dispatchGroup = dispatch_group_create()
                
                for id in added
                {
                    // dispatch_group_enter(dispatchGroup)
                    
                    // 25? 50?
                    // queryLimitedToFirst or queryLimitedToLast?
                    // selectedDateTime or firebaseTimestamp?
                    // will selectedDateTime work with the spacing?
                    
                    firebaseRootRef.child("users/\(id)/drinks").queryOrdered(byChild: "selectedDateTime").queryLimited(toLast: 25).observeSingleEvent(of: .value, with:
                    {
                        snapshot in
                        
                        if snapshot.value is NSNull
                        {
                            // Do nothing.
                        }
                        else
                        {
                            let drinksEnumerator = snapshot.children
                            
                            while let drink = drinksEnumerator.nextObject() as? FIRDataSnapshot
                            {
                                self.firebaseRootRef.child("users/\(uid)/feeds/friends").updateChildValues([drink.key : "true"])
                                
                                // self.friendFeedDrinks.append(FirebaseDrink(id: drink.key))
                            }
                        }
                        
                        // update current user's data
                        self.firebaseRootRef.child("users/\(uid)/friends").updateChildValues([id : "true"])
                        
                        // update friend's data
                        self.firebaseRootRef.child("users/\(id)/friends").updateChildValues([uid : "true"])
                        
                        // dispatch_group_leave(dispatchGroup)
                    })
                }
                
                /*
                dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(),
                {
                    // so that trimFeed works
                    self.friendFeedDrinks.sortInPlace({$0.id.compare($1.id) == NSComparisonResult.OrderedAscending})
                    
                    // There was another equivalent to dispatch_group_notify, I think.
                    // There's a dispatch_group_wait
                    // Also, it allows you to specify a time. Nice.
                    
                    // I think I need a completion handler
                    // Yep. Probably too much effort to make this work well.
                })
                */
            }
        }
    }
    
    func trimFeed(uid: String, friendsOrFollowees: String)
    {
        var i = 0
        
        var n = 0
        if friendsOrFollowees == "friends"
        {
            n = friendFeedDrinks.count - 1000
        }
        else if friendsOrFollowees == "followees"
        {
            n = followeeFeedDrinks.count - 1000
        }
        
        while i < n
        {
            if friendsOrFollowees == "friends"
            {
                firebaseRootRef.child("users/\(uid)/feeds/friends/\(friendFeedDrinks[i].id)").removeValue()
            }
            else if friendsOrFollowees == "followees"
            {
                firebaseRootRef.child("users/\(uid)/feeds/followees/\(followeeFeedDrinks[i].id)").removeValue()
            }
            
            i += 1
        }
    }
    
    func fetchUserData(dispatchGroup: DispatchGroup, friendsOrFollowees: String)
    {
        var users = [FirebaseUser]()
        if friendsOrFollowees == "friends"
        {
            users = firebaseFriends
        }
        else
        {
            users = followees
        }
        
        var i = 0
        let n = users.count
        while i < n
        {
            dispatchGroup.enter()
            
            let user = users[i]
            
            let j = i
            
            guard user.id != nil
            else
            {
                dispatchGroup.leave()
                
                i += 1
                
                continue
            }
            
            firebaseRootRef.child("users/\(user.id!)/info").observeSingleEvent(of: .value, with:
            {
                snapshot in
                
                if snapshot.value is NSNull
                {
                    // should never be null
                    // in any case, this user's drinks shouldn't get added to usableFriendFeedDrinks or usableFolloweeFeedDrinks
                }
                else
                {
                    if let snapshotValue = snapshot.value as? NSDictionary
                    {
                        // not currently used for anything
                        if let facebookID = snapshotValue["facebookID"] as? String
                        {
                            user.facebookID = facebookID
                        }
                        
                        if let name = snapshotValue["name"] as? String
                        {
                            user.name = name
                        }
                        
                        if let photo = snapshotValue["photoSquare"] as? String
                        {
                            user.photo = photo
                        }
                        
                        if let sharing = snapshotValue["sharing"] as? String
                        {
                            user.sharing = sharing
                        }
                    }
                }
                
                // I can't use i here because i is being synchronously updated.
                // In other words, by the time this code is called, i isn't the index I want.
                if friendsOrFollowees == "friends"
                {
                    self.firebaseFriends[j] = user
                }
                else
                {
                    self.followees[j] = user
                }
                
                dispatchGroup.leave()
            })
            
            i += 1
        }
    }
    
    func fetchDrinks(friendsOrFollowees: String, batch: Int, usableDrinksPreviouslyFetched: Int, completion: @escaping () -> Void)
    {
        // should be sorted, right?
        // need to limit this to the first 25? 50? 100?
        var i = 50 * batch
        
        var n: Int
        if friendsOrFollowees == "friends"
        {
            n = friendFeedDrinks.count
        }
        else
        {
            n = followeeFeedDrinks.count
        }
        
        if i >= n
        {
            completion()
        }
        else
        {
            let dispatchGroup = DispatchGroup()
            
            while (i < 50 * (batch + 1)) && (i < n)
            {
                dispatchGroup.enter()
                
                // maybe I should just change the FirebaseDrink model
                var drink = FirebaseDrink(id: "")
                if friendsOrFollowees == "friends"
                {
                    drink = friendFeedDrinks[i]
                }
                else
                {
                    drink = followeeFeedDrinks[i]
                }
                
                let j = i
                
                guard drink.id != nil
                else
                {
                    dispatchGroup.leave()
                    
                    i += 1
                    
                    continue
                }
                
                firebaseRootRef.child("drinks/\(drink.id!)").observeSingleEvent(of: .value, with:
                {
                    snapshot in
                        
                    if snapshot.value is NSNull
                    {
                        // should never be null
                        // in any case, this drink shouldn't get added to usableFriendFeedDrinks or usableFolloweeFeedDrinks
                    }
                    else
                    {
                        
                        
                        
                        // should this just be if let snapshotValue = snapshot.value as? FirebaseDrink?
                        // that should simplify the rest of this
                        
                        
                        
                        if let snapshotValue = snapshot.value as? NSDictionary
                        {
                            // since I'm using "if let as?", I don't need to worry about some of these properties not existing, right?
                            
                            if let userID = snapshotValue["userID"] as? String
                            {
                                drink.userID = userID
                            }
                                
                            if let displayName = snapshotValue["displayName"] as? String
                            {
                                drink.displayName = displayName
                            }
                            
                            if let type = snapshotValue["type"] as? String
                            {
                                drink.type = type
                            }
                                
                            if let breweryName = snapshotValue["breweryName"] as? String
                            {
                                drink.breweryName = breweryName
                            }
                                
                            if let beerName = snapshotValue["beerName"] as? String
                            {
                                drink.beerName = beerName
                            }
                                
                            if let vineyardName = snapshotValue["vineyardName"] as? String
                            {
                                drink.vineyardName = vineyardName
                            }
                                
                            if let wineName = snapshotValue["wineName"] as? String
                            {
                                drink.wineName = wineName
                            }
                                
                            if let vintage = snapshotValue["vintage"] as? String
                            {
                                drink.vintage = vintage
                            }
                                
                            if let entryMode = snapshotValue["entryMode"] as? Int
                            {
                                drink.entryMode = entryMode
                            }
                                
                            // not entirely sure how ingredients are going to be organized yet
                            // drinks/ID/ingredients/ID? 0-X?
                            if let ingredientsDictionary = snapshotValue["ingredients"] as? [NSDictionary]
                            {
                                var ingredients = [FirebaseIngredient]()
                                    
                                for ingredientEntry in ingredientsDictionary
                                {
                                    let ingredient = FirebaseIngredient()
                                        
                                    if let name = ingredientEntry["name"] as? String
                                    {
                                        ingredient.name = name
                                    }
                                        
                                    if let volume = ingredientEntry["volume"] as? Double
                                    {
                                        ingredient.volume = volume
                                    }
                                        
                                    if let volumeUnits = ingredientEntry["volumeUnits"] as? Int
                                    {
                                        ingredient.volumeUnits = volumeUnits
                                    }
                                        
                                    if let abv = ingredientEntry["abv"] as? Double
                                    {
                                        ingredient.abv = abv
                                    }
                                        
                                    ingredients.append(ingredient)
                                }
                                
                                drink.ingredients = ingredients
                            }
                                
                            if let locationName = snapshotValue["locationName"] as? String
                            {
                                drink.locationName = locationName
                            }
                            
                            if let locationID = snapshotValue["locationID"] as? String
                            {
                                drink.locationID = locationID
                            }
                                
                            if let locationAddress = snapshotValue["locationAddress"] as? String
                            {
                                drink.locationAddress = locationAddress
                            }
                                
                            if let locationLatitude = snapshotValue["locationLatitude"] as? String
                            {
                                drink.locationLatitude = locationLatitude
                            }
                                
                            if let locationLongitude = snapshotValue["locationLongitude"] as? String
                            {
                                drink.locationLongitude = locationLongitude
                            }
                            
                            if let caption = snapshotValue["caption"] as? String
                            {
                                drink.caption = caption
                            }
                            
                            if let commentCount = snapshotValue["commentCount"] as? Int
                            {
                                drink.commentCount = commentCount
                            }
                                
                            if let likeCount = snapshotValue["likeCount"] as? Int
                            {
                                drink.likeCount = likeCount
                            }
                                
                            if let os = snapshotValue["os"] as? String
                            {
                                drink.os = os
                            }
                                
                            // need to double check this
                            if let firebaseTimestamp = snapshotValue["firebaseTimestamp"] as? TimeInterval
                            {
                                drink.firebaseTimestamp = Date(timeIntervalSince1970: firebaseTimestamp / 1000)
                            }
                                
                            if let abv = snapshotValue["abv"] as? Double
                            {
                                drink.abv = abv
                            }
                                
                            if let volume = snapshotValue["volume"] as? Double
                            {
                                drink.volume = volume
                            }
                                
                            if let volumeUnits = snapshotValue["volumeUnits"] as? Int
                            {
                                drink.volumeUnits = volumeUnits
                            }
                                
                            if let effectiveDrinkCount = snapshotValue["effectiveDrinkCount"] as? Double
                            {
                                drink.effectiveDrinkCount = effectiveDrinkCount
                            }
                                
                            if let bacEstimation = snapshotValue["bacEstimation"] as? Bool
                            {
                                drink.bacEstimation = bacEstimation
                            }
                                
                            if let savedDateTime = snapshotValue["savedDateTime"] as? String
                            {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy MM dd HH mm ss"
                                dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                                    
                                drink.savedDateTime = dateFormatter.date(from: savedDateTime)
                            }
                                
                            if let selectedDateTime = snapshotValue["selectedDateTime"] as? String
                            {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy MM dd HH mm ss"
                                dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                                
                                drink.selectedDateTime = dateFormatter.date(from: selectedDateTime)
                            }
                        }
                    }
                    
                    // I can't use i here because i is being synchronously updated.
                    // In other words, by the time this code is called, i isn't the index I want.
                    if friendsOrFollowees == "friends"
                    {
                        self.friendFeedDrinks[j] = drink
                    }
                    else
                    {
                        self.followeeFeedDrinks[j] = drink
                    }
                    
                    dispatchGroup.leave()
                })
                
                i += 1
            }
            
            dispatchGroup.notify(queue: DispatchQueue.main, execute:
            {
                let usableDrinksJustFetched = self.checkForUsableDrinks(friendsOrFollowees: friendsOrFollowees, batch: batch)
                
                if (usableDrinksPreviouslyFetched + usableDrinksJustFetched) < 25
                {
                    self.fetchDrinks(friendsOrFollowees: friendsOrFollowees, batch: batch + 1, usableDrinksPreviouslyFetched: usableDrinksPreviouslyFetched + usableDrinksJustFetched)
                    {
                        completion()
                    }
                }
                else
                {
                    completion()
                }
            })
        }
    }
    
    func checkForUsableDrinks(friendsOrFollowees: String, batch: Int) -> Int
    {
        // the following should be (generally) consistent with fetchDrinks
        
        var count = 0
        
        var drinks = [FirebaseDrink]()
        var users = [FirebaseUser]()
        
        var n: Int
        
        if friendsOrFollowees == "friends"
        {
            drinks = friendFeedDrinks
            users = firebaseFriends
            
            n = friendFeedDrinks.count
        }
        else
        {
            drinks = followeeFeedDrinks
            users = followees
            
            n = followeeFeedDrinks.count
        }
        
        var i = 50 * batch
        while i < 50 * (batch + 1) && (i < n)
        {
            // The users should always have IDs because of the way they're fetched/created.
            guard drinks[i].userID != nil
            else
            {
                // I'm only adding usable drinks so there's no need to do anything else.
                i += 1
                
                continue
            }
            
            if let index = users.index(where: {$0.id == drinks[i].userID})
            {
                let userSharingSetting = users[index].sharing
                
                if friendsOrFollowees == "friends" && (userSharingSetting == "Public" || userSharingSetting == "Friends")
                {
                    // make sure the user is still friends with the drink's owner?
                    // actually, the "if let index" should take care of that
                    
                    drinks[i].userName = users[index].name
                    drinks[i].userPhoto = users[index].photo
                    
                    usableFriendFeedDrinks.append(drinks[i])
                    
                    count += 1
                }
                
                if friendsOrFollowees == "followees" && userSharingSetting == "Public"
                {
                    // make sure the user is still following the drink's owner?
                    // actually, the "if let index" should take care of that
                    
                    drinks[i].userName = users[index].name
                    drinks[i].userPhoto = users[index].photo
                    
                    usableFolloweeFeedDrinks.append(drinks[i])
                    
                    count += 1
                }
            }
            
            i += 1
        }
        
        lastBatchFetchedAndChecked = batch
        
        return count
    }
    
    @IBAction func doneToFeed(_ segue: UIStoryboardSegue)
    {
        // if there were any changes, refresh
        if shouldRefresh == true
        {
            shouldRefresh = false
            
            /*
            if PFUser.currentUser() != nil
            {
                refreshControl?.beginRefreshing()
                
                // fetchDrinks()
                fetchFollowingDrinks()
            }
            // else, do nothing?
            */
            
            // the following should be consistent with viewDidLoad
            // should I add a timer?
            if let uid = FIRAuth.auth()?.currentUser?.uid
            {
                refreshControl?.beginRefreshing()
                
                fetchFacebookFriends()
                {
                    (friendsFetched: Bool) in
                    
                    // just pass the variable in to fetchFirebaseData? (along with the uid)
                    // I can still get the drinks of the people the user is following at least
                    // some sort of message or alert? that may already be taken care of in cellForRowAtIndexPath
                        
                    self.fetchFirebaseData(uid: uid, friendsFetched: friendsFetched)
                    {
                        (error: String?) in
                        
                        self.fillMessageTextArray(error: error, friendsFetched: friendsFetched)
                        
                        self.tableView.reloadData()
                        
                        if self.refreshControl?.isRefreshing == true
                        {
                            self.refreshControl?.endRefreshing()
                        }
                        
                        if friendsFetched == false
                        {
                            // Alert
                            // "Unfortunately, we couldn’t retrieve the data we needed from Facebook so we won’t be able to show you any of your friends’ drinks. However, we did still check for drinks for the people you follow."
                        }
                        
                        // observe childAdded for each feed? (depending on friendsFetched)
                        // unless this was already taken care of in viewDidLoad
                        // set a variable on success and check it here?
                    }
                }
            }
            else
            {
                // Suggest the user log back in? Try logging the user back in first?
                // I think I may need a slightly different message here.
                
                messageTextArray.removeAll()
                
                // all segment
                messageTextArray.append("\nTo see drinks from your friends and the people you follow, please log in by going to More -> Social.")
                
                // friends segment
                messageTextArray.append("\nTo see drinks from your friends and the people you follow, please log in by going to More -> Social.")
                
                // following segment
                messageTextArray.append("\nTo see drinks from your friends and the people you follow, please log in by going to More -> Social.")
                
                tableView.reloadData()
            }
        }
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl)
    {
        if sender.selectedSegmentIndex == 0
        {
            // drinkList = allDrinkList
            drinkList = allUsableDrinks
            
            tableView.reloadSections(IndexSet(integer: 0), with: UITableViewRowAnimation.right)
        }
        else if sender.selectedSegmentIndex == 1
        {
            // drinkList = friendsDrinkList
            drinkList = usableFriendFeedDrinks
            
            if previousSelectedSegmentIndex == 0
            {
                tableView.reloadSections(IndexSet(integer: 0), with: UITableViewRowAnimation.left)
            }
            else
            {
                tableView.reloadSections(IndexSet(integer: 0), with: UITableViewRowAnimation.right)
            }
        }
        else
        {
            // drinkList = followingDrinkList
            drinkList = usableFolloweeFeedDrinks
            
            tableView.reloadSections(IndexSet(integer: 0), with: UITableViewRowAnimation.left)
        }
        
        previousSelectedSegmentIndex = sender.selectedSegmentIndex
    }
    
    override func didReceiveMemoryWarning()
    {
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
        if drinkList.count == 0
        {
            return 1
        }
        else
        {
            return drinkList.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if drinkList.count > 0
        {
            // let drink = drinkList[indexPath.row] as ParseDrinkEntry
            let drink = drinkList[indexPath.row]
            
            if drink.type == "beer" || drink.type == "wine"
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FeedBeerWineCell", for: indexPath) as! FeedBeerWineTableViewCell
                
                cell.nameLabel.text = drink.displayName
                cell.dateTimeLabel.text = createDateTimeString(selectedDateTime: drink.selectedDateTime)
                
                if let name = drink.userName
                {
                    cell.userNameLabel.text = name
                }
                else
                {
                    updateUserName(drink: drink)
                }
                
                if let photo = drink.userPhoto
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
                            
                            self.updateUserPhoto(drink: drink)
                            
                            // what if the problem is that there's no internet access?
                        }
                    }
                }
                else
                {
                    updateUserPhoto(drink: drink)
                }
                
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
                let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCocktailShotCell", for: indexPath) as! FeedCocktailShotTableViewCell
                
                cell.nameLabel.text = drink.displayName
                cell.dateTimeLabel.text = createDateTimeString(selectedDateTime: drink.selectedDateTime)
                
                if let name = drink.userName
                {
                    cell.userNameLabel.text = name
                }
                else
                {
                    updateUserName(drink: drink)
                }
                
                if let photo = drink.userPhoto
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
                            
                            self.updateUserPhoto(drink: drink)
                            
                            // what if the problem is that there's no internet access?
                        }
                    }
                }
                else
                {
                    updateUserPhoto(drink: drink)
                }
                
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
        else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath) 
            
            // cell.textLabel?.text = messageText
            
            if messageTextArray.count == 3
            {
                if segmentedControl.selectedSegmentIndex == 0
                {
                    cell.textLabel?.text = messageTextArray[0]
                }
                else if segmentedControl.selectedSegmentIndex == 1
                {
                    cell.textLabel?.text = messageTextArray[1]
                }
                else if segmentedControl.selectedSegmentIndex == 2
                {
                    cell.textLabel?.text = messageTextArray[2]
                }
            }
            
            tableView.separatorStyle = .none
            
            return cell
        }
    }
    
    func createDateTimeString(selectedDateTime: Date) -> String
    {
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
    
    // no longer used
    /*
    func updateFriendPhoto(drink: ParseDrinkEntry)
    {
        // limit to 3 or so friends to reduce the number of calls (in case something goes wrong)
        if friendsWithUpdatedPhotos.count < 3
        {
            // don't want to call this function multiple times for the same friend
            if !friendsWithUpdatedPhotos.contains(drink.parseUser)
            {
                friendsWithUpdatedPhotos.append(drink.parseUser)
                
                // var params = ["token" : FBSDKAccessToken.currentAccessToken().tokenString, "fbID" : drink.parseUser.valueForKey("facebookID") as? String, "parseID" : drink.parseUser.objectId]
                var params = ["token": FBSDKAccessToken.currentAccessToken().tokenString]
                params["fbID"] = drink.parseUser.valueForKey("facebookID") as? String
                params["parseID"] = drink.parseUser.objectId
                
                do
                {
                    try PFCloud.callFunction("updateFriendPhoto", withParameters: params)
                }
                catch let error as NSError
                {
                    // Do nothing?
                    print("Error in Cloud Code function updateFriendPhoto: \(error)")
                }
            }
        }
    }
    */
    
    func updateUserName(drink: FirebaseDrink)
    {
        // don't want to call this function multiple times for the same user
        if !usersWithUpdatedNames.contains(drink.userID)
        {
            usersWithUpdatedNames.append(drink.userID)
            
            // I need the user's Facebook ID. This is not the same as the user's ID. The user's ID is the user's Facebook ID plus "facebook:" (at least so long as I only allow logging in via Facebook).
            
            // need to remove "facebook:", which is 9 characters
            let index = drink.userID.index(drink.userID.startIndex, offsetBy: 9)
            let id = drink.userID.substring(from: index)
            
            // alternatively, I can find the user in firebaseFriends or followees whose id matches drink.userID
            // then I can access that user's facebookID
            
            DispatchQueue.main.async
            {
                let request: FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "/" + id + "?fields=name", parameters: nil, httpMethod: "GET")
                
                request.start(completionHandler:
                {
                    (connection, result, error) -> Void in
                        
                    if error != nil
                    {
                        // Do nothing?
                        print("Error in updateUserName: \(error)")
                    }
                    else
                    {
                        // let results = result as! NSDictionary
                        
                        // let name = results.object(forKey: "name") as! String
                        
                        if let resultDictionary = result as? NSDictionary
                        {
                            if let name = resultDictionary.object(forKey: "name") as? String
                            {
                                let firebaseData = ["name": name]
                                    
                                self.firebaseRootRef.child("users/\(drink.userID)/info").updateChildValues(firebaseData)
                                
                                // should I also find and update the drink in the drinkList?
                            }
                        }
                        // else, do nothing?
                    }
                })
            }
        }
    }
    
    func updateUserPhoto(drink: FirebaseDrink)
    {
        // don't want to call this function multiple times for the same user
        if !usersWithUpdatedPhotos.contains(drink.userID)
        {
            usersWithUpdatedPhotos.append(drink.userID)
            
            // I need the user's Facebook ID. This is not the same as the user's ID. The user's ID is the user's Facebook ID plus "facebook:" (at least so long as I only allow logging in via Facebook).
            
            // need to remove "facebook:", which is 9 characters
            let index = drink.userID.index(drink.userID.startIndex, offsetBy: 9)
            let id = drink.userID.substring(from: index)
            
            // alternatively, I can find the user in firebaseFriends or followees whose id matches drink.userID
            // then I can access that user's facebookID
            
            DispatchQueue.main.async
            {
                let request: FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "/" + id + "/picture?fields=url&width=150&height=150&redirect=false", parameters: nil, httpMethod: "GET")
                
                request.start(completionHandler:
                {
                    (connection, result, error) -> Void in
                    
                    if error != nil
                    {
                        // Do nothing?
                        print("Error in updateUserPhoto: \(error)")
                    }
                    else
                    {
                        // let results = result as! NSDictionary
                        
                        // let url = results.object(forKey: "data")?.objectForKey("url") as! String
                        
                        if let resultDictionary = result as? NSDictionary
                        {
                            if let data = resultDictionary.object(forKey: "data") as? NSDictionary
                            {
                                if let url = data.object(forKey: "url") as? String
                                {
                                    let firebaseData = ["photoSquare": url]
                                    
                                    self.firebaseRootRef.child("users/\(drink.userID)/info").updateChildValues(firebaseData)
                                    
                                    // should I also find and update the drink in the drinkList?
                                }
                            }
                        }
                        // else, do nothing?
                    }
                })
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if drinkList.count > 0
        {
            // I need the selected cell so I can pass the selected drink to the details page.
            performSegue(withIdentifier: "FeedDrinkSelection", sender: tableView.cellForRow(at: indexPath))
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if drinkList.count == 0
        {
            return self.view.frame.height - self.refreshControl!.frame.height
        }
        else
        {
            return 154
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if drinkList.count > 0
        {
            return UITableViewAutomaticDimension + 7
        }
        else
        {
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        // Needs to be transparent.
        view.tintColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 0.0)
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if identifier == "AddFollowees"
        {
            if FIRAuth.auth()?.currentUser == nil
            {
                alert()
                
                return false
            }
        }
        
        return true
    }
    
    func alert()
    {
        let alertController = UIAlertController(title: "Error", message: "You must be logged in to follow other users.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "FeedDrinkSelection"
        {
            if let selectedCell = sender as? UITableViewCell
            {
                if let selectedIndexPath = tableView.indexPath(for: selectedCell)
                {
                    let selectedDrink = drinkList[selectedIndexPath.row]
                    
                    if let friendDrinkDetailsTVC = segue.destination as? FriendDrinkDetailsTableViewController
                    {
                        friendDrinkDetailsTVC.selectedDrink = selectedDrink
                    }
                }
            }
        }
    }

}
