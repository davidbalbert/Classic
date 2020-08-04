//
//  ViewController.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class AssemblyViewController: NSViewController, LineNumberRulerViewDelegate {
    @IBOutlet var textView: LineHighlightingTextView!
    var rulerView: LineNumberRulerView?
    
    var addressToLine: [UInt32: Int] = [:]

    override var representedObject: Any? {
        didSet {
            guard let content = representedObject as? Content else {
                textView.string = ""
                return
            }

            textView.textStorage?.setAttributedString(content.attributedAssembly)
            textView.font = NSFont(name: "Monaco", size: 11)
            
            addressToLine = [:]
            for (i, instruction) in content.instructions.enumerated() {
                addressToLine[instruction.address] = i+1
            }
            
            guard let pc = content.machine?.cpu.pc, let lineno = addressToLine[pc] else {
                return
            }

            textView.highlightedLine = lineno
            rulerView?.highlightedLine = lineno
        }
    }
    
    func lineNumberRulerView(_ rulerView: LineNumberRulerView, stringFor lineno: Int) -> String {
        guard let content = representedObject as? Content else {
            return String(lineno)
        }
        
        return String(content.address(for: lineno) ?? 0, radix: 16)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.highlightColor = NSColor(named: "debuggerHighlightColor")
        
        if let scrollView = textView.enclosingScrollView {
            let rulerView = LineNumberRulerView(scrollView: scrollView, orientation: .verticalRuler)
            rulerView.clientView = textView
            rulerView.delegate = self
            
            scrollView.verticalRulerView = rulerView
            scrollView.rulersVisible = true
            
            self.rulerView = rulerView
        }
    }
}

