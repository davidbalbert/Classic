//
//  LineHighlightingTextView.swift
//  Classic
//
//  Created by David Albert on 8/2/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

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
            let layoutManager = layoutManager else {
                return nil
        }
        
        var line = 1   // line numbers are 1 indexed
        var index = 0
        var range = NSRange(location: 0, length: 0)
        var rect = NSRect.zero
        while line <= highlightedLine {
            rect = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &range)
            
            line += 1
            index = NSMaxRange(range)
        }
        
        return rect
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
