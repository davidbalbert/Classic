//
//  Content.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

private extension Data {
    func chunked(by count: Int) -> [Data] {
        return stride(from: startIndex, to: endIndex, by: count).map { i in
            self[i..<Swift.min(i+count, endIndex)]
        }
    }
}

class Content: NSObject {
    static let lineLength = 16
    
    var _data = Data([])
    var loadAddress = 0
    var offset = 0
        
    var data: Data {
        _data[offset...]
    }
    
    lazy var instructions: [Instruction] = {
        M68K.disassemble(data: data, address: offset+loadAddress)
    }()
    
    var assembly: String {
        instructions.map { String(describing: $0) }.joined(separator: "\n")
    }
    
    // lineno is 1 indexed
    func address(for lineno: Int) -> Int? {
        let i = lineno-1
        
        if i >= instructions.count {
            return nil
        } else {
            return instructions[i].address
        }
    }
    
    var hexDescription: String {
        data.chunked(by: Content.lineLength).map { line in
            line.chunked(by: 2).map { word in
                word.map { String(format: "%02x", $0) }.joined(separator: "")
            }.joined(separator: " ")
        }.joined(separator: "\n")
    }
    
    func read(from data: Data) {
        self._data = data
    }
}
