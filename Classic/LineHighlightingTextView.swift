//
//  LineHighlightingTextView.swift
//  Classic
//
//  Created by David Albert on 8/2/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

private extension NSString {
    func characterRange(for line: Int) -> NSRange? {
        var l = 1
        var i = 0
        var range = NSRange(location: i, length: 0)
        
        while l <= line {
            if i == length {
                return nil
            }

            range = lineRange(for: NSRange(location: i, length: 0))
            l += 1
            i = NSMaxRange(range)
        }
        
        return range
    }
}

class LineHighlightingTextView: NSTextView {
    var highlightedLine: Int? {
        didSet {
            needsDisplay = true
        }
    }
    
    var highlightColor: NSColor? {
        didSet {
            if highlightedLine != nil {
                needsDisplay = true
            }
        }
    }
    
    // keep our superclass from drawing our background
    override var drawsBackground: Bool {
        get {
            false
        }
        
        set {
            // noop
        }
    }
    
    
    func rectForHighlightedLine() -> NSRect? {
        guard let highlightedLine = highlightedLine,
            let layoutManager = layoutManager,
            let textStorage = textStorage,
            let textContainer = textContainer else {
                return nil
        }
        
        guard let charRange = (textStorage.string as NSString).characterRange(for: highlightedLine) else {
            return nil
        }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
        
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        return boundingRect.insetBy(dx: -textContainer.lineFragmentPadding, dy: 0)
    }

    override func draw(_ dirtyRect: NSRect) {
        // TODO: figure out what to do when drawsBackground is false
        backgroundColor.set()
        NSBezierPath.fill(dirtyRect)
        
        if let highlightRect = rectForHighlightedLine(), let highlightColor = highlightColor, highlightRect.intersects(dirtyRect) {

            highlightColor.set()
            NSBezierPath.fill(highlightRect)
        }

        super.draw(dirtyRect)
    }
    
}
