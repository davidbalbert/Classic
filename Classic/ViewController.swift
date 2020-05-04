//
//  ViewController.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var textView: NSTextView!

    var content: Content! {
        didSet {
            textView.string = content.bytes.map { String(format: "%02x", $0) }.joined(separator: " ")
            textView.textStorage?.font = NSFont(name: "Monaco", size: 11)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

