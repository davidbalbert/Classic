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
            self[i..<Swift.min(i+count, endIndex)]
        }
    }
}

class ViewController: NSViewController {
    @IBOutlet var textView: NSTextView!

    var content: Content? {
        didSet {
            guard let data = content?.data, let offset = content?.offset else {
                textView.string = ""
                return
            }
            
            let string = data[offset..<data.count].chunked(by: 16).map { line in
                line.chunked(by: 2).map { word in
                    word.map { String(format: "%02x", $0) }.joined(separator: "")
                }.joined(separator: " ")
            }.joined(separator: "\n")

            textView.textStorage?.setAttributedString(NSAttributedString(string: string))
            textView.font = NSFont(name: "Monaco", size: 11)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let scrollView = textView.enclosingScrollView {
            let rulerView = LineNumberRulerView(scrollView: scrollView, orientation: .verticalRuler)
            rulerView.clientView = textView
            
            scrollView.verticalRulerView = rulerView
            scrollView.rulersVisible = true
        }
    }
}

