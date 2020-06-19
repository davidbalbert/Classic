//
//  Content.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa

class Content: NSObject {
    var data: Data
    var loadAddress = 0
    var offset = 0

    init(bytes: [UInt8]) {
        data = Data(bytes)
    }

    func read(from data: Data) {
        self.data = data
    }
}
