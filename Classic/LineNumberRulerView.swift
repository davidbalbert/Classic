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
    var lineInfo: [Int : Int] = [:] // first character -> line
    var content: Content?
    var padding = 0
    
    override var isFlipped: Bool {
        true
    }
    
    var attributes: [NSAttributedString.Key : Any] {
        var attrs: [NSAttributedString.Key : Any] = [.foregroundColor: NSColor.secondaryLabelColor]
        
        if let textView = clientView as? NSTextView, let font = textView.font {
            attrs[.font] = font
        }
        
        return attrs
    }
    
    override func viewWillDraw() {
        super.viewWillDraw()
        
        if !lineInfoValid {
            updateLineInfo()
        }
    }
    
    func updateLineInfo() {
        guard let textStorage = (clientView as? NSTextView)?.textStorage else { return }
        guard let content = content else { return }
        
        let s = textStorage.string as NSString
        
        var line = 1
        s.enumerateSubstrings(in: NSRange(location: 0, length: s.length), options: [.byLines, .substringNotRequired]) { substring, range, enclosingRange, stop in
            
            self.lineInfo[range.lowerBound] = line
            line += 1
        }
                
        lineInfoValid = true
        
        var last: UInt32
        if lineInfo.count > 0 {
            last = content.address(for: lineInfo.count) ?? 0
        } else {
            last = 0
        }

        let lastString = NSString(format: "%x", last)
        let maxWidth = lastString.size(withAttributes: attributes).width + 6
        
        ruleThickness = maxWidth
        padding = lastString.length
    }
    
    func address(for characterIndex: Int) -> UInt32? {
        guard let lineno = lineInfo[characterIndex] else { return nil }
        return content?.address(for: lineno)
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView else { return }
        guard let layoutManager = textView.layoutManager else { return }
        guard let textStorage = textView.textStorage else { return }
        guard let textContainer = textView.textContainer else { return }
        guard let scrollView = scrollView else { return }

        let visibleRect = scrollView.contentView.bounds
        let visibleGlyphs = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let visibleChars = layoutManager.characterRange(forGlyphRange: visibleGlyphs, actualGlyphRange: nil)
        
        let attrs = attributes
        let string = textStorage.string as NSString

        var charIndex = visibleChars.location
        
        while charIndex < NSMaxRange(visibleChars) {
            guard let address = address(for: charIndex) else {
                string.getLineStart(nil, end: &charIndex, contentsEnd: nil, for: NSRange(location: charIndex, length: 0))
                continue
            }

            let glyphIndex = layoutManager.characterIndexForGlyph(at: charIndex)
            let fragment = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            
            let s = NSString(format: "%0\(padding)x" as NSString, address)
            let size = s.size(withAttributes: attrs)
            let rect = NSRect(x: bounds.maxX - size.width - 3, y: fragment.minY - visibleRect.minY, width: size.width, height: size.height)
            s.draw(in: rect, withAttributes: attrs)
            
            string.getLineStart(nil, end: &charIndex, contentsEnd: nil, for: NSRange(location: charIndex, length: 0))
        }
    }
}
