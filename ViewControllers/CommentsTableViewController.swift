//
//  CommentsTableViewController.swift
//  Cheers
//
//  Created by John DeRusso on 11/1/15.
//  Copyright © 2015 Cheers. All rights reserved.
//

import UIKit
import Parse

class CommentsTableViewController: UITableViewController
{
    var drinkEntry: ParseDrinkEntry!
    var comments = [ParseComment]()
    
    var messageText = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.refreshControl?.addTarget(self, action: #selector(CommentsTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        // other stuff from the beer search page?
        
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl!.frame.size.height), animated: true)
        
        refreshControl?.beginRefreshing()
        
        commentSearch()
    }
    
    func handleRefresh(refreshControl: UIRefreshControl)
    {
        commentSearch()
    }
    
    func commentSearch()
    {            
        DispatchQueue.global(qos: .userInitiated).async
        {
            let query = PFQuery(className: "ParseComment")
            query.whereKey("drinkEntry", equalTo: PFObject(outDataWithClassName: "ParseDrinkEntry", objectId: self.drinkEntry.objectId))
            query.includeKey("commenter")
            query.order(byAscending: "universalDateTime")
            
            do
            {
                if let results = try query.findObjects() as? [ParseComment]
                {
                    DispatchQueue.main.async
                    {
                        self.comments = results
                        
                        self.tableView.reloadData()
                        
                        self.refreshControl?.endRefreshing()
                    }
                }
                else
                {
                    DispatchQueue.main.async
                    {
                        // set messageText
                        
                        self.tableView.reloadData()
                        
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
            catch let error as NSError
            {
                DispatchQueue.main.async
                {
                    // set messageText
                
                    self.tableView.reloadData()
                
                    self.refreshControl?.endRefreshing()
                
                    // error? error.description?
                    print(error)
                }
            }
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
        if comments.count > 0
        {
            return comments.count
        }
        else
        {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if comments.count > 0
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentTableViewCell
            
            let comment = comments[indexPath.row]
            
            cell.commentTextLabel.text = comment.text

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
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
