//
//  DebugWindowController.swift
//  Classic
//
//  Created by David Albert on 8/8/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa
import M68K

class DebugWindowController: NSWindowController {
    @IBOutlet var toolbar: NSToolbar!
    
    var machine: MacPlus?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        toolbar.autosavesConfiguration = true
    }

    @IBAction func step(_ sender: Any) {
        machine?.step()
    }
    
    @IBAction func reset(_ sender: Any) {
        machine?.reset()
    }
}