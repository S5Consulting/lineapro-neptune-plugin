//
//  Progress.swift
//  SwiftDemo
//
//  Created by Flex on 9/4/15.
//  Copyright (c) 2015 Datecs. All rights reserved.
//

import Foundation

import UIKit

class PopoverVC: UIViewController {
    @IBAction func popoverDone(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

//
// PizzaModalProgVC.swift
// SwiftPizzaPopover
//
// Created by Steven Lipton on 8/28/14.
// Copyright (c) 2014 MakeAppPie.Com. All rights reserved.
//

import UIKit

class Progress: UIViewController {
    
    static var viewController: Progress?
    
    var dismissButton = UIButton(type: UIButtonType.Custom)
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    var message = UITextView()
    var progress = UIProgressView(progressViewStyle: UIProgressViewStyle.Bar)
    
    func onCancel(){
        dismissViewControllerAnimated(false, completion: nil)
    }

    static func show(vc: UIViewController)
    {
        show(vc, message: "Operation in progress\nPlease wait...", progress: false)
    }
    
    static func show(vc: UIViewController, message: String)
    {
        show(vc, message: message, progress: false)
    }

    static func show(vc: UIViewController, message: String, progress: Bool)
    {
        viewController = Progress()
        viewController?.message.text=message
        vc.presentViewController(viewController!, animated: false, completion: nil)
    }
    
    static func hide()
    {
        viewController?.activityIndicator.stopAnimating()
        viewController?.dismissViewControllerAnimated(false, completion: nil)
    }
    
    static func setMessage(message: String)
    {
        viewController?.message.text=message
    }
    
    static func setProgress(percents: Float)
    {
        viewController?.progress.setProgress(percents/100.0, animated: false)
    }
    
    func centerRect(width: CGFloat, height: CGFloat, var top: CGFloat) -> CGRect
    {
        let bounds=UIScreen.mainScreen().bounds
        if top == -1
        {
            top=bounds.height/2-height/2
        }
        return CGRectMake(bounds.width/2-width/2, top, width, height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bounds=UIScreen.mainScreen().bounds
        
        //set our transition style
        modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
        
        // Build a programmatic view
        view.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
        
        //add activity indicator
        activityIndicator.frame=centerRect(40,height: 40, top: -1)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        //add text message (if any)
        message.frame=centerRect(bounds.width-40, height: 200, top: bounds.height/2-200)
        message.textAlignment = .Center
        message.backgroundColor=UIColor.clearColor()
        message.font=UIFont(name: "Helvetica", size: 24)
        view.addSubview(message)
        
        //add progress (if any)
        progress.frame=centerRect(bounds.width-40, height: 40, top: (bounds.height/4)*3)
        progress.setProgress(0, animated: false)
        view.addSubview(progress)
        
        //add the done button
        dismissButton.setTitle("Done", forState: .Normal)
        dismissButton.titleLabel!.font = UIFont(name: "Helvetica", size: 24)
        dismissButton.titleLabel!.textAlignment = .Left
        dismissButton.frame = centerRect(400, height: 200, top: bounds.height-400)
        dismissButton.addTarget(self, action: "onCancel", forControlEvents: .TouchUpInside)
//        view.addSubview(dismissButton)
    }
    
}