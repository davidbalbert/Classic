//
//  TestMachine.swift
//  M68KTests
//
//  Created by David Albert on 8/9/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Foundation
@testable import M68K

class TestMachine: Machine {
    var data: Data
    
    init(_ bytes: [UInt8]) {
        data = Data(bytes)
    }
    
    func read8(_ address: UInt32) -> UInt8 {
        data.read8(Int(address))
    }
    
    func read16(_ address: UInt32) -> UInt16 {
        data.read16(Int(address))
    }
    
    func read32(_ address: UInt32) -> UInt32 {
        data.read32(Int(address))
    }
    
    func write8(_ address: UInt32, value: UInt8) {
        data.write8(Int(address), value: value)
    }
    
    func write16(_ address: UInt32, value: UInt16) {
        data.write16(Int(address), value: value)
    }
    
    func write32(_ address: UInt32, value: UInt32) {
        data.write32(Int(address), value: value)
    }
    
    func readRange(_ range: Range<UInt32>) -> Data {
        data[range]
    }
    
    func canReadWithoutSideEffects(_ address: UInt32) -> Bool {
        true
    }
}

