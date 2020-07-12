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
    @IBOutlet var entryPointField: NSTextField!
    
    var loadAddress: UInt32 = 0
    var entryPoint: UInt32 = 0

    @IBAction func loadAddressUpdated(_ sender: NSTextField) {
        let s = sender.stringValue

        loadAddress = parseHex(s) ?? 0
    }
    
    @IBAction func offsetUpdated(_ sender: NSTextField) {
        let s = sender.stringValue
        
        entryPoint = parseHex(s) ?? 0
    }
    
    func parseHex(_ s: String) -> UInt32? {
        if s.starts(with: "0x") {
            return UInt32(s.dropFirst(2), radix: 16)
        } else {
            return UInt32(s, radix: 16)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reset()
    }
    
    func reset() {
        loadAddress = 0
        loadAddressField.stringValue = "0x0"
        
        entryPoint = 0x2a
        entryPointField.stringValue = "0x2a"
    }
}
