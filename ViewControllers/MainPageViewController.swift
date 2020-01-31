//
//  MainPageViewController.swift
//  Cheers
//
//  Created by Air on 2/8/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData
import Firebase

class MainPageViewController: UIViewController
{
    @IBOutlet weak var mostRecentDrinkNameLabel: UILabel!
    @IBOutlet weak var mostRecentDrinkSourceLabel: UILabel!
    @IBOutlet weak var mostRecentDrinkDateTimeLabel: UILabel!
    @IBOutlet weak var mostRecentSessionLabel: UILabel!
    @IBOutlet weak var bacButton: UIButton!
    @IBOutlet weak var mostRecentSessionView: UIView!
    @IBOutlet weak var mostRecentDrinkImageView: UIImageView!
    @IBOutlet weak var mostRecentDrinkView: UIView!
    @IBOutlet var mostRecentDrinkViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var mostRecentDrinkViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var mostRecentDrinkImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var mostRecentDrinkSourceLabelHeightConstraint: NSLayoutConstraint!
        
    var drinkHistory = [DrinkEntry]()
    // var drinkHistory = [NSManagedObject]()
    
    var mostRecentSessionViewIsVisible: Bool = false
    
    // let firebaseRootRef = Firebase(url: "https://glowing-inferno-7505.firebaseio.com")
    let firebaseRootRef = FIRDatabase.database().reference()
    
    @IBAction func cancelAddDrink(_ segue: UIStoryboardSegue)
    {
        // Do nothing.
    }
    
    @IBAction func saveDrink(_ segue: UIStoryboardSegue)
    {
        // Do nothing?
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // I thought I could use applicationWillEnterForeground...
        // but it doesn't seem to trigger when I want it to.
        // Apparently, neither does applicationDidBecomeActive
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainPageViewController.enteredForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        // NSNotificationCenter.defaultCenter().addObserver(self, selector: "becameActive", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(MainPageViewController.swipedLeft))
        leftSwipeGesture.direction = .left
        self.view.addGestureRecognizer(leftSwipeGesture)
        
        self.tabBarController?.view.backgroundColor = UIColor.white
    
        let transform = CGAffineTransform(scaleX: 1.0, y: 0.01)
        let point = mostRecentSessionView.center
        mostRecentSessionView.transform = transform
        mostRecentSessionView.center = point
        
        // if there was an error updating some other user's data when the current user followed/unfollowed that user, try updating that user's data again
        updateFollowersIfNecessary()
        
        /*
        // refresh Amazon credentials and sync userDataset if the user is logged in
        if FBSDKAccessToken.currentAccessToken() != nil
        {
            refreshAndSync()
        }
        */
        
        if let user = FIRAuth.auth()?.currentUser
        {
            let defaults = UserDefaults.standard
            
            let fetchInfo = defaults.bool(forKey: "fetchFacebookInfo")
            
            if fetchInfo == true
            {
                fetchFacebookInfo(uid: user.uid)
            }
            
            let fetchPicture = defaults.bool(forKey: "fetchFacebookPicture")
            
            if fetchPicture == true
            {
                fetchFacebookPicture(uid: user.uid)
            }
            
        }
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        updateUI()
        
        mostRecentDrinkViewLeadingConstraint.isActive = false
        mostRecentDrinkViewTrailingConstraint.isActive = false
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        // not sure if 30 is the right value for this
        if self.view.frame.width - mostRecentDrinkView.frame.width < 30
        {
            mostRecentDrinkViewLeadingConstraint.isActive = true
            mostRecentDrinkViewTrailingConstraint.isActive = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        if mostRecentSessionViewIsVisible
        {
            toggleMostRecentSessionView()
        }
        
        super.viewWillDisappear(animated)
    }
    
    func enteredForeground()
    {
        updateUI()
        
        /*
        let currentDateTime = Date()
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeZone = NSTimeZone.systemTimeZone()
        foregroundLabel.text = "entered foreground at \(dateFormatter.stringFromDate(currentDateTime))"
        */
    }
    
    // not currently in use
    /*
    func becameActive()
    {
        updateUI()
        
        let currentDateTime = Date()
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeZone = NSTimeZone.systemTimeZone()
        activeLabel.text = "became active at \(dateFormatter.stringFromDate(currentDateTime))"
    }
    */
    
    func updateUI()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName:"DrinkEntry")
        fetchRequest.fetchLimit = 50
        
