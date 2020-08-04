//
//  LineNumberRulerView.swift
//  Classic
//
//  Created by David Albert on 6/19/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

@objc protocol LineNumberRulerViewDelegate {
    @objc optional func lineNumberRulerView(_ rulerView: LineNumberRulerView, stringFor lineno: Int) -> String
}

class LineNumberRulerView: NSRulerView {
    var lineInfoValid: Bool = false
    var lineInfo: [Int : Int] = [:] // first character -> line
    var padding = 0
    
    weak var delegate: LineNumberRulerViewDelegate?
    
    var highlightedLine: Int? {
        didSet {
            needsDisplay = true
        }
    }
    
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
    
    var highlightedAttributes: [NSAttributedString.Key : Any] {
        var attrs: [NSAttributedString.Key : Any] = [.foregroundColor: NSColor.textColor]
        
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
        
        let s = textStorage.string as NSString
        
        var line = 1
        s.enumerateSubstrings(in: NSRange(location: 0, length: s.length), options: [.byLines, .substringNotRequired]) { substring, range, enclosingRange, stop in
            
            self.lineInfo[range.lowerBound] = line
            line += 1
        }
                
        lineInfoValid = true
        
        var last: String
        if lineInfo.count > 0 {
            last = string(for: lineInfo.count)
        } else {
            last = "1"
        }

        let maxWidth = last.size(withAttributes: attributes).width + 6
        
        ruleThickness = maxWidth
        padding = last.count
    }
    
    func line(for characterIndex: Int) -> Int? {
        lineInfo[characterIndex]
    }
    
    func string(for lineno: Int) -> String {
        delegate?.lineNumberRulerView?(self, stringFor: lineno) ?? String(lineno)
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
        let storageString = textStorage.string as NSString

        var charIndex = visibleChars.location
        
        while charIndex < NSMaxRange(visibleChars) {
            guard let lineno = line(for: charIndex) else {
                storageString.getLineStart(nil, end: &charIndex, contentsEnd: nil, for: NSRange(location: charIndex, length: 0))
                continue
            }

            let glyphIndex = layoutManager.characterIndexForGlyph(at: charIndex)
            let fragment = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            
            let s = string(for: lineno)
            let size = s.size(withAttributes: attrs)
            let rect = NSRect(x: bounds.maxX - size.width - 3, y: fragment.minY - visibleRect.minY, width: size.width, height: size.height)
            
            if lineno == highlightedLine {
                s.draw(in: rect, withAttributes: highlightedAttributes)
            } else {
                s.draw(in: rect, withAttributes: attrs)
            }
            
            storageString.getLineStart(nil, end: &charIndex, contentsEnd: nil, for: NSRange(location: charIndex, length: 0))
        }
    }
}
