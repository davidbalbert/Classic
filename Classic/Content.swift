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
    
    var data = Data([])
    var loadAddress = 0
    var offset = 0

    // lineno is 1 indexed
    func address(for lineno: Int) -> Int? {
        loadAddress + offset + (lineno-1)*Content.lineLength
    }
    
    var hexDescription: String {
        data[offset..<data.count].chunked(by: Content.lineLength).map { line in
            line.chunked(by: 2).map { word in
                word.map { String(format: "%02x", $0) }.joined(separator: "")
            }.joined(separator: " ")
        }.joined(separator: "\n")
    }
    
    func read(from data: Data) {
        self.data = data
    }
}
