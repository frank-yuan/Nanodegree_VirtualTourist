//
//  AnyObjectHelper.swift
//  Nanodegree_OnTheMap
//
//  Created by Xuan Yuan (Frank) on 8/2/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import UIKit

class AnyObjectHelper{
    static func parseData<T>(object:AnyObject?, name:String, defaultValue:T) -> T {
        if let object = object, result = object[name] as? T {
            return result
        }
        return defaultValue
    }
}

class AutoSelectorCaller : NSObject{
    
    private let sender: AnyObject
    private let releaseSelector : Selector
    
    init(sender: AnyObject, releaseSelector: Selector) {
        self.sender = sender
        self.releaseSelector = releaseSelector
    }
    
    init(sender: AnyObject, startSelector: Selector, releaseSelector: Selector) {
        self.sender = sender
        self.releaseSelector = releaseSelector
        sender.performSelectorOnMainThread(startSelector, withObject: nil, waitUntilDone: false)
    }
    
    deinit {
        sender.performSelectorOnMainThread(releaseSelector, withObject: nil, waitUntilDone: false)
    }
}


extension UIViewController {

    func showAlert(title: String, buttonText: String = "OK",  message: String = "", completionHandler: (()->Void)? = nil ) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: buttonText, style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: completionHandler)
    }
}
