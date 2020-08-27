//
//  RegisterViewController.swift
//  Classic
//
//  Created by David Albert on 7/21/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa
import Combine
import M68K

protocol NameValueConvertible {
    var nameDescription: String { get }
    var valueDescription: String { get }
}

extension NameValueConvertible {
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

struct StatusRegisterBitField: BitField, NameValueConvertible, Hashable {
    let name: String
    let bit: StatusRegister
    let bitNumber: Int
    
    weak var viewController: RegisterViewController?
    
    var value: Int {
        guard let vc = viewController, let cpu = vc.cpu else { return 0 }
        
        return cpu.sr.intersection(bit).rawValue == 0 ? 0 : 1
    }

    init?(name: String, bit: StatusRegister, viewController: RegisterViewController) {
        guard bit.rawValue.nonzeroBitCount == 1 else {
            return nil
        }
        
        self.name = name
        self.viewController = viewController
        self.bit = bit
        self.bitNumber = bit.rawValue.trailingZeroBitCount
    }
}

protocol Register {
    var children: [BitField] { get }
}

struct DataRegisterItem: Register, NameValueConvertible, Hashable {
    let name: String
    let keyPath: KeyPath<CPU, UInt32>
    
    weak var viewController: RegisterViewController?
    
    var value: Int32 {
        guard let vc = viewController, let cpu = vc.cpu else { return 0 }

        return Int32(bitPattern: cpu[keyPath: keyPath])
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

struct AddressRegisterItem: Register, NameValueConvertible, Hashable {
    let name: String
    let keyPath: KeyPath<CPU, UInt32>
    
    weak var viewController: RegisterViewController?
    
    var value: UInt32 {
        guard let vc = viewController, let cpu = vc.cpu else { return 0 }

        return cpu[keyPath: keyPath]
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

struct StackPointerItem: Register, NameValueConvertible, Hashable {
    weak var viewController: RegisterViewController?
    
    var value: UInt32 {
        guard let vc = viewController, let cpu = vc.cpu else { return 0 }

        return cpu.a7
    }
    
    var nameDescription: String {
        guard let vc = viewController, let cpu = vc.cpu else { return "A7" }
        
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

struct StatusRegisterItem: Register, NameValueConvertible, Hashable {
    weak var viewController: RegisterViewController?
    
    var nameDescription: String {
      "SR (CCR)"
    }
    
    var valueDescription: String {
        guard let vc = viewController, let cpu = vc.cpu else { return "0x0" }
        
        return "0x\(String(cpu.sr.rawValue, radix: 16))"
    }
    
    func bitField(name: String, bit: StatusRegister) -> BitField? {
        guard let viewController = viewController else { return nil }

        return StatusRegisterBitField(name: name, bit: bit, viewController: viewController)
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
    
    var machine: MacPlus?
    var cpu: CPU? {
        didSet {
            outlineView.reloadData()
        }
    }
    var registers: [Register] = []
    var canceller: AnyCancellable?
    
    override var representedObject: Any? {
        didSet {
            guard let content = representedObject as? Content, let machine = content.machine else {
                return
            }
            
            canceller?.cancel()

            canceller = machine.$cpu.sink { [weak self] cpu in
                self?.cpu = cpu
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createRegisters()
    }
    
    func createRegisters() {
        let dataKeyPaths: [(String, KeyPath<CPU, UInt32>)] = [("D0", \.d0), ("D1", \.d1), ("D2", \.d2), ("D3", \.d3), ("D4", \.d4), ("D5", \.d5), ("D6", \.d6), ("D7", \.d7)]
        let addressKeyPaths: [(String, KeyPath<CPU, UInt32>)] =  [("A0", \.a0), ("A1", \.a1), ("A2", \.a2), ("A3", \.a3), ("A4", \.a4), ("A5", \.a5), ("A6", \.a6)]
        
        registers = [
            AddressRegisterItem(name: "PC", keyPath: \.pc, viewController: self),
            StatusRegisterItem(viewController: self)
        ]
        
        registers += dataKeyPaths.map { (name, path) in
            DataRegisterItem(name: name, keyPath: path, viewController: self)
        }
        
        registers += addressKeyPaths.map { (name, path) in
            AddressRegisterItem(name: name, keyPath: path, viewController: self)
        }
        
        registers += [
            StackPointerItem(viewController: self),
            AddressRegisterItem(name: "USP", keyPath: \.usp, viewController: self),
            AddressRegisterItem(name: "ISP", keyPath: \.isp, viewController: self),
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
        guard let register = item as AnyObject as? NameValueConvertible else {
            return view
        }
        
        guard let textField = view?.textField else {
            return view
        }
        
        let font = textField.font ?? NSFont.systemFont(ofSize: 0)
        
        textField.attributedStringValue = register.attributedDescription(with: font)
        
        return view
    }
}
