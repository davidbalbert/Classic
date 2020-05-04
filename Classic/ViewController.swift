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
            let data = content.data
            let n = 16

            let string = stride(from: data.startIndex, to: data.endIndex, by: n).map { i in
                data[i..<i+n].map { String(format: "%02x", $0) }.joined(separator: " ")
            }.joined(separator: "\n")

            textView.string = string
            textView.textStorage?.font = NSFont(name: "Monaco", size: 11)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

