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
    var rulerView: LineNumberRulerView?

    var content: Content? {
        didSet {
            guard let content = content else {
                textView.string = ""
                return
            }

            textView.textStorage?.setAttributedString(content.attributedAssembly)
            textView.font = NSFont(name: "Monaco", size: 11)
            rulerView?.content = content
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let scrollView = textView.enclosingScrollView {
            let rulerView = LineNumberRulerView(scrollView: scrollView, orientation: .verticalRuler)
            rulerView.clientView = textView
            rulerView.content = content
            
            scrollView.verticalRulerView = rulerView
            scrollView.rulersVisible = true
            
            self.rulerView = rulerView
        }
    }
}

