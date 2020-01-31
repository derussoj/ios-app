//
//  SharingTableViewController.swift
//  Cheers
//
//  Created by John DeRusso on 10/3/15.
//  Copyright © 2015 Cheers. All rights reserved.
//

import UIKit
import Firebase

class SharingTableViewController: UITableViewController {

    var sharingOptions = ["Private", "Friends", "Public"]
    var selectedSharingOptionIndex: Int? = nil
    
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
        
        // ideally, the sharing setting is passed in from the SocialTVC
        if selectedSharingOptionIndex == nil
        {
            selectedSharingOptionIndex = 0
        }
        
        tableView.selectRow(at: IndexPath(row: selectedSharingOptionIndex!, section: 0), animated: false, scrollPosition: UITableViewScrollPosition.none)
        
        /*
        // shouldn't be able to reach this page w/o a currentUser
        if let currentUser = PFUser.currentUser()
        {
            if let userSharingSetting: String = currentUser.objectForKey("sharing") as? String
            {
                selectedSharingOptionIndex = sharingOptions.indexOf(userSharingSetting)
            }
            else
            {
                selectedSharingOptionIndex = 0
            }
        }
        
        if selectedSharingOptionIndex != nil
        {
            tableView.selectRowAtIndexPath(NSIndexPath(forRow: selectedSharingOptionIndex!, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
        }
        */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // no longer used
    @IBAction func doneAction(_ sender: UIBarButtonItem)
    {
        // shouldn't be able to reach this page w/o a user
        if let user = FIRAuth.auth()?.currentUser
        {
            // should never be nil?
            if selectedSharingOptionIndex != nil
            {
                let selectedOption = sharingOptions[selectedSharingOptionIndex!]
                
                let data = ["sharing": selectedOption]
                
                self.firebaseRootRef.child("users/\(user.uid)/info").updateChildValues(data)
                
                self.performSegue(withIdentifier: "SaveSharingSelection", sender: self)
            }
            else
            {
                // Alert.
                // Please select an option.
            }
        }
        else
        {
            // Alert.
            // You need to be logged in to select an option. Honestly, we're not sure how you reached this page without being logged in.
        }
        
        /*
        // shouldn't be able to reach this page w/o a currentUser
        let currentUser = PFUser.currentUser()
        if currentUser != nil
        {
            // should never be nil?
            if selectedSharingOptionIndex != nil
            {
                // if the selected setting is equal to the current setting, just segue?
                
                showActivityIndicator(true)
                
                currentUser?.setObject(sharingOptions[selectedSharingOptionIndex!], forKey: "sharing")
                
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))
                {
                    do
                    {
                        try currentUser?.save()
                        
                        sleep(3)
                    }
                    catch
                    {
                        currentUser?.saveEventually()
                    }
                    
                    dispatch_async(dispatch_get_main_queue())
                    {
                        self.showActivityIndicator(false)
                        
                        self.performSegueWithIdentifier("SaveSharingSelection", sender: self)
                    }
                }
            }
            else
            {
                // Alert.
                // Please select an option.
            }
        }
        */
    }
    
    // no longer used
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
            
            navigationController?.tabBarController?.view.addSubview(overlay)
        }
        else
        {
            overlay.removeFromSuperview()
            
            activityIndicator.stopAnimating()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return sharingOptions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SharingOptionCell", for: indexPath)

        cell.textLabel?.text = sharingOptions[indexPath.row]
        
        if indexPath.row == selectedSharingOptionIndex
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
        if let index = selectedSharingOptionIndex
        {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
            cell?.accessoryType = .none
        }
        
        selectedSharingOptionIndex = indexPath.row
        
        // sets new checkmark
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if identifier == "SaveSharingSelection"
        {
            // shouldn't be able to reach this page w/o a user
            if FIRAuth.auth()?.currentUser != nil
            {
                // should never be nil?
                if selectedSharingOptionIndex != nil
                {
                    return true
                }
                else
                {
                    presentAlert(message: "Please select an option. If you don't want to make any changes, you can hit cancel.")
                    
                    return false
                }
            }
            else
            {
                presentAlert(message: "You need to be logged in to select an option. Honestly, we're not really sure how you reached this page without being logged in.")
                
                return false
            }
        }
        else
        {
            return true
        }
    }
    
    func presentAlert(message: String)
    {
        // title: "Error"?
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "SaveSharingSelection"
        {
            // the existence of selectedSharingOptionIndex should be guaranteed by shouldPerformSegue()
            let selectedOption = sharingOptions[selectedSharingOptionIndex!]
            
            let data = ["sharing": selectedOption]
            
            // the existence of currentUser should be guaranteed by shouldPerformSegue()
            let userID = FIRAuth.auth()!.currentUser!.uid
            
            firebaseRootRef.child("users/\(userID)/info").updateChildValues(data)
        }
    }

}
