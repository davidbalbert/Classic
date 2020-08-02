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

protocol BitField {
    var name: String { get }
    var bitNumber: Int { get }
    var value: Int { get }
}

extension BitField {
    var nameDescription: String {
        "\(name) (\(bitNumber))"
    }
    
    var valueDescription: String {
        "\(value)"
    }
}

struct StatusRegisterBitField: BitField, NameValueDescribable {
    let name: String
    let cpu: CPU
    let bit: StatusRegister
    let bitNumber: Int
    
    var value: Int {
        cpu.sr.intersection(bit).rawValue == 0 ? 0 : 1
    }

    init?(name: String, bit: StatusRegister, cpu: CPU) {
        guard bit.rawValue.nonzeroBitCount == 1 else {
            return nil
        }
        
        self.name = name
        self.cpu = cpu
        self.bit = bit
        self.bitNumber = bit.rawValue.trailingZeroBitCount
    }
}

protocol Register {
    var children: [BitField] { get }
}

struct DataRegisterItem: Register, NameValueDescribable {
    let cpu: CPU
    let name: String
    let keyPath: KeyPath<CPU, UInt32>
    
    var value: UInt32 {
        cpu[keyPath: keyPath]
    }

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

struct AddressRegisterItem: Register, NameValueDescribable {
    let cpu: CPU
    let name: String
    let keyPath: KeyPath<CPU, UInt32>
    
    var value: UInt32 {
        cpu[keyPath: keyPath]
    }
    
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

struct StackPointerItem: Register, NameValueDescribable {
    let cpu: CPU
    
    var value: UInt32 {
        cpu.a7
    }
    
    var nameDescription: String {
        switch cpu.sr.intersection(.stackSelectionMask) {
        case .isp:
            return "A7 (ISP)"
        default:
            return "A7 (USP)"
        }
    }
    
    var valueDescription: String {
        "0x\(String(value, radix: 16))"
    }
    
    var children: [BitField] {
        []
    }
}

struct StatusRegisterItem: Register, NameValueDescribable {
    let cpu: CPU
    
    var nameDescription: String {
      "SR (CCR)"
    }
    
    var valueDescription: String {
        "0x\(String(cpu.sr.rawValue, radix: 16))"
    }
    
    func bitField(name: String, bit: StatusRegister) -> BitField? {
        StatusRegisterBitField(name: name, bit: bit, cpu: cpu)
    }
    
    var children: [BitField] {
        [
            bitField(name: "T0", bit: .t0)!,
            bitField(name: "S",  bit: .s)!,
            bitField(name: "I2", bit: .i2)!,
            bitField(name: "I1", bit: .i1)!,
            bitField(name: "I0", bit: .i0)!,
            bitField(name: "X",  bit: .x)!,
            bitField(name: "N",  bit: .n)!,
            bitField(name: "Z",  bit: .z)!,
            bitField(name: "V",  bit: .v)!,
            bitField(name: "C",  bit: .c)!,
        ]
    }
}


class RegisterViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    @IBOutlet var outlineView: NSOutlineView!
    
    var cpu: CPU?
    var registers: [Register] = []

    
    override var representedObject: Any? {
        didSet {
            guard let content = representedObject as? Content else {
                return
            }
            
            guard let cpu = content.machine?.cpu else {
                return
            }
            
            self.cpu = cpu
            
            createRegisters(cpu)
            outlineView.reloadData()
        }
    }
    
    func createRegisters(_ cpu: CPU) {
        let dataKeyPaths: [String: KeyPath<CPU, UInt32>] = ["D0": \.d0, "D1": \.d1, "D2": \.d2, "D3": \.d3, "D4": \.d4, "D5": \.d5, "D6": \.d6, "D7": \.d7]
        let addressKeyPaths: [String: KeyPath<CPU, UInt32>] =  ["A0": \.a0, "A1": \.a1, "A2": \.a2, "A3": \.a3, "A4": \.a4, "A5": \.a5, "A6": \.a6]
        
        registers = [
            AddressRegisterItem(cpu: cpu, name: "PC", keyPath: \CPU.pc),
            StatusRegisterItem(cpu: cpu)
        ]
        
        registers += dataKeyPaths.map { (name, path) in
            DataRegisterItem(cpu: cpu, name: name, keyPath: path)
        }
        
        registers += addressKeyPaths.map { (name, path) in
            AddressRegisterItem(cpu: cpu, name: name, keyPath: path)
        }
        
        registers += [
            StackPointerItem(cpu: cpu),
            AddressRegisterItem(cpu: cpu, name: "USP", keyPath: \.usp),
            AddressRegisterItem(cpu: cpu, name: "ISP", keyPath: \.isp),
        ]
    }

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
    }
}
