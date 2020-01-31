//
//  FriendDrinkDetailsTableViewController.swift
//  Cheers
//
//  Created by Air on 6/14/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import Parse

class FriendDrinkDetailsTableViewController: UITableViewController, UITextViewDelegate
{
    var friendDrinkEntry: ParseDrinkEntry!
    var selectedDrink: FirebaseDrink!
    var friendPhoto: UIImage?
    
    var likeCount: Int?
    // better name? optional?
    var drinkEntryLiked: Bool?
    
    var comments = [ParseComment]()
    
    var commentText: String?
    
    var messageText = String()
    
    // optional array? empty array?
    // using an empty array seems simpler
    // var status: [String]?
    var status = [String]()
    
    var editingComment = false
    var commentIndexPath: IndexPath?
    var editedCommentText: String?
    
    // for the activity indicator
    let activityIndicator = UIActivityIndicatorView()
    let overlay = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FriendDrinkDetailsTableViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        refreshControl?.addTarget(self, action: #selector(FriendDrinkDetailsTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        // other stuff from the beer search page?
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
        
        refreshControl?.beginRefreshing()
        
        // the first parameter is fetchingComments
        fetchLikes(fetchingComments: true, usingActivityIndicator: false)
    }
    
    func hideKeyboard()
    {
        tableView.endEditing(true)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl)
    {
        // the first parameter is fetchingComments
        fetchLikes(fetchingComments: true, usingActivityIndicator: false)
    }
    
    func fetchLikes(fetchingComments: Bool, usingActivityIndicator: Bool)
    {
        let query = PFQuery(className: "ParseLike")
        // query.whereKey("drinkEntry", equalTo: ParseDrinkEntry(withoutDataWithObjectId: friendDrinkEntry.objectId))
        query.whereKey("drinkEntry", equalTo: ParseDrinkEntry(outDataWithObjectId: friendDrinkEntry.objectId))
        query.includeKey("liker")

        DispatchQueue.global(qos: .userInitiated).async
        {
            do
            {
                if let results = try query.findObjects() as? [ParseLike]
                {
                    DispatchQueue.main.async
                    {
                        self.likeCount = results.count
                        
                        if let currentUser = PFUser.current()
                        {
                            self.drinkEntryLiked = false
                            
                            for result in results
                            {
                                if result.liker == currentUser
                                {
                                    self.drinkEntryLiked = true
                                }
                            }
                        }
                        else
                        {
                            // leave variable as nil (set to nil if it wasn't previously nil? yes!)
                            // in this case, nil means idk
                            // useful below when the user tries to save a like
                        }
                        
                        if fetchingComments == false
                        {
                            let likesCellIndexPath = IndexPath(row: 3, section: 2)
                            self.tableView.reloadRows(at: [likesCellIndexPath], with: UITableViewRowAnimation.none)
                        }
                    }
                }
                else
                {
                    DispatchQueue.main.async
                    {
                        // Not sure how I would actually reach this code.
                        
                        self.status.append("casting error in fetchLikes")
                    }
                }
            }
            catch let error as NSError
            {
                DispatchQueue.main.async
                {
                    // error? error.description?
                    print(error)
                    
                    self.status.append("query error in fetchLikes")
                }
            }
            
            DispatchQueue.main.async
            {
                if fetchingComments == true
                {
                    // presentAlert, showActivityIndicator/refreshControl.endRefreshing and tableView.reloadData are always called in fetchComments
                    self.fetchComments(usingActivityIndicator: usingActivityIndicator)
                }
                else
                {
                    // when there are no errors, the likes cell is reloaded above
                    // otherwise, there is no need to reload the likes cell (or the table)
                    
                    if usingActivityIndicator == true
                    {
                        self.showActivityIndicator(shouldShow: false)
                    }
                    else
                    {
                        self.refreshControl?.endRefreshing()
                    }
                    
                    // no alert shown when no errors
                    self.presentAlert()
                }
            }
        }
    }
    
