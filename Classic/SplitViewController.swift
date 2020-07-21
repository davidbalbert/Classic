//
//  SplitViewController.swift
//  Classic
//
//  Created by David Albert on 7/21/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class SplitViewController: NSSplitViewController {
    override var representedObject: Any? {
        didSet {
            for item in splitViewItems {
                item.viewController.representedObject = representedObject
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
