//
//  LineNumberRulerView.swift
//  Classic
//
//  Created by David Albert on 6/19/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class LineNumberRulerView: NSRulerView {
    var trackingTextView: NSTextView
    var textStorage: NSTextStorage
    var layoutManager: NSLayoutManager
    var textContainer: NSTextContainer

    init(textView trackingTextView: NSTextView) {
        self.trackingTextView = trackingTextView
        
        textStorage = NSTextStorage(string: "1\n2\n3\n4\n5\n6\n7\n8\n9\n10")
        layoutManager = NSLayoutManager()
        textContainer = NSTextContainer()
        
        super.init(scrollView: trackingTextView.enclosingScrollView!, orientation: .verticalRuler)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.typesetterBehavior = trackingTextView.layoutManager!.typesetterBehavior
        
        // Maybe add this once things are working?
        // layoutManager.allowsNonContiguousLayout = true
        
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        textStorage.font = trackingTextView.font
        textStorage.setAlignment(.right, range: NSRange(location: 0, length: textStorage.length))
        
//        print(textStorage)
        
        let nGlyphs = layoutManager.numberOfGlyphs
        
        // assumes that the rendered width of line numbers is monitonicly increasing
        let maxWidth = layoutManager.lineFragmentUsedRect(forGlyphAt: nGlyphs-1, effectiveRange: nil).width
        
        self.ruleThickness = maxWidth

        let glyphRange = layoutManager.glyphRange(for: textContainer)
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: bounds.origin)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: bounds.origin)
    }
}