    func fetchComments(usingActivityIndicator: Bool)
    {
        let query = PFQuery(className: "ParseComment")
        // query.whereKey("drinkEntry", equalTo: ParseDrinkEntry(withoutDataWithObjectId: friendDrinkEntry.objectId))
        query.whereKey("drinkEntry", equalTo: ParseDrinkEntry(outDataWithObjectId: friendDrinkEntry.objectId))
        query.includeKey("commenter")
        query.order(byAscending: "universalDateTime")
        
        DispatchQueue.global(qos: .userInitiated).async
        {
            do
            {
                if let results = try query.findObjects() as? [ParseComment]
                {
                    self.comments = results
                }
                else
                {
                    self.status.append("casting error in fetchComments")
                }
            }
            catch let error as NSError
            {
                // error? error.description?
                print(error)
                
                self.status.append("query error in fetchComments")
            }
            
            DispatchQueue.main.async
            {
                // this is used to refresh the likes cell as well
                self.tableView.reloadData()
                
                if usingActivityIndicator == true
                {
                    self.showActivityIndicator(shouldShow: false)
                }
                else
                {
                    self.refreshControl?.endRefreshing()
                }
                
                self.presentAlert()
            }
        }
    }
    
    func presentAlert()
    {
        // alert based on status
        
        if status.count > 0
        {
            if status.contains("casting error in fetchLikes") || status.contains("query error in fetchLikes")
            {
                // "To be honest, we're not really sure what happened. Please try again. Or maybe pull down to refresh? And then try again?"
                // If saving/deleting was successful... "Well, the good news is that we saved your change. However, there was an error fetching up-to-date data. Please trying pulling down to refresh."
                // Can this code even be reached when saving/deleting is unsuccessful? At the moment but not eventually.
                
                // If saving/deleting was successful... "Well, the good news is that we saved your change. However, there was an error fetching up-to-date data. Please trying pulling down to refresh."
                // Can this code even be reached when saving/deleting is unsuccessful? At the moment yes but not eventually.
            }
            
            status = []
        }
    }
    
    @IBAction func likeButtonTouchUpInside(_ sender: UIButton)
    {
        if PFUser.current() != nil
        {
            if drinkEntryLiked != nil
            {
                showActivityIndicator(shouldShow: true)
                
                if drinkEntryLiked == true
                {
                    deleteLike(sender: sender)
                }
                else
                {
                    saveLike(sender: sender)
                }
            }
            else
            {
                // Alert?
                // We weren't or haven't yet been able to determine whether you already liked this drink.
                // Try refetching the likes before showing the error?
                // Ask the user to pull to refresh?
            }
        }
        else
        {
            // Alert.
            // "You must be logged in to like a drink."
            // You don't need to be logged in to see public drinks so you can still reach this point.
        }
    }
    
    func saveLike(sender: UIButton)
    {
        let like = ParseLike()
        
        // like.drinkEntry = ParseDrinkEntry(withoutDataWithObjectId: friendDrinkEntry.objectId)
        like.drinkEntry = ParseDrinkEntry(outDataWithObjectId: friendDrinkEntry.objectId)
        like.drinkEntryOwner = friendDrinkEntry.parseUser

        // already checked for nil in likeButtonTouchUpInside
        like.liker = PFUser.current()!
        like.universalDateTime = Date()
        // leave like.localDateTime empty?
        
        DispatchQueue.global(qos: .userInitiated).async
        {
            do
            {
                try like.save()
                
                self.status.append("like saved")
                
                DispatchQueue.main.async
                {
                    // everything is updated in fetchLikes (label, button, variables, activity indicator)
                        
                    // the first parameter is fetchingComments
                    self.fetchLikes(fetchingComments: false, usingActivityIndicator: true)
                }
            }
            catch
            {
                // like.saveEventually()
                // self.status.append("like saved eventually")
                
                // this way makes it easier to keep the UI accurate and handle other errors
                // probably more intuitive for the user too
                
                DispatchQueue.main.async
                {
                    // Alert.
                }
            }
        }
    }
    
