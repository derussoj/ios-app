//
//  AppDelegate.swift
//  Cheers
//
//  Created by Air on 2/8/15.
//  Copyright (c) 2015 Cheers. All rights reserved.
//

import UIKit
import CoreData
import Parse
import Bolts
import ParseFacebookUtilsV4
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?

    override init()
    {
        FIRApp.configure()
        
        // enables disk persistence
        FIRDatabase.database().persistenceEnabled = true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool
    {
        // Override point for customization after application launch.
        
        // Apply Cheers green throughout the app.
        // #38CFA6
        // let cheersGreen = UIColor(red: 56/255.0, green: 207/255.0, blue: 166/255.0, alpha: 1)
        // #2EBFA4
        // let cheersGreen = UIColor(red: 46/255.0, green: 191/255.0, blue: 164/255.0, alpha: 1)
        // #29AB9E
        let cheersGreen = UIColor(red: 41/255.0, green: 171/255.0, blue: 158/255.0, alpha: 1)
        UITextField.appearance().tintColor = cheersGreen
        UITableViewCell.appearance().tintColor = cheersGreen
        UISwitch.appearance().onTintColor = cheersGreen
        UITabBar.appearance().tintColor = cheersGreen
        // UIButton.appearance().tintColor = cheersGreen
        
        if #available(iOS 8.2, *)
        {
            UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightLight)], for: UIControlState.normal)
        }
        else
        {
            if let font = UIFont(name: "HelveticaNeue-Light", size: 18.0)
            {
                UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: font], for: UIControlState.normal)
            }
        }
        
        // FIRApp.configure()
        
        let firebaseRootRef = FIRDatabase.database().reference()
        
        // keeps the user's data synched
        if let user = FIRAuth.auth()?.currentUser
        {
            // maybe not all of the user's data
            // everything but /drinks?
            let userRef = firebaseRootRef.child("users/\(user.uid)")
            userRef.keepSynced(true)
        }
        
        // [Optional] Power your app with Local Datastore. For more info, go to
        // https://parse.com/docs/ios_guide#localdatastore/iOS
        Parse.enableLocalDatastore()
        
        ParseDrinkEntry.registerSubclass()
        ParseIngredient.registerSubclass()
        ParseComment.registerSubclass()
        ParseLike.registerSubclass()
        
        // Initialize Parse.
        Parse.setApplicationId("GGfmnOeEnnf54tOADJpXYkLYdPZr3mMufnrbALlj",
            clientKey: "JSw29n8kB5tmd55wPiJGrCUGDZtUPMeoFVOY0uju")
        
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)
        
        // [Optional] Track statistics around application opens.
        PFAnalytics.trackAppOpened(launchOptions: launchOptions)
                
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool
    {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.cheers.iphone.Cheers" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Etto", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("Etto.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do
        {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        }
        catch
        {
            // Report any error we got.
            var dict = [String: Any]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext ()
    {
        if managedObjectContext.hasChanges
        {
            do
            {
                try managedObjectContext.save()
            }
            catch
            {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}

