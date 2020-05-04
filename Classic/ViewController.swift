//
//  ViewController.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

private extension Data {
    func chunked(by count: Int) -> [Data] {
        return stride(from: startIndex, to: endIndex, by: count).map { i in
            self[i..<i+count]
        }
    }
}

class ViewController: NSViewController {
    @IBOutlet var textView: NSTextView!

    var content: Content! {
        didSet {
            let data = content.data

            let string = data.chunked(by: 16).map { line in
                line.chunked(by: 2).map { nibble in
                    nibble.map { String(format: "%02x", $0) }.joined(separator: "")
                }.joined(separator: " ")
            }.joined(separator: "\n")

            textView.string = string
            textView.textStorage?.font = NSFont(name: "Monaco", size: 11)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