    func deleteLike(sender: UIButton)
    {
        let query = PFQuery(className: "ParseLike")
        // query.whereKey("drinkEntry", equalTo: ParseDrinkEntry(withoutDataWithObjectId: friendDrinkEntry.objectId))
        query.whereKey("drinkEntry", equalTo: ParseDrinkEntry(outDataWithObjectId: friendDrinkEntry.objectId))
        // already checked for nil in likeButtonTouchUpInside
        query.whereKey("liker", equalTo: PFUser.current()!)
        
        DispatchQueue.global(qos: .userInitiated).async
        {
            do
            {
                // when deleting, it's probably best to try to delete all of that user's likes in case something went wrong and there's more than one
                
                if let results = try query.findObjects() as? [ParseLike]
                {
                    var successfulDeletion = true
                    
                    for result in results
                    {
                        do
                        {
                            try result.delete()
                        }
                        catch
                        {
                            // result.deleteEventually()
                            // self.status.append("like deleted eventually")
                            
                            // Using deleteEventually results in the UI being updated (via fetchLikes) prior to the like being deleted. As a result, the UI is inaccurate and requires manual updating.
                            
                            successfulDeletion = false
                        }
                    }
                    
                    if successfulDeletion == false
                    {
                        // Alert.
                    }
                    else
                    {
                        self.status.append("like(s) deleted")
                        
                        DispatchQueue.main.async
                        {
                            // everything is updated in fetchLikes (label, button, variables, activity indicator)
                                
                            // the first parameter is fetchingComments
                            self.fetchLikes(fetchingComments: false, usingActivityIndicator: true)
                        }
                    }
                }
                else
                {
                    DispatchQueue.main.async
                    {
                        // Not sure how I would actually reach this code.
                        
                        self.showActivityIndicator(shouldShow: false)
                        
                        // Alert.
                        // "Something has gone terribly wrong. Try again maybe?"
                    }
                }
            }
            catch let error as NSError
            {
                DispatchQueue.main.async
                {
                    // error? error.description?
                    print(error)
                    
                    self.showActivityIndicator(shouldShow: false)
                    
                    // Alert.
                }
            }
        }
    }
    
