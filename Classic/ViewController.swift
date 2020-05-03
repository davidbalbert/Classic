//
//  ViewController.swift
//  Classic
//
//  Created by David Albert on 5/2/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var pathLabel: NSTextField!
    @IBOutlet var loadAddressTextField: NSTextField!
    @IBOutlet var disassembleButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

