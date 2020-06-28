//
//  Content.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class Content: NSObject {
    static let lineLength = 16
    
    var _data = Data([])
    var loadAddress: UInt32 = 0
    var offset: UInt32 = 0
        
    var data: Data {
        _data[offset...]
    }
    
    lazy var instructions: [Instruction] = {
        var d = Disassembler(data, loadAddress: loadAddress)
        return d.disassemble()
    }()
    
    var assembly: String {
        instructions.map { String(describing: $0) }.joined(separator: "\n")
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
