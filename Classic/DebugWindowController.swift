//
//  DebugWindowController.swift
//  Classic
//
//  Created by David Albert on 8/8/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa
import Combine

import M68K

class DebugWindowController: NSWindowController {
    @IBOutlet var toolbar: NSToolbar!
    @IBOutlet var stepButton: NSButton!
    
    var canceller: AnyCancellable?

    var machine: MacPlus? {
        didSet {
            guard let machine = machine else {
                return
            }
            
            canceller?.cancel()
            
            canceller = machine.$cpu.sink { [weak self] cpu in
                let insn = cpu.fetchNextInstruction()
                
                self?.stepButton.isEnabled = cpu.implements(insn)
            }
        }
    }
    
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
