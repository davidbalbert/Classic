//
//  RegisterViewController.swift
//  Classic
//
//  Created by David Albert on 7/21/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa
import M68K

protocol NameValueDescribable {
    var nameDescription: String { get }
    var valueDescription: String { get }
}

extension NameValueDescribable {
    func attributedDescription(with font: NSFont) -> NSAttributedString {
        let boldDesc = font.fontDescriptor.withSymbolicTraits(.bold)
        let boldFont = NSFont(descriptor: boldDesc, size: font.pointSize) ?? font
        
        let s = NSMutableAttributedString()
        
        s.append(NSAttributedString(string: nameDescription, attributes: [.font: boldFont]))
        
        s.append(NSAttributedString(string: " = \(valueDescription)", attributes: [.font: font]))
        
        return s
    }
}

struct BitField: NameValueDescribable {
    var name: String
    var bitNumber: Int
    var value: Int

    var nameDescription: String {
        "\(name) (\(bitNumber))"
    }
    
    var valueDescription: String {
        "\(value)"
    }
}

protocol Register {
    var children: [BitField] { get }
}

struct DataRegister: Register, NameValueDescribable {
    var name: String
    var value: Int32
    
    var nameDescription: String {
        name
    }
    
    var valueDescription: String {
        String(value)
    }
    
    var children: [BitField] {
        []
    }
}

struct AddressRegister: Register, NameValueDescribable {
    var name: String
    var value: UInt32
    
    var nameDescription: String {
        name
    }
    
    var valueDescription: String {
        "0x\(String(value, radix: 16))"
    }
    
    var children: [BitField] {
        []
    }
}

struct StackPointer: Register, NameValueDescribable {
    enum BackingRegister {
        case usp
        case isp
    }
    
    var backingRegister: BackingRegister
    var value: UInt32
    
    var nameDescription: String {
        switch backingRegister {
        case .usp:
            return "A7 (USP)"
        case .isp:
            return "A7 (ISP)"
        }
    }
    
    var valueDescription: String {
        "0x\(String(value, radix: 16))"
    }
    
    var children: [BitField] {
        []
    }
}

struct StatusRegister: Register, NameValueDescribable {
    let statusRegister: M68K.StatusRegister
    
    var nameDescription: String {
      "SR (CCR)"
    }
    
    var valueDescription: String {
        "0x\(String(statusRegister.rawValue, radix: 16))"
    }
    
    var children: [BitField] {
        [
            BitField(name: "T0", bitNumber: 14, value: statusRegister.intersection(.t0).rawValue == 0 ? 0 : 1),
            BitField(name: "S", bitNumber: 13, value: statusRegister.intersection(.s).rawValue == 0 ? 0 : 1),
        ]
    }
}


class RegisterViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    @IBOutlet var outlineView: NSOutlineView!
    
    lazy var registers: [Register] = {
        var registers: [Register] = [AddressRegister(name: "PC", value: 0x2a), StatusRegister(statusRegister: [.s])]
        
        registers += ["D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7"].map { DataRegister(name: $0, value: 0) }
        
        registers += ["A0", "A1", "A2", "A3", "A4", "A5", "A6"].map { AddressRegister(name: $0, value: 0) }
        
        registers.append(StackPointer(backingRegister: .usp, value: 0))
        
        registers += ["USP", "ISP"].map { AddressRegister(name: $0, value: 0) }
        
        return registers
    }()

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        if item == nil {
            return registers.count
        } else if let register = item as AnyObject as? Register {
            return register.children.count
        } else {
            return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        if item == nil {
            return registers[index]
        } else if let register = item as AnyObject as? Register {
            return register.children[index]
        } else {
            return item!
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let register = item as AnyObject as? Register, register.children.count > 0 {
            return true
        } else {
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Register"), owner: self) as? NSTableCellView
        
        // `as AnyObject` is a hack to get around this bug: https://bugs.swift.org/browse/SR-3871
        guard let register = item as AnyObject as? NameValueDescribable else {
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
