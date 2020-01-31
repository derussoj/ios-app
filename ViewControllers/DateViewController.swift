//
//  DateViewController.swift
//  Cheers
//
//  Created by Air on 5/25/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit

class DateViewController: UIViewController {

    var selectedDate: Date!
    
    var sendingView: String!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if selectedDate != nil
        {
            datePicker.setDate(selectedDate, animated: false)
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
            performSegue(withIdentifier: "SaveDateToAddBeer", sender: self)
        }
        else if sendingView == "AddWine"
        {
            performSegue(withIdentifier: "SaveDateToAddWine", sender: self)
        }
        else if sendingView == "AddCocktail"
        {
            performSegue(withIdentifier: "SaveDateToAddCocktail", sender: self)
        }
        else if sendingView == "AddShot"
        {
            performSegue(withIdentifier: "SaveDateToAddShot", sender: self)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "SaveDateToAddBeer" || segue.identifier == "SaveDateToAddWine" || segue.identifier == "SaveDateToAddCocktail" || segue.identifier == "SaveDateToAddShot"
        {
            selectedDate = datePicker.date
        }
    }

}
