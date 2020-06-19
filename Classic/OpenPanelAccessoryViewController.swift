//
//  OpenPanelAccessoryViewController.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class OpenPanelAccessoryViewController: NSViewController, NSOpenSavePanelDelegate {
    
    @IBOutlet var loadAddressField: NSTextField!
    @IBOutlet var offsetField: NSTextField!
    
    var loadAddress = 0
    var offset = 0

    @IBAction func loadAddressUpdated(_ sender: NSTextField) {
        let s = sender.stringValue
        let i: Int?

        if s.starts(with: "0x") {
            i = Int(s.dropFirst(2), radix: 16)
        } else {
            i = Int(s)
        }

        loadAddress = i ?? 0
    }
    
    @IBAction func offsetUpdated(_ sender: NSTextField) {
        let s = sender.stringValue
        let i: Int?

        if s.starts(with: "0x") {
            i = Int(s.dropFirst(2), radix: 16)
        } else {
            i = Int(s)
        }

        offset = i ?? 0
    }
    
    func reset() {
        loadAddress = 0
        loadAddressField.stringValue = "0x0"
        
        offset = 0
        offsetField.stringValue = "0x0"
    }
}
