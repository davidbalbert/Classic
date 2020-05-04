//
//  Content.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class Content: NSObject {
    var bytes: [UInt8]

    init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    func read(from data: Data) {
        bytes = Array(data)
    }
}