        // selected or universal?
        let sortDescriptor = NSSortDescriptor(key: "selectedDateTime", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do
        {
            let fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
            
            // if let results = fetchedResults
            if let results = fetchedResults as? [DrinkEntry]
            {
                drinkHistory = results
                
                if (drinkHistory.count > 0)
                {
                    // Update UI.
                    let mostRecentDrink = drinkHistory[0]
                    displayMostRecentDrink(mostRecentDrink: mostRecentDrink)
                    
                    // check the BAC setting
                    let defaults = UserDefaults.standard
                    let bacEstimation = defaults.bool(forKey: "bacEstimation")
                    
                    if bacEstimation == true
                    {
                        // bac, effectiveDrinkCount, sessionDuration
                        let data: (Double, Double, Double) = calculateBAC()
                        
                        bacButton.setTitle(String(format: "%.3f", data.0), for: UIControlState.normal)
                        
                        let effectiveDrinkCountString = String(format: "%.2f drinks", data.1)
                        let sessionDurationString = String(format: "%.2f hours", data.2)
                        mostRecentSessionLabel.text = effectiveDrinkCountString + " over " + sessionDurationString
                    }
                }
                // else
                // set bacText to 0
                // clear the mostRecentDrinkNameLabel, effectiveDrinkText, and sessionDurationText
                // actually, just need this for when the only drink in the drinkHistory is deleted, I think
            }
        }
        catch let error
        {
            print("Could not fetch \(error)")
        }
    }
    
    func displayMostRecentDrink(mostRecentDrink: DrinkEntry)
    {
        mostRecentDrinkNameLabel.text = mostRecentDrink.displayName
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = NSTimeZone.system
        // selected or universal?
        mostRecentDrinkDateTimeLabel.text = dateFormatter.string(from: mostRecentDrink.universalDateTime)
        
        if mostRecentDrink.type == "beer"
        {
            mostRecentDrinkSourceLabel.text = mostRecentDrink.breweryName
            
            mostRecentDrinkSourceLabelHeightConstraint.isActive = false
            
            if let image = UIImage(named: "Beer 250 (no side padding)")
            {
                let width = (image.size.width / image.size.height) * 88.0
                mostRecentDrinkImageViewWidthConstraint.constant = width
                
                mostRecentDrinkImageView.image = image
            }
        }
        else if mostRecentDrink.type == "wine"
        {
            mostRecentDrinkSourceLabel.text = mostRecentDrink.vineyardName
            
            mostRecentDrinkSourceLabelHeightConstraint.isActive = false
            
            if let image = UIImage(named: "Wine 250 (no side padding)")
            {
                let width = (image.size.width / image.size.height) * 88.0
                mostRecentDrinkImageViewWidthConstraint.constant = width
                
                mostRecentDrinkImageView.image = image
            }
        }
        else if mostRecentDrink.type == "cocktail"
        {
            mostRecentDrinkSourceLabel.text = String()
            
            mostRecentDrinkSourceLabelHeightConstraint.isActive = true
            
            if let image = UIImage(named: "Cocktail 250 (no side padding)")
            {
                let width = (image.size.width / image.size.height) * 88.0
                mostRecentDrinkImageViewWidthConstraint.constant = width
                
                mostRecentDrinkImageView.image = image
            }
        }
        else
        {
            mostRecentDrinkSourceLabel.text = String()
            
            mostRecentDrinkSourceLabelHeightConstraint.isActive = true
            
            if let image = UIImage(named: "Shot 125 (no side padding)")
            {
                let width = (image.size.width / image.size.height) * 88.0
                mostRecentDrinkImageViewWidthConstraint.constant = width
                
                mostRecentDrinkImageView.image = image
            }
        }
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
    
    @IBAction func bacButtonTouchUpInside(_ sender: UIButton)
    {
        toggleMostRecentSessionView()
    }
    
    // animate appearance and disappearance of the view
    func toggleMostRecentSessionView()
    {
        if mostRecentSessionViewIsVisible
        {
            let transform = CGAffineTransform(scaleX: 1.0, y: 0.01)
            let point = mostRecentSessionView.center
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations:
            {
                self.mostRecentSessionView.transform = transform
                self.mostRecentSessionView.center = point
                    
                self.mostRecentDrinkView.frame = CGRect(x: self.mostRecentDrinkView.frame.origin.x, y: self.mostRecentDrinkView.frame.origin.y - 19, width: self.mostRecentDrinkView.frame.width, height: self.mostRecentDrinkView.frame.height)
                    
                self.bacButton.frame = CGRect(x: self.bacButton.frame.origin.x, y: self.bacButton.frame.origin.y + 19, width: self.bacButton.frame.width, height: self.bacButton.frame.height)
            },
            completion:
            {
                finished in
                
                self.mostRecentSessionView.alpha = 0.0
            })
        }
        else
        {
            let transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            let point = mostRecentSessionView.center
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations:
            {
                self.mostRecentSessionView.alpha = 1.0
                
                self.mostRecentSessionView.transform = transform
                self.mostRecentSessionView.center = point
                                    
                self.mostRecentDrinkView.frame = CGRect(x: self.mostRecentDrinkView.frame.origin.x, y: self.mostRecentDrinkView.frame.origin.y + 19, width: self.mostRecentDrinkView.frame.width, height: self.mostRecentDrinkView.frame.height)
                
                self.bacButton.frame = CGRect(x: self.bacButton.frame.origin.x, y: self.bacButton.frame.origin.y - 19, width: self.bacButton.frame.width, height: self.bacButton.frame.height)
            },
            completion: nil)
        }
        
