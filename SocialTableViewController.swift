//
//  SocialTableViewController.swift
//  Cheers
//
//  Created by Air on 5/24/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4
import Firebase

class SocialTableViewController: UITableViewController {

    @IBOutlet weak var userCell: UITableViewCell!
    @IBOutlet weak var sharingCell: UITableViewCell!
    @IBOutlet weak var logInCell: UITableViewCell!
    @IBOutlet weak var logOutCell: UITableViewCell!

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    
    @IBOutlet weak var sharingDetailLabel: UILabel!
    
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var logOutButton: UIButton!
    
    var justLoaded: Bool!
    var haveUserDataset = false
    var timeoutInUpdateUI = false
    
    // let firebaseRootRef = Firebase(url: "https://glowing-inferno-7505.firebaseio.com")
    let firebaseRootRef = FIRDatabase.database().reference()
    
    // for the activity indicator
    let activityIndicator = UIActivityIndicatorView()
    let overlay = UIView()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        justLoaded = true
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let currentUser = FIRAuth.auth()?.currentUser
        {
            updateUI(uid: currentUser.uid, shouldReload: false)
        }
        
        /*
        let currentUser = PFUser.currentUser()
        if currentUser != nil
        {
            if let userName: String = currentUser?.objectForKey("name") as? String
            {
                userLabel.text = userName
            }
            else
            {
                fetchFacebookInfoAsync()
            }
            
            if let userPhoto: String = currentUser?.objectForKey("photo") as? String
            {
                let url = URL(string: userPhoto)
                
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
                {
                    if let data = NSData(contentsOfURL: url!)
                    {
                        dispatch_async(dispatch_get_main_queue())
                        {
                            self.userImage.alpha = 0
                            self.userImage.image = UIImage(data: data)
                            UIView.animateWithDuration(0.5, delay: 0.25, options: UIViewAnimationOptions.CurveEaseIn, animations:
                            {
                                self.userImage.alpha = 1
                            }, completion: nil)
                        }
                    }
                    else
                    {
                        self.fetchFacebookPictureAsync()
                    }
                }
            }
            else
            {
                fetchFacebookPictureAsync()
            }
            
            if let userSharingSetting: String = currentUser?.objectForKey("sharing") as? String
            {
                sharingDetailLabel.text = userSharingSetting
            }
            else
            {
                sharingDetailLabel.text = "Private"
            }
        }
        */
    }
    
    func updateUI(uid: String, shouldReload: Bool)
    {
        showActivityIndicator(shouldShow: true)
        
        // 10 seconds? Maybe longer?
        let timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(SocialTableViewController.removeFirebaseObserver), userInfo: nil, repeats: false)
        
        firebaseRootRef.child("users/\(uid)/info").observeSingleEvent(of: .value, with:
        {
            snapshot in
            
            timer.invalidate()
            
            if snapshot.value is NSNull
            {
                // self.firebaseRootRef.unauth()
                try! FIRAuth.auth()!.signOut()
                FBSDKLoginManager().logOut()
                
                DispatchQueue.main.async
                {
                    self.tableView.reloadData()
                    
                    if self.activityIndicator.isAnimating
                    {
                        self.showActivityIndicator(shouldShow: false)
                    }
                    
                    // "Mistakes were made."
                    self.presentAlert(message: "Something has gone terribly wrong. Sorry! Please log back in.")
                }
            }
            else
            {
                // update the name and photo if they haven't been updated recently?
                
                // should probably do this as if let and handle the failure
                // handle by fetching everything?
                let snapshotValue = snapshot.value as! NSDictionary
                
                // if let name = snapshot.value["name"] as? String
                if let name = snapshotValue["name"] as? String
                {
                    DispatchQueue.main.async
                    {
                        self.userLabel.text = name
                    }
                }
                else
                {
                    // in practice, I don't think this will get called
                    self.fetchFacebookInfo(uid: uid)
                }
            
                // photoSquare? photoDefault?
                // if let photo = snapshot.value["photoSquare"] as? String
                if let photo = snapshotValue["photoSquare"] as? String
                {
                    let url = URL(string: photo)
                
                    DispatchQueue.global(qos: .utility).async
                    {
                        do
                        {
                            let data = try Data(contentsOf: url!)
                            
                            DispatchQueue.main.async
                            {
                                self.userImage.alpha = 0
                                self.userImage.image = UIImage(data: data)
                                
                                UIView.animate(withDuration: 0.5, delay: 0.25, options: UIViewAnimationOptions.curveEaseIn, animations:
                                {
                                    self.userImage.alpha = 1
                                },
                                completion: nil)
                            }
                        }
                        catch let error
                        {
                            print("error in updateUI: \(error)")
                            
                            self.fetchFacebookPicture(uid: uid)
                            
                            // what if the problem is that there's no internet access?
                        }
                    }
                }
                else
                {
                    self.fetchFacebookPicture(uid: uid)
                }
                    
                DispatchQueue.main.async
                {
                    // if let sharingSetting = snapshot.value["sharing"] as? String
                    if let sharingSetting = snapshotValue["sharing"] as? String
                    {
                        self.sharingDetailLabel.text = sharingSetting
                    }
                    else
                    {
                        self.sharingDetailLabel.text = "Private"
                        
                        let data = ["sharing": "Private"]
                    
                        self.firebaseRootRef.child("users/\(uid)/info").updateChildValues(data)
                    }
                    
                    if shouldReload == true
                    {
                        self.tableView.reloadData()
                    }
                    
                    if self.activityIndicator.isAnimating
                    {
                        self.showActivityIndicator(shouldShow: false)
                    }
                }
            }
        })
    }
    
    func removeFirebaseObserver()
    {
        print("updateUI timed out")
        
        // firebaseRootRef.removeAllObservers()
        if let currentUser = FIRAuth.auth()?.currentUser
        {
            firebaseRootRef.child("users/\(currentUser.uid)/info").removeAllObservers()
        }
        
        timeoutInUpdateUI = true
        
        DispatchQueue.main.async
        {
            self.tableView.reloadData()
            
            if self.activityIndicator.isAnimating
            {
                self.showActivityIndicator(shouldShow: false)
            }
            
            self.timeoutInUpdateUI = false
        }
    }
    
    @IBAction func cancelSharingSelection(_ segue:UIStoryboardSegue)
    {
        // Do nothing.
    }
    
    @IBAction func saveSharingSelection(_ segue:UIStoryboardSegue)
    {
        if let sharingTableViewController = segue.source as? SharingTableViewController
        {
            if sharingTableViewController.selectedSharingOptionIndex == 0
            {
                sharingDetailLabel.text = "Private"
            }
            else if sharingTableViewController.selectedSharingOptionIndex == 1
            {
                sharingDetailLabel.text = "Friends"
            }
            else
            {
                sharingDetailLabel.text = "Public"
            }
        }
        
        /*
        let currentUser = PFUser.currentUser()
        if currentUser != nil
        {
            if let userSharingSetting: String = currentUser?.objectForKey("sharing") as? String
            {
                sharingDetailLabel.text = userSharingSetting
            }
        }
        */
    }
    
    func presentAlert(message: String)
    {
        // title: "Error"?
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
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
        // return 4
        
        if FIRAuth.auth()?.currentUser != nil
        {
            return 5
        }
        else
        {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if FIRAuth.auth()?.currentUser != nil
        {
            if section == 0
            {
                return 0
            }
            else if section == 4
            {
                return 1
            }
            
            if timeoutInUpdateUI == false
            {
                if section == 3
                {
                    return 0
                }
                else
                {
                    return 1
                }
            }
            else
            {
                if section == 1 || section == 2
                {
                    return 0
                }
                else
                {
                    return 1
                }
            }
        }
        else
        {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if FIRAuth.auth()?.currentUser != nil
        {
            if section == 0
            {
                return CGFloat.leastNormalMagnitude
            }
            else if section == 4
            {
                return UITableViewAutomaticDimension
            }
            
            if timeoutInUpdateUI == false
            {
                if section == 1
                {
                    if justLoaded == true
                    {
                        return CGFloat.leastNormalMagnitude + 35
                    }
                    else
                    {
                        return CGFloat.leastNormalMagnitude
                    }
                }
                else if section == 3
                {
                    return CGFloat.leastNormalMagnitude
                }
                else
                {
                    return UITableViewAutomaticDimension
                }
            }
            else
            {
                if section == 1 || section == 2
                {
                    return CGFloat.leastNormalMagnitude
                }
                else
                {
                    return CGFloat.leastNormalMagnitude + 35
                }
            }
        }
        else
        {
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        if FIRAuth.auth()?.currentUser != nil
        {
            if section == 0
            {
                return CGFloat.leastNormalMagnitude
            }
            else if section == 4
            {
                return UITableViewAutomaticDimension
            }
            
            if timeoutInUpdateUI == false
            {
                if section == 3
                {
                    return CGFloat.leastNormalMagnitude
                }
                else
                {
                    return UITableViewAutomaticDimension
                }
            }
            else
            {
                if section == 1 || section == 2
                {
                    return CGFloat.leastNormalMagnitude
                }
                else
                {
                    return UITableViewAutomaticDimension
                }
            }
        }
        else
        {
            return UITableViewAutomaticDimension
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // currently, there's only one cell in each of these sections
        if indexPath.section == 0
        {
            logInTouched(logInButton)
        }
        else if indexPath.section == 3
        {
            if let currentUser = FIRAuth.auth()?.currentUser
            {
                updateUI(uid: currentUser.uid, shouldReload: true)
            }
            else
            {
                tableView.reloadData()
            
                presentAlert(message: "Sorry, but it looks like you're no longer logged in. Please log back in if you'd like.")
            }
        }
        else if indexPath.section == 4
        {
            logOutTouched(logOutButton)
        }
    }
    
    @IBAction func logInTouched(_ sender: UIButton)
    {
        showActivityIndicator(shouldShow: true)
        
        justLoaded = false
        
        let permissions = ["public_profile", "user_friends", "email"]
        
        let loginManager = FBSDKLoginManager()
        
        loginManager.logIn(withReadPermissions: permissions, from: self, handler:
        {
            (result, error) -> Void in
            
            if error != nil
            {
                print("Facebook login error: \(error)")
                
                DispatchQueue.main.async
                {
                    self.showActivityIndicator(shouldShow: false)
                    
                    self.presentAlert(message: "There was a problem logging in to Facebook. Please try logging in again if you'd like.")
                }
            }
            else if result?.isCancelled == true
            {
                print("Facebook login canceled")
                
                DispatchQueue.main.async
                {
                    self.showActivityIndicator(shouldShow: false)
                    
                    // no alert for this, I think
                }
            }
            else
            {
                print("Facebook login successful")
                
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                
                FIRAuth.auth()?.signIn(with: credential)
                {
                    (user, error) in
                    
                    if error != nil
                    {
                        print("Firebase login failed: \(error)")
                        
                        FBSDKLoginManager().logOut()
                        
                        DispatchQueue.main.async
                        {
                            self.showActivityIndicator(shouldShow: false)
                            
                            // problem instead of error?
                            self.presentAlert(message: "There was an error during login. Sorry! Please try logging in again if you'd like.")
                        }
                    }
                    else if user == nil
                    {
                        // same stuff as error != nil except that I probably also need to log out the user
                        // or maybe I can just "try" logging the user out above
                    }
                    else
                    {
                        print("Firebase login successful: \(user)")
                        
                        // 10 seconds? Maybe longer?
                        let timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(SocialTableViewController.removeFirebaseObserverAndLogOut), userInfo: nil, repeats: false)
                        
                        // user is not nil (see above)
                        self.firebaseRootRef.child("users/\(user!.uid)/info").observeSingleEvent(of: .value, with:
                        {
                            snapshot in
                                
                            timer.invalidate()
                                
                            if snapshot.value is NSNull
                            {
                                print("new user")
                                    
                                self.sharingDetailLabel.text = "Private"
                                    
                                let data = ["sharing" : "Private"]
                                    
                                self.firebaseRootRef.child("users/\(user!.uid)/info").updateChildValues(data)
                            }
                            else
                            {
                                print("old user")
                                    
                                // should probably do this as if let and handle the failure
                                let snapshotValue = snapshot.value as! NSDictionary
                                    
                                // if let sharingSetting = snapshot.value["sharing"] as? String
                                if let sharingSetting = snapshotValue["sharing"] as? String
                                {
                                    self.sharingDetailLabel.text = sharingSetting
                                }
                                else
                                {
                                    self.sharingDetailLabel.text = "Private"
                                
                                    let data = ["sharing": "Private"]
                                        
                                    self.firebaseRootRef.child("users/\(user!.uid)/info").updateChildValues(data)
                                }
                            }
                            
                            if user!.providerData.count != 0
                            {
                                // Facebook should be the only provider
                                let profile = user!.providerData[0]
                                
                                var userDictionary = [String: String]()
                                
                                userDictionary["facebookID"] = profile.uid
                                
                                if let url = profile.photoURL?.absoluteString
                                {
                                    userDictionary["photoDefault"] = url
                                }
                                
                                if let name = profile.displayName
                                {
                                    userDictionary["name"] = name
                                    
                                    self.userLabel.text = name
                                }
                                else
                                {
                                    // in practice, I don't think this will get called
                                    self.fetchFacebookInfo(uid: user!.uid)
                                }
                                
                                self.firebaseRootRef.child("users/\(user!.uid)/info").updateChildValues(userDictionary)
                                
                                self.fetchFacebookPicture(uid: user!.uid)
                            }
                            else
                            {
                                // considering I just logged in with Facebook, this code should never be reached
                            }
                            
                            DispatchQueue.main.async
                            {
                                self.tableView.reloadData()
                                    
                                if self.activityIndicator.isAnimating
                                {
                                    self.showActivityIndicator(shouldShow: false)
                                }
                            }
                        })
                    }
                }
            }
        })

        /*
        PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions, block:
        {
            (user: PFUser?, error: NSError?) -> Void in
                
            if let user = user
            {
                if user.isNew
                {
                    print("User signed up and logged in through Facebook!")
                        
                    self.fetchFacebookInfoAsync()
                    self.fetchFacebookPictureAsync()
                }
                else
                {
                    print("User logged in through Facebook!")
                        
                    if let userName: String = user.objectForKey("name") as? String
                    {
                        self.userLabel.text = userName
                    }
                    else
                    {
                        self.fetchFacebookInfoAsync()
                    }
                        
                    if let userPhoto: String = user.objectForKey("photo") as? String
                    {
                        let url = URL(string: userPhoto)
                        
                        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
                        {
                            if let data = NSData(contentsOfURL: url!)
                            {
                                dispatch_async(dispatch_get_main_queue())
                                {
                                    self.userImage.alpha = 0
                                    self.userImage.image = UIImage(data: data)
                                    UIView.animateWithDuration(0.5, delay: 0.25, options: UIViewAnimationOptions.CurveEaseIn, animations:
                                    {
                                        self.userImage.alpha = 1
                                    }, completion: nil)
                                }
                            }
                            else
                            {
                                self.fetchFacebookPictureAsync()
                            }
                        }
                    }
                    else
                    {
                        self.fetchFacebookPictureAsync()
                    }
                }
                
                if let userSharingSetting: String = user.objectForKey("sharing") as? String
                {
                    self.sharingDetailLabel.text = userSharingSetting
                }
                else
                {
                    self.sharingDetailLabel.text = "Private"
                }
                
                // Update UI.
                self.tableView.reloadData()
                
                // Run Cloud Code anyway?
            }
            else
            {
                print("Uh oh. The user cancelled the Facebook login.")
                    
                // Make sure the UI looks right. Maybe an alert?
            }
        })
        */
    }

    @IBAction func logOutTouched(_ sender: UIButton)
    {
        // PFUser.logOut()
        
        // firebaseRootRef.unauth()
        try! FIRAuth.auth()!.signOut()
        FBSDKLoginManager().logOut()
        
        // Testing.
        print("logged out")
        
        // Update UI.
        tableView.reloadData()
    }
    
    func fetchFacebookInfo(uid: String)
    {
        DispatchQueue.main.async
        {
            let request: FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "/me?fields=id,name", parameters: nil, httpMethod: "GET")
            
            request.start(completionHandler:
            {
                (connection, result, error) -> Void in
                
                guard error == nil,
                    let resultDictionary = result as? NSDictionary,
                    let id = resultDictionary.object(forKey: "id") as? String,
                    let name = resultDictionary.object(forKey: "name") as? String
                else
                {
                    if error != nil
                    {
                        print("error in fetchFacebookInfo: \(error!)")
                    }
                    else
                    {
                        print("error in fetchFacebookInfo: could not unwrap result")
                    }
                    
                    self.presentAlert(message: "There was a problem fetching some of your data from Facebook. We'll try again later.")
                    
                    // this setting is checked in MainPageVC
                    // no need to worry about whether it's the same user
                    // there's no harm in unnecessarily calling the function
                    let defaults = UserDefaults.standard
                    defaults.set(true, forKey: "fetchFacebookInfo")
                    
                    return
                }
                
                let data = ["facebookID": id, "name": name]
                
                self.firebaseRootRef.child("users/\(uid)/info").updateChildValues(data)
                
                DispatchQueue.main.async
                {
                    self.userLabel.text = name
                }
            })
        }
    }
    
    func fetchFacebookPicture(uid: String)
    {
        DispatchQueue.main.async
        {
            let request: FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "/me/picture?fields=url&width=150&height=150&redirect=false", parameters: nil, httpMethod: "GET")
            
            request.start(completionHandler:
            {
                (connection, result, error) -> Void in
                
                guard error == nil,
                    let resultDictionary = result as? NSDictionary,
                    let data = resultDictionary.object(forKey: "data") as? NSDictionary,
                    let urlString = data.object(forKey: "url") as? String
                else
                {
                    if error != nil
                    {
                        print("error in fetchFacebookPicture: \(error!)")
                    }
                    else
                    {
                        print("error in fetchFacebookPicture: could not unwrap result")
                    }
                        
                    self.presentAlert(message: "There was a problem fetching some of your data from Facebook. We'll try again later.")
                            
                    // this setting is checked in MainPageVC
                    // no need to worry about whether it's the same user
                    // there's no harm in unnecessarily calling the function
                    let defaults = UserDefaults.standard
                    defaults.set(true, forKey: "fetchFacebookPicture")
                        
                    return
                }
        
                let firebaseData = ["photoSquare": urlString]
        
                self.firebaseRootRef.child("users/\(uid)/info").updateChildValues(firebaseData)
                
                let url = URL(string: urlString)
                
                DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async
                {
                    do
                    {
                        let photoData = try Data(contentsOf: url!)
                        
                        DispatchQueue.main.async
                        {
                            self.userImage.alpha = 0
                            self.userImage.image = UIImage(data: photoData)
                                
                            UIView.animate(withDuration: 0.5, delay: 0.25, options: UIViewAnimationOptions.curveEaseIn, animations:
                            {
                                self.userImage.alpha = 1
                            },
                            completion: nil)
                        }
                    }
                    catch let error
                    {
                        print("error in fetchFacebookPicture: \(error)")
                        
                        self.presentAlert(message: "There was a problem loading some of your data. Sorry!")
                        
                        // No need to try again (now or later).
                        // If the error was due to a lack of internet access, there's nothing I can do or need to do at the moment.
                        // If the error was due to the URL, it'll get resolved next time updateUI is called. It can also be resolved by another user viewing the current user's drinks. See updateFriendPhoto in FriendsTVC.
                    }
                }
            })
        }
    }
    
    func removeFirebaseObserverAndLogOut()
    {
        print("checking for existing Firebase user timed out")
        
        // firebaseRootRef.removeAllObservers()
        if let currentUser = FIRAuth.auth()?.currentUser
        {
            firebaseRootRef.child("users/\(currentUser.uid)/info").removeAllObservers()
        }
        
        // firebaseRootRef.unauth()
        try! FIRAuth.auth()!.signOut()
        FBSDKLoginManager().logOut()
        
        DispatchQueue.main.async
        {
            self.showActivityIndicator(shouldShow: false)
                
            // problem instead of error?
            self.presentAlert(message: "There was an error during login. Sorry! Please try logging in again if you'd like.")
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "SharingSelection"
        {
            if let sharingTableViewController = segue.destination as? SharingTableViewController
            {
                if sharingDetailLabel.text == "Private"
                {
                    sharingTableViewController.selectedSharingOptionIndex = 0
                }
                else if sharingDetailLabel.text == "Friends"
                {
                    sharingTableViewController.selectedSharingOptionIndex = 1
                }
                else if sharingDetailLabel.text == "Public"
                {
                    sharingTableViewController.selectedSharingOptionIndex = 2
                }
            }
        }
    }

}
