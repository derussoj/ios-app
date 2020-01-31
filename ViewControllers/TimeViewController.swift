//
//  TimeViewController.swift
//  Cheers
//
//  Created by Air on 5/25/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class TimeViewController: UIViewController {

    var selectedTime: Date!
    
    var sendingView: String!
    
    @IBOutlet weak var timePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if selectedTime != nil
        {
            timePicker.setDate(selectedTime, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
        if sendingView == "AddBeer"
        {
            performSegue(withIdentifier: "SaveTimeToAddBeer", sender: self)
        }
        else if sendingView == "AddWine"
        {
            performSegue(withIdentifier: "SaveTimeToAddWine", sender: self)
        }
        else if sendingView == "AddCocktail"
        {
            performSegue(withIdentifier: "SaveTimeToAddCocktail", sender: self)
        }
        else if sendingView == "AddShot"
        {
            performSegue(withIdentifier: "SaveTimeToAddShot", sender: self)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "SaveTimeToAddBeer" || segue.identifier == "SaveTimeToAddWine" || segue.identifier == "SaveTimeToAddCocktail" || segue.identifier == "SaveTimeToAddShot"
        {
            selectedTime = timePicker.date
        }
    }

}