    @IBAction func saveButtonTouchUpInside(_ sender: UIButton)
    {
        if let currentUser = PFUser.current()
        {
            if commentText == nil
            {
                // Alert.
            }
            else
            {
                showActivityIndicator(shouldShow: true)
                
                let comment = ParseComment()
                
                // comment.drinkEntry = ParseDrinkEntry(withoutDataWithObjectId: friendDrinkEntry.objectId)
                comment.drinkEntry = ParseDrinkEntry(outDataWithObjectId: friendDrinkEntry.objectId)
                comment.drinkEntryOwner = friendDrinkEntry.parseUser
                
                comment.commenter = currentUser
                comment.text = commentText!
                comment.universalDateTime = Date()
                // leave comment.localDateTime empty?
                
                DispatchQueue.global(qos: .userInitiated).async
                {
                    do
                    {
                        try comment.save()
                        
                        self.status.append("comment saved")
                        
                        DispatchQueue.main.async
                        {
                            if let cell = sender.superview?.superview as? FDDAddCommentTableViewCell
                            {
                                cell.addCommentTextView.text = String()
                                
                                cell.addCommentTextView.textColor = UIColor.lightGray
                                    
                                cell.addCommentTextView.text = "Add Comment"
                                    
                                self.commentText = nil
                            }
                                
                            // everything is updated in fetchComments (comment cells, tableView.reloadData, showActivityIndicator)
                                
                            // the parameter is usingActivityIndicator
                            self.fetchComments(usingActivityIndicator: true)
                        }
                    }
                    catch
                    {
                        // comment.saveEventually()
                        // self.status.append("comment saved eventually")
                        
                        // this way makes it easier to handle other errors
                        // probably more intuitive for the user too
                        // would be weird for everyone involved to have a comment show up hours later
                        
                        DispatchQueue.main.async
                        {
                            // Alert.
                        }
                    }
                }
            }
        }
        else
        {
            // Alert.
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
    
    @IBAction func moreButtonTouchUpInside(_ sender: UIButton)
    {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.deleteComment(sender: sender)
        }
        alertController.addAction(deleteAction)
        
        let editAction = UIAlertAction(title: "Edit", style: .default) { (action) in
            self.editComment(sender: sender)
        }
        alertController.addAction(editAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func deleteComment(sender: UIButton)
    {
        // this button should only be visible for the user's own comments
        // hide in cellForRowAtIndexPath? different custom cell?
        
        if let currentUser = PFUser.current()
        {
            if let cell = sender.superview?.superview as? FDDCommentTableViewCell
            {
                if cell.comment.commenter == currentUser
                {
                    showActivityIndicator(shouldShow: true)
                        
                    DispatchQueue.global(qos: .userInitiated).async
                    {
                        var successfulDelete = true
                        
                        do
                        {
                            try cell.comment.delete()
                            
                            self.status.append("comment deleted")
                        }
                        catch
                        {
                            // cell.comment.deleteEventually()
                            // self.status.append("comment deleted eventually")
                            
                            // this way makes it easier to handle other errors
                            // probably more intuitive for the user too
                            // deleting comments can mess with everyone involved
                            // having them deleted at an indeterminate time is probably worse
                            // if the user wants it gone, they can get some internet access
                            
                            successfulDelete = false
                            
                            DispatchQueue.main.async
                            {
                                // Alert.
                            }
                        }
                        
                        if successfulDelete == true
                        {
                            DispatchQueue.main.async
                            {
                                // everything is updated in fetchComments (comment cells, tableView.reloadData, showActivityIndicator)
                                
                                // the parameter is usingActivityIndicator
                                self.fetchComments(usingActivityIndicator: true)
                            }
                        }
                    }
                }
                else
                {
                    // Alert.
                    
                    // Or maybe nothing here? Should be unreachable.
                    // On the one hand, pretty sure I have unreachable code above.
                    // On the other hand, I'm only handling 2/3 of the if statements here.
                }
            }
        }
        else
        {
            // Alert.
        }
    }
    
    func editComment(sender: UIButton)
    {
        if let cell = sender.superview?.superview as? FDDCommentTableViewCell
        {
            if let indexPath = tableView.indexPath(for: cell)
            {
                editingComment = true
                commentIndexPath = indexPath
                
                let comment = comments[indexPath.row]
                
                editedCommentText = comment.text
                
                comments.remove(at: indexPath.row)
                
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.left)
                
                comments.append(comment)

                tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.right)
                
                // set the text view as active?
                // i.e., show the cursor and keyboard
                // that might be too much after the cell animation
                // and probably unnecessary
            }
        }
        
        // alert for either of the potential else statements?
        // neither should be able to fail, right?
    }
    
    @IBAction func saveEditTouchUpInside(_ sender: UIButton)
    {
        if PFUser.current() != nil
        {
            if editedCommentText == nil
            {
                // Alert.
                // "Comment text is required. If you'd like to delete your comment, please hit cancel and then select delete."
            }
            else
            {
                if let cell = sender.superview?.superview as? FDDEditCommentTableViewCell
                {
                    if let indexPath = tableView.indexPath(for: cell)
                    {
                        showActivityIndicator(shouldShow: true)
                        
                        let comment = comments[indexPath.row]
                        
                        // check to make sure the comment.commenter is the current user?
                        
                        comment.text = editedCommentText!
                        // nothing else needs updating
                        
                        DispatchQueue.global(qos: .userInitiated).async
                        {
                            do
                            {
                                try comment.save()
                                
                                self.status.append("comment saved")
                                
                                DispatchQueue.main.async
                                {
                                    self.editingComment = false
                                    self.commentIndexPath = nil
                                    self.editedCommentText = nil
                                        
                                    // everything is updated in fetchComments (comment cells, tableView.reloadData, showActivityIndicator)
                                        
                                    // the parameter is usingActivityIndicator
                                    self.fetchComments(usingActivityIndicator: true)
                                }
                            }
                            catch
                            {
                                DispatchQueue.main.async
                                {
                                    // Alert.
                                }
                            }
                        }
                    }
                }
                
                // alert for either of the potential else statements?
                // neither should be able to fail, right?
            }
        }
        else
        {
            // Alert.
        }
    }
    
    @IBAction func cancelEditTouchUpInside(_ sender: UIButton)
    {
        if let cell = sender.superview?.superview as? FDDEditCommentTableViewCell
        {
            if let indexPath = tableView.indexPath(for: cell)
            {
                editingComment = false
                commentIndexPath = nil
                editedCommentText = nil
                
                let comment = comments[indexPath.row]
                
                comments.remove(at: indexPath.row)
                
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.right)
                
                comments.append(comment)
                
                tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.left)
            }
        }
    }
    
    func createIngredientsString() -> String
    {
        // Should always be at least 1 ingredient.
        var ingredientsString: String
        
        if let volume: Double = friendDrinkEntry.ingredients[0].parseIngredientVolume
        {
            if friendDrinkEntry.ingredients[0].parseIngredientUnits == 0
            {
                ingredientsString = "\(friendDrinkEntry.ingredients[0].parseIngredientName) (\(volume) oz)"
            }
            else
            {
                ingredientsString = "\(friendDrinkEntry.ingredients[0].parseIngredientName) (\(volume) ml)"
            }
        }
        else
        {
            ingredientsString = friendDrinkEntry.ingredients[0].parseIngredientName
        }
        
        var i = 1
        let n = friendDrinkEntry.ingredients.count
        while i < n
        {
            if let volume: Double = friendDrinkEntry.ingredients[i].parseIngredientVolume
            {
                if friendDrinkEntry.ingredients[i].parseIngredientUnits == 0
                {
                    ingredientsString = "\(ingredientsString)\n\(friendDrinkEntry.ingredients[i].parseIngredientName) (\(volume) oz)"
                }
                else
                {
                    ingredientsString = "\(ingredientsString)\n\(friendDrinkEntry.ingredients[i].parseIngredientName) (\(volume) ml)"
                }
            }
            else
            {
                ingredientsString = "\(ingredientsString)\n\(friendDrinkEntry.ingredients[i].parseIngredientName)"
            }
            
            i += 1
        }
        
        return ingredientsString
    }
    
    func createDateTimeString(dateTime: Date) -> String
    {
        let currentDateTime = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.system
        
        if NSCalendar.current.isDateInToday(dateTime)
        {
            dateFormatter.timeStyle = DateFormatter.Style.short
        }
        else if currentDateTime.timeIntervalSince(dateTime) < (60 * 60 * 24 * 6)
        {
            dateFormatter.dateFormat = "E, h:mm a"
        }
        else
        {
            dateFormatter.dateFormat = "M/d"
        }
        
        return dateFormatter.string(from: dateTime)
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        // tableView.estimatedRowHeight = textView.frame.height + 14
        
        let offset = tableView.contentOffset
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
        tableView.layer.removeAllAnimations()
        tableView.setContentOffset(offset, animated: false)
        
        // let indexPath = NSIndexPath(forRow: comments.count, inSection: 3)
        
        // tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        if let _ = textView.superview?.superview as? FDDAddCommentTableViewCell
        {
            if textView.text == "Add Comment" && commentText == nil
            {
                textView.text = String()
                
                textView.textColor = UIColor.black
            }
        }
        // FDDEditCommentTableViewCell
        else
        {
            if textView.text == "Add Comment" && editedCommentText == nil
            {
                textView.text = String()
                
                textView.textColor = UIColor.black
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView)
    {
        textView.text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let _ = textView.superview?.superview as? FDDAddCommentTableViewCell
        {
            if textView.text.isEmpty
            {
                textView.textColor = UIColor.lightGray
                
                textView.text = "Add Comment"
                
                commentText = nil
            }
            else
            {
                commentText = textView.text
            }
        }
        // FDDEditCommentTableViewCell
        else
        {
            if textView.text.isEmpty
            {
                textView.textColor = UIColor.lightGray
                
                textView.text = "Add Comment"
                
                editedCommentText = nil
            }
            else
            {
                editedCommentText = textView.text
            }
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return 1
        }
        else if section == 1
        {
            if friendDrinkEntry.type == "beer"
            {
                return 2
            }
            else if friendDrinkEntry.type == "wine"
            {
                return 3
            }
            else
            {
                // Should always have an entry mode here.
                if friendDrinkEntry.cocktailEntryMode == 1
                {
                    return 4
                }
                else
                {
                    return 1
                }
            }
        }
        else if section == 2
        {
            // date/time, location, caption, likes
            return 4
        }
        else
        {
            // should use comments.count instead of friendDrinkEntry.commentNumber
            // otherwise, there will be empty rows until comments are fetched
            
            if comments.count < 1
            {
                return 1
            }
            else
            {
                return comments.count + 1
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if indexPath.section == 0
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as! FDDFriendTableViewCell
            
            if friendPhoto != nil
            {
                cell.friendPhotoImageView.image = friendPhoto
            }
            else
            {
                if let photo = friendDrinkEntry.friendPhoto
                {
                    let url = URL(string: photo)
                    
                    DispatchQueue.global(qos: .utility).async
                    {
                        do
                        {
                            let data = try Data(contentsOf: url!)
                            
                            DispatchQueue.main.async
                            {
                                self.friendPhoto = UIImage(data: data)
                                
                                cell.friendPhotoImageView.alpha = 0
                                cell.friendPhotoImageView.image = UIImage(data: data)
                                    
                                UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations:
                                {
                                    cell.friendPhotoImageView.alpha = 1
                                },
                                completion: nil)
                            }
                        }
                        catch let error
                        {
                            print("error in cellForRowAt: \(error)")
                            
                            // refetch the photo, I guess
                            // what if the problem is that there's no internet access?
                        }
                    }
                }
            }
            
            if let friendName = friendDrinkEntry.friendName
            {
                cell.friendNameLabel.text = friendName
            }

            return cell
        }
        else if indexPath.section == 1
        {
            if indexPath.row == 0
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "NameCell", for: indexPath) as! FDDNameTableViewCell
                
                if friendDrinkEntry.type == "beer"
                {
                    cell.cellNameLabel.text = "Beer"
                    cell.drinkEntryNameLabel.text = friendDrinkEntry.beerName
                }
                else if friendDrinkEntry.type == "wine"
                {
                    cell.cellNameLabel.text = "Wine"
                    cell.drinkEntryNameLabel.text = friendDrinkEntry.wineName
                }
                else if friendDrinkEntry.type == "cocktail"
                {
                    cell.cellNameLabel.text = "Cocktail"
                    cell.drinkEntryNameLabel.text = friendDrinkEntry.displayName
                }
                else if friendDrinkEntry.type == "shot"
                {
                    cell.cellNameLabel.text = "Shot"
                    cell.drinkEntryNameLabel.text = friendDrinkEntry.displayName
                }
                
                return cell
            }
            else if indexPath.row == 1
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SourceCell", for: indexPath) as! FDDSourceTableViewCell
                
                if friendDrinkEntry.type == "beer"
                {
                    cell.cellSourceLabel.text = "Brewery"
                    cell.drinkEntrySourceLabel.text = friendDrinkEntry.breweryName
                }
                else if friendDrinkEntry.type == "wine"
                {
                    cell.cellSourceLabel.text = "Vineyard"
                    cell.drinkEntrySourceLabel.text = friendDrinkEntry.vineyardName
                }
                
                return cell
            }
            else if indexPath.row == 2
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "VintageCell", for: indexPath) as! FDDVintageTableViewCell
                
                if friendDrinkEntry.type == "wine"
                {
                    cell.drinkEntryVintageLabel.text = friendDrinkEntry.vintage
                }
                
                return cell
            }
            else
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientsCell", for: indexPath) as! FDDIngredientsTableViewCell
                
                if friendDrinkEntry.type == "cocktail" || friendDrinkEntry.type == "shot"
                {
                    if friendDrinkEntry.cocktailEntryMode == 1
                    {
                        cell.drinkEntryIngredientsLabel.text = createIngredientsString()
                    }
                }
                
                return cell
            }
        }
        else if indexPath.section == 2
        {
            if indexPath.row == 0
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DateTimeCell", for: indexPath) as! FDDDateTimeTableViewCell
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                dateFormatter.timeZone = NSTimeZone.system
                cell.drinkEntryDateTimeLabel.text = dateFormatter.string(from: friendDrinkEntry.universalDateTime)
                
                return cell
            }
            else if indexPath.row == 1
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! FDDLocationTableViewCell
                
                if let locationName = friendDrinkEntry.locationName
                {
                    cell.drinkEntryLocationLabel.text = locationName
                }
                
                return cell
            }
            else if indexPath.row == 2
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CaptionCell", for: indexPath) as! FDDCaptionTableViewCell
                
                if let caption = friendDrinkEntry.caption
                {
                    cell.drinkEntryCaptionLabel.text = caption
                }
                
                return cell
            }
            else
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LikesCell", for: indexPath) as! FDDLikesTableViewCell
                
                if likeCount != nil
                {
                    cell.likesLabel.text = "\(likeCount!) likes"
                }
                else
                {
                    // or maybe whatever the friendDrinkEntry.likeCount is?
                    cell.likesLabel.text = "0 likes"
                }
                
                if drinkEntryLiked == true
                {
                    cell.likeButton.setImage(UIImage(named: "Hearts Filled"), for: UIControlState.normal)
                }
                else
                {
                    cell.likeButton.setImage(UIImage(named: "Hearts"), for: UIControlState.normal)
                }
                
                return cell
            }
        }
        else
        {
            if indexPath.row < comments.count
            {
                if editingComment == true && indexPath == commentIndexPath
                {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "EditCommentCell", for: indexPath) as! FDDEditCommentTableViewCell
                    
                    cell.editCommentTextView.delegate = self
                    
                    cell.editCommentTextView.isScrollEnabled = false
                    
                    if editedCommentText != nil
                    {
                        cell.editCommentTextView.textColor = UIColor.black
                        
                        cell.editCommentTextView.text = editedCommentText
                    }
                    // else, it's set to "Add Comment" in light gray by default
                    
                    return cell
                }
                else
                {
                    let comment = comments[indexPath.row]
                    
                    let cell: FDDCommentTableViewCell
                    
                    if let currentUser = PFUser.current()
                    {
                        if comment.commenter == currentUser
                        {
                            cell = tableView.dequeueReusableCell(withIdentifier: "UserCommentCell", for: indexPath) as! FDDCommentTableViewCell
                        }
                        else
                        {
                            cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! FDDCommentTableViewCell
                        }
                    }
                    else
                    {
                        cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! FDDCommentTableViewCell
                    }
                    
                    if let name = comment.commenter.object(forKey: "name") as? String
                    {
                        cell.commenterLabel.text = name
                    }
                    if let photo = comment.commenter.object(forKey: "photo") as? String
                    {
                        let url = URL(string: photo)
                        
                        DispatchQueue.global(qos: .utility).async
                        {
                            do
                            {
                                let data = try Data(contentsOf: url!)
                                
                                DispatchQueue.main.async
                                {
                                    cell.commenterImageView.alpha = 0
                                    cell.commenterImageView.image = UIImage(data: data)
                                        
                                    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations:
                                    {
                                        cell.commenterImageView.alpha = 1
                                    },
                                    completion: nil)
                                }
                            }
                            catch let error
                            {
                                print("error in cellForRowAt: \(error)")
                                
                                // refetch the photo, I guess
                                // what if the problem is that there's no internet access?
                            }
                        }
                    }
                    
                    cell.commentTextLabel.text = comment.text
                    cell.commentDateTimeLabel.text = createDateTimeString(dateTime: comment.universalDateTime)
                    cell.comment = comment
                    
                    return cell
                }
            }
            else
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell", for: indexPath) as! FDDAddCommentTableViewCell
                
                cell.addCommentTextView.delegate = self
                
                cell.addCommentTextView.isScrollEnabled = false
                
                if commentText != nil
                {
                    cell.addCommentTextView.textColor = UIColor.black
                    
                    cell.addCommentTextView.text = commentText
                }
                // else, it's set to "Add Comment" in light gray by default
                
                return cell
            }
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let friendIndexPath = IndexPath(row: 0, section: 0)
        
        if indexPath == friendIndexPath
        {
            return 95
        }
        
        if indexPath.section == 1
        {
            if (indexPath.row == 1 || indexPath.row == 2) && (friendDrinkEntry.type == "cocktail" || friendDrinkEntry.type == "shot") && friendDrinkEntry.cocktailEntryMode == 1
            {
                return 0
            }
        }
        
        if indexPath.section == 2
        {
            if indexPath.row == 1 && friendDrinkEntry.locationName == nil
            {
                return 0
            }
            else if indexPath.row == 2 && friendDrinkEntry.caption == nil
            {
                return 0
            }
        }
        
        /*
        if indexPath.section == 3 && indexPath.row == comments.count
        {
            // return 150
            return UITableViewAutomaticDimension
        }
        */
        
        return UITableViewAutomaticDimension
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
