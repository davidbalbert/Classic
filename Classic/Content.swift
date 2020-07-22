//
//  Content.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa
import M68K

private extension Data {
    func chunked(by count: Int) -> [Data] {
        stride(from: startIndex, to: endIndex, by: count).map { i in
            self[i..<Swift.min(i+count, endIndex)]
        }
    }

    func hexDump() -> String {
        chunked(by: 2).map { word in
            word.map { String(format: "%02x", $0) }.joined(separator: "")
        }.joined(separator: " ")
    }
}

class Content: NSObject {
    static let lineLength = 16
    
    var _data = Data([])
    var loadAddress: UInt32 = 0
    var offset: UInt32 = 0
        
    var data: Data {
        _data[offset...]
    }
    
    lazy var instructions: [Instruction] = {
        var d = Disassembler()
        return d.disassemble(data, loadAddress: loadAddress)
    }()
    
    var attributedAssembly: NSAttributedString {
        let res = NSMutableAttributedString()
                    
        for insn in instructions {
            var attributes: [NSAttributedString.Key : Any] = [.foregroundColor: NSColor.textColor]
            
            var s = insn.data.hexDump().padding(toLength: 26, withPad: " ", startingAt: 0)
            
            if insn.isUnknown, let atrap = ATrap(data: insn.data) {
                s += String(describing: atrap)
            } else if insn.isUnknown {
                s += String(describing: insn)
                attributes[.backgroundColor] = NSColor.red
            } else {
                s += String(describing: insn)
            }
            
            res.append(NSAttributedString(string: s, attributes: attributes))
            res.append(NSAttributedString(string: "\n", attributes: attributes))
        }
        
        return res
    }
    
    // lineno is 1 indexed
    func address(for lineno: Int) -> UInt32? {
        let i = lineno-1
        
        if i >= instructions.count {
            return nil
        } else {
            return instructions[i].address
        }
    }
    
    func read(from data: Data) {
        self._data = data
    }
}
