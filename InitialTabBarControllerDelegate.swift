//
//  InitialTabBarControllerDelegate.swift
//  Cheers
//
//  Created by John DeRusso on 9/30/15.
//  Copyright © 2015 Cheers. All rights reserved.
//

import UIKit

class InitialTabBarControllerDelegate: NSObject, UITabBarControllerDelegate
{
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool
    {
        let fromViewIndex = tabBarController.selectedIndex
        
        if let toViewIndex = tabBarController.viewControllers?.index(of: viewController)
        {
            if toViewIndex > fromViewIndex
            {
                rightwardTransition(tabBarController: tabBarController, selectedViewController: viewController)
            }
            else if toViewIndex < fromViewIndex
            {
                leftwardTransition(tabBarController: tabBarController, selectedViewController: viewController)
            }
            else
            {
                // Do nothing when the current tab is selected.
            }
        }
        
        return false
    }
    
    func rightwardTransition(tabBarController: UITabBarController, selectedViewController: UIViewController)
    {
        guard let fromView = tabBarController.selectedViewController?.view
            else { return }
        
        guard let toView = selectedViewController.view
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
                    
                tabBarController.selectedViewController = selectedViewController
            }
        })
    }
    
    func leftwardTransition(tabBarController: UITabBarController, selectedViewController: UIViewController)
    {
        guard let fromView = tabBarController.selectedViewController?.view
            else { return }
        
        guard let toView = selectedViewController.view
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
                    
                tabBarController.selectedViewController = selectedViewController
            }
        })
    }
}
