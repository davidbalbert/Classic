//
//  RegisterViewController.swift
//  Classic
//
//  Created by David Albert on 7/21/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

struct Register {
    var name: String
    var value: Int32
    
    func attributedDescription(with font: NSFont) -> NSAttributedString {
        let boldDesc = font.fontDescriptor.withSymbolicTraits(.bold)
        let boldFont = NSFont(descriptor: boldDesc, size: font.pointSize)
        
        let s = NSMutableAttributedString()
        
        s.append(NSAttributedString(string: name, attributes: [.font: boldFont ?? font]))
        
        s.append(NSAttributedString(string: " = \(value)", attributes: [.font: font]))
        
        return s
    }
}

class RegisterViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    @IBOutlet var outlineView: NSOutlineView!
    
    let registers = ["D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "A0", "A1", "A2", "A3", "A4", "A5", "A6", "A7"].map { Register(name: $0, value: 0) }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        if item == nil {
            return registers.count
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item else {
            return registers[index]
        }
        
        return item
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        false
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Register"), owner: self) as? NSTableCellView
        
        guard let register = item as? Register else {
            return view
        }
        
        guard let textField = view?.textField else {
            return view
        }
        
        let font = textField.font ?? NSFont.systemFont(ofSize: 0)
        
        textField.attributedStringValue = register.attributedDescription(with: font)
        
        return view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
