//
//  GCDBlackBox.swift
//  Nanodegree_OnTheMap
//
//  Created by Xuan Yuan (Frank) on 7/26/16.
//  Copyright © 2016 frank-yuan. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}
func performUpdatesUserInitiated(updates: () -> Void) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
        updates()
    }
}
func performUpdatesUserInteractive(updates: () -> Void) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
        updates()
    }
}