        mostRecentSessionViewIsVisible = !mostRecentSessionViewIsVisible
    }
    
    func calculateBAC() -> (Double, Double, Double)
    {
        let defaults = UserDefaults.standard
        // Have to exist to reach this code.
        let sex: Int = defaults.integer(forKey: "sex")
        let weight: Int = defaults.integer(forKey: "weight")
        
        var userBAC: Double = 0
        
        // Already checked for count == 0 above.
        if (drinkHistory.count == 0)
        {
            return (0, 0, 0)
        }
        else
        {
            var session = [DrinkEntry]()
            
            let currentDateTime = Date()
            
            var correctSession = [DrinkEntry]()
            
            var i = 0
            let n = drinkHistory.count
            while i < n
            {
                if (currentDateTime.compare(drinkHistory[i].universalDateTime) == ComparisonResult.orderedDescending)
                {
                    session.append(drinkHistory[i])
                    session.sort(by: { $0.universalDateTime.compare($1.universalDateTime) == ComparisonResult.orderedDescending })
                    
                    let sessionBAC = calculateSessionBAC(session: session, currentDateTime: currentDateTime, sex: sex, weight: weight)
                    
                    if (sessionBAC <= 0)
                    {
                        if (currentDateTime.timeIntervalSince(drinkHistory[i].universalDateTime) > (72 * 60 * 60))
                        {
                            break
                        }
                    }
                    
                    if (sessionBAC > userBAC)
                    {
                        userBAC = sessionBAC
                        
                        // Doesn't work because some drinks end up being skipped.
                        // correctSession.append(drinkHistory[i])
                        
                        // Make sure this works (it doesn't on Windows Phone)
                        correctSession = session
                    }
                }
                
                i += 1
            }
            
            // Should already be sorted.
            // correctSession.sort({ $0.universalDateTime.compare($1.universalDateTime) == NSComparisonResult.OrderedDescending })
            
            var effectiveDrinkCount = calculateEffectiveDrinkCount(session: correctSession, currentDateTime: currentDateTime)
            
            var sessionDuration = calculateSessionDuration(session: correctSession, currentDateTime: currentDateTime)
            
            if correctSession.count == 0
            {
                let mostRecentSession = loadMostRecentSession()
                
                // make sure the session is sorted?
                
                effectiveDrinkCount = calculateEffectiveDrinkCount(session: mostRecentSession, currentDateTime: currentDateTime)
                
                sessionDuration = calculateSessionDuration(session: mostRecentSession, currentDateTime: currentDateTime)
            }
            else
            {
                saveMostRecentSession(mostRecentSession: correctSession)
            }
            
            return (userBAC, effectiveDrinkCount, sessionDuration)
        }
    }
    
    func calculateSessionBAC(session: [DrinkEntry], currentDateTime: Date, sex: Int, weight: Int) -> Double
    {
        var effectiveDrinks: Double = 0
        
        var i = 0
        let n = session.count
        while i < n
        {
            // There's no guarantee all the drinks have an effectiveDrinkCount even if BAC estimation is on.
            if let effectiveDrinkCount = session[i].effectiveDrinkCount
            {
                effectiveDrinks += effectiveDrinkCount.doubleValue
            }
            
            i += 1
        }
        
        let timeSinceCurrentDrink = currentDateTime.timeIntervalSince(session[0].universalDateTime)
        
        var unconsumedDrinks: Double = 0
        
        if (timeSinceCurrentDrink >= (30 * 60) || session[0].type == "shot")
        {
            unconsumedDrinks = 0
        }
        else
        {
            // There's no guarantee all the drinks have an effectiveDrinkCount even if BAC estimation is on.
            if let effectiveDrinkCount = session[0].effectiveDrinkCount
            {
                unconsumedDrinks = effectiveDrinkCount.doubleValue * (1 - (timeSinceCurrentDrink / (30 * 60)))
            }
        }
        let consumedDrinks: Double = effectiveDrinks - unconsumedDrinks
        
        var bodyWaterConstant: Double
        var metabolicRate: Double
        
        if (sex == 0)
        {
            bodyWaterConstant = 0.49
            metabolicRate = 0.017
        }
        else
        {
            bodyWaterConstant = 0.58
            metabolicRate = 0.015
        }
        
        // Kilogram conversion
        let weightInKG: Double = Double(weight) / 2.20462234
        
        let oldestDrinkDateTime: Date = session[session.count - 1].universalDateTime
        
        let drinkingPeriod: Double = max(0, currentDateTime.timeIntervalSince(oldestDrinkDateTime) / (60 * 60))
        
        let bac: Double = ((0.806 * consumedDrinks * 1.4) / (bodyWaterConstant * weightInKG)) - (metabolicRate * drinkingPeriod)
        
        return max(0, bac)
    }
    
    func calculateEffectiveDrinkCount(session: [DrinkEntry], currentDateTime: Date) -> Double
    {
        // Do I need to check for nil?
        if session.count > 0
        {
            var effectiveDrinks: Double = 0
            
            var i = 0
            let n = session.count
            while i < n
            {
                // There's no guarantee all the drinks have an effectiveDrinkCount even if BAC estimation is on.
                if let effectiveDrinkCount = session[i].effectiveDrinkCount
                {
                    effectiveDrinks += effectiveDrinkCount.doubleValue
                }
                
                i += 1
            }
            
            let timeSinceCurrentDrink = currentDateTime.timeIntervalSince(session[0].universalDateTime)
            
            var unconsumedDrinks: Double = 0
            if (timeSinceCurrentDrink >= (30 * 60) || session[0].type == "shot")
            {
                unconsumedDrinks = 0
            }
            else
            {
                // There's no guarantee all the drinks have an effectiveDrinkCount even if BAC estimation is on.
                if let effectiveDrinkCount = session[0].effectiveDrinkCount
                {
                    unconsumedDrinks = effectiveDrinkCount.doubleValue * (1 - (timeSinceCurrentDrink / (30 * 60)))
                }
            }
            
            return effectiveDrinks - unconsumedDrinks
        }
        else
        {
            return 0
        }
    }
    
    func calculateSessionDuration(session: [DrinkEntry], currentDateTime: Date) -> Double
    {
        // Do I need to check for nil?
        if session.count > 0
        {
            // Sorted above.
            return currentDateTime.timeIntervalSince(session[session.count - 1].universalDateTime) / (60 * 60)
        }
        else
        {
            return 0
        }
    }
    
    func saveMostRecentSession(mostRecentSession: [DrinkEntry])
    {
        var mostRecentSessionIDs = [String]()
        
        for drinkEntry in mostRecentSession
        {
            // I don't believe I can save the objectID itself to UserDefaults
            mostRecentSessionIDs.append(drinkEntry.objectID.uriRepresentation().absoluteString)
        }
        
        let defaults = UserDefaults.standard
        defaults.set(mostRecentSessionIDs, forKey: "mostRecentSessionIDs")
    }
    
    func loadMostRecentSession() -> [DrinkEntry]
    {
        let defaults = UserDefaults.standard
        
        if let mostRecentSessionIDs = defaults.array(forKey: "mostRecentSessionIDs") as? [String]
        {
            var mostRecentSession = [DrinkEntry]()
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            for id in mostRecentSessionIDs
            {
                if let idURL = URL(string: id)
                {
                    if let objectID = managedContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: idURL)
                    {
                        do
                        {
                            if let drinkEntry = try managedContext.existingObject(with: objectID) as? DrinkEntry
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
            }
            
            return mostRecentSession
        }
        else
        {
            return [DrinkEntry]()
        }
    }
    
    func updateFollowersIfNecessary()
    {
        if let currentUser = PFUser.current()
        {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName:"UpdateFollowers")
            
            do
            {
                let fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
                
                if let results = fetchedResults as? [UpdateFollowers]
                {
                    for result in results
                    {
                        if currentUser.objectId == result.currentUserID
                        {
                            var shouldCallCloudFunction: Bool
                            
                            // check the currentUser's data to make sure I'm doing the right thing
                            if result.addOrRemove == "add"
                            {
                                shouldCallCloudFunction = false
                                
                                if let followedUsers = currentUser["following"] as? [PFUser]
                                {
                                    for user in followedUsers
                                    {
                                        // i.e., only if the currentUser is still following the user that needs to be updated do I add the current user as a follower
                                        if user.objectId == result.userToUpdateID
                                        {
                                            shouldCallCloudFunction = true
                                        }
                                    }
                                }
                            }
                            else
                            {
                                shouldCallCloudFunction = true
                                
                                if let followedUsers = currentUser["following"] as? [PFUser]
                                {
                                    for user in followedUsers
                                    {
                                        // i.e., only if the current user is now following the user that needs to be updated do I not remove the current user as a follower
                                        if user.objectId == result.userToUpdateID
                                        {
                                            shouldCallCloudFunction = false
                                        }
                                    }
                                }
                            }
                            
                            if shouldCallCloudFunction == true
                            {
                                var params = ["userID": result.userToUpdateID]
                                params["addOrRemove"] = result.addOrRemove
                                
                                PFCloud.callFunction(inBackground: "updateFollowers", withParameters: params)
                                {
                                    (response: Any?, error: Error?) -> Void in
                                        
                                    if error == nil
                                    {
                                        managedContext.delete(result as NSManagedObject)
                                            
                                        do
                                        {
                                            try managedContext.save()
                                        }
                                        catch let error
                                        {
                                            print("Could not delete \(error)")
                                            
                                            // I don't think it actually matters if updateFollowers is called twice
                                            // there's a check above and in updateFollowers itself
                                        }
                                    }
                                }
                            }
                            else
                            {
                                managedContext.delete(result as NSManagedObject)
                                
                                do
                                {
                                    try managedContext.save()
                                }
                                catch let error
                                {
                                    print("Could not delete \(error)")
                                    
                                    // I don't think it actually matters if updateFollowers is called twice
                                    // there's a check above and in updateFollowers itself
                                }
                            }
                        }
                    }
                }
            }
            catch let error
            {
                print("Could not fetch \(error)")
            }
        }
    }
    
    /*
    func refreshAndSync()
    {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:0ac1e34c-f3d0-4316-8352-f117e40e3773")
        
        let token = FBSDKAccessToken.currentAccessToken().tokenString
        
        credentialsProvider.logins = [AWSCognitoLoginProviderKey.Facebook.rawValue: token]
        
        // no need to call getIdentityID?
        
        credentialsProvider.refresh().continueWithBlock(
        {
            (task) -> AnyObject! in
                
            if !task.cancelled && task.error == nil
            {
                let defaults = NSUserDefaults.standardUserDefaults()
                var dateTimeNow = Date()
                // I don't currently use this for anything
                defaults.setObject(dateTimeNow, forKey: "awsCredentialsRefreshed")
                
                let dataset = AWSCognito.defaultCognito().openOrCreateDataset("userDataset")
                
                dataset.synchronize().continueWithBlock(
                {
                    (task) -> AnyObject! in
                            
                    if !task.cancelled && task.error == nil
                    {
                        dateTimeNow = Date()
                        defaults.setObject(dateTimeNow, forKey: "awsDatasetSynched")
                    }
                            
                    return nil
                })
            }
                
            return nil
        })
    }
    */
    
    func fetchFacebookInfo(uid: String)
    {
        let request: FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "/me?fields=id,name", parameters: nil, httpMethod: "GET")
        
        request.start(completionHandler:
        {
            (connection, result, error) -> Void in
                        
            if error != nil
            {
                // Do nothing?
            }
            else
            {
                let results = result as! NSDictionary
                            
                let id = results.object(forKey: "id") as! String
                let name = results.object(forKey: "name") as! String
                            
                let data = ["facebookID": id, "name": name]
                            
                self.firebaseRootRef.child("users/\(uid)").updateChildValues(data)
                            
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "fetchFacebookInfo")
            }
        })
    }
    
    func fetchFacebookPicture(uid: String)
    {
        let request: FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "/me/picture?fields=url&width=150&height=150&redirect=false", parameters: nil, httpMethod: "GET")
        
        request.start(completionHandler:
        {
            (connection, result, error) -> Void in
                        
            if error != nil
            {
                // Do nothing?
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
                            
                            self.firebaseRootRef.child("users/\(uid)/info").updateChildValues(firebaseData)
                            
                            let defaults = UserDefaults.standard
                            defaults.removeObject(forKey: "fetchFacebookPicture")
                        }
                    }
                }
                // else, do nothing?
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
