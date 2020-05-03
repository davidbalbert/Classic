//
//  OpenPanelAccessoryViewController.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class OpenPanelAccessoryViewController: NSViewController, NSOpenSavePanelDelegate {
    var loadAddress = 0

    @IBAction func loadAddressUpdated(_ sender: NSTextField) {
        let s = sender.stringValue
        let i: Int?

        if s.starts(with: "0x") {
            i = Int(s, radix: 16)
        } else {
            i = Int(s)
        }

        loadAddress = i ?? 0
    }
}
