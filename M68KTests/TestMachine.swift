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
    var cpu = CPU()
    var ram: Data
    
    init(_ bytes: [UInt8]) {
        ram = Data(bytes)
    }
    
    func read8(_ address: UInt32) -> UInt8 {
        ram.read8(Int(address))
    }
    
    func read16(_ address: UInt32) -> UInt16 {
        ram.read16(Int(address))
    }
    
    func read32(_ address: UInt32) -> UInt32 {
        ram.read32(Int(address))
    }
    
    func write8(_ address: UInt32, value: UInt8) {
        ram.write8(Int(address), value: value)
    }
    
    func write16(_ address: UInt32, value: UInt16) {
        ram.write16(Int(address), value: value)
    }
    
    func write32(_ address: UInt32, value: UInt32) {
        ram.write32(Int(address), value: value)
    }
    
    func readRange(_ range: Range<UInt32>) -> Data {
        ram[range]
    }
    
    func canReadWithoutSideEffects(_ address: UInt32) -> Bool {
        true
    }
}

