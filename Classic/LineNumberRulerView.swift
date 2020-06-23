//
//  LineNumberRulerView.swift
//  Classic
//
//  Created by David Albert on 6/19/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class LineNumberRulerView: NSRulerView {
    var lineInfoValid: Bool = false
    var lineInfo: [String.Index] = []
    
    override var isFlipped: Bool {
        true
    }

    var attributes: [NSAttributedString.Key : Any] {
        if let textView = clientView as? NSTextView, let font = textView.font {
            return [.font: font]
        } else {
            return [:]
        }
    }
    
    override func viewWillDraw() {
        super.viewWillDraw()
        
        if !lineInfoValid {
            updateLineInfo()
        }
    }
    
    func updateLineInfo() {
        guard let textView = clientView as? NSTextView else { return }
        guard let s = textView.textStorage?.string else { return }
        
        s.enumerateSubstrings(in: s.startIndex..., options: [.substringNotRequired, .byLines]) { substring, range, enclosingRange, stop in
            
            self.lineInfo.append(range.lowerBound)
        }
        
        lineInfoValid = true
                
        let last = max(lineInfo.count, 1)
        let maxWidth = NSString(format: "%lu", last).size(withAttributes: attributes).width + 8
        
        ruleThickness = maxWidth
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView else { return }
        guard let layoutManager = textView.layoutManager else { return }
        guard let font = textView.font else { return }

        let attrs = attributes
        
        let numbers = Array(1...10)
                
        for n in numbers {
            let s = NSString(format: "%lu", n)
            let size = s.size(withAttributes: attrs)
            let rect = NSRect(x: bounds.maxX - size.width - 3, y: layoutManager.defaultLineHeight(for: font) * CGFloat(n-1), width: size.width, height: size.height)
            s.draw(in: rect, withAttributes: attrs)
        }
    }
}
