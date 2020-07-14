//
//  Content.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa
import M68K

private extension Sequence where Iterator.Element == NSAttributedString {
    func joined(separator: NSAttributedString) -> NSAttributedString {
        return reduce(NSMutableAttributedString()) { r, s in
            if r.length > 0 {
                r.append(separator)
            }
            r.append(s)
            
            return r
        }
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
    
    var assembly: String {
        instructions.map { String(describing: $0) }.joined(separator: "\n")
    }
    
    var attributedAssembly: NSAttributedString {
        instructions.map { instruction in
            if instruction.isUnknown {
                return NSAttributedString(string: String(describing: instruction), attributes: [.backgroundColor: NSColor.red])
            } else {
                return NSAttributedString(string: String(describing: instruction))
            }
        }.joined(separator: NSAttributedString(string: "\n"))
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
