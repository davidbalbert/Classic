//
//  ViewController.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class AssemblyViewController: NSViewController {
    @IBOutlet var textView: LineHighlightingTextView!
    var rulerView: LineNumberRulerView?

    override var representedObject: Any? {
        didSet {
            guard let content = representedObject as? Content else {
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
        
        textView.highlightColor = NSColor(named: "debuggerHighlightColor")
        textView.highlightedLine = 2
        
        if let scrollView = textView.enclosingScrollView {
            let rulerView = LineNumberRulerView(scrollView: scrollView, orientation: .verticalRuler)
            rulerView.clientView = textView
            
            rulerView.highlightedLine = 2
            
            scrollView.verticalRulerView = rulerView
            scrollView.rulersVisible = true
            
            self.rulerView = rulerView
        }
    }
}

