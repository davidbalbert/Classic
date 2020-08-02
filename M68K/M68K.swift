//
//  M68K.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Foundation

extension Data {
    func read8(_ index: Index) -> UInt8 {
        self[startIndex + index]
    }
    
    func read16(_ index: Index) -> UInt16 {
        let hi = read8(index)
        let lo = read8(index+1)
        
        return UInt16(hi) << 8 + UInt16(lo)
    }
    
    func read32(_ index: Index) -> UInt32 {
        let hi = read16(index)
        let lo = read16(index+2)
        
        return UInt32(hi) << 16 + UInt32(lo)
    }

    mutating func write8(_ index: Index, value: UInt8) {
        self[startIndex + index] = value
    }
    
    mutating func write16(_ index: Index, value: UInt16) {
        let hi = value >> 8
        let lo = value & 0xff
        
        write8(index, value: UInt8(hi))
        write8(index+1, value: UInt8(lo))
    }
    
    mutating func write32(_ index: Index, value: UInt32) {
        let hi = value >> 16
        let lo = value & 0xffff
        
        write16(index, value: UInt16(hi))
        write16(index+2, value: UInt16(lo))
    }
}

protocol AddressableDevice {
    func read8(_ address: UInt32) -> UInt8
    func read16(_ address: UInt32) -> UInt16
    func read32(_ address: UInt32) -> UInt32
    mutating func write8(_ address: UInt32, value: UInt8)
    mutating func write16(_ address: UInt32, value: UInt16)
    mutating func write32(_ address: UInt32, value: UInt32)
}

class Machine {
    var ram = RAM(count: 0x400000)
    var cpu = CPU()
    let rom: ROM
    
    init(rom: Data) {
        self.rom = ROM(data: rom)
        
        cpu.bus = self
        cpu.reset()
    }
    
    func read8(_ address: UInt32) -> UInt8 {
        let a24 = address & 0x00FFFFFF
        let device = getDevice(address: a24)
        
        return device?.read8(address) ?? 0
    }
    
    func read16(_ address: UInt32) -> UInt16 {
        let a24 = address & 0x00FFFFFF
        let device = getDevice(address: a24)
        
        return device?.read16(address) ?? 0
    }
    
    func read32(_ address: UInt32) -> UInt32 {
        let a24 = address & 0x00FFFFFF
        let device = getDevice(address: a24)
        
        return device?.read32(address) ?? 0
    }
    
    func write8(_ address: UInt32, value: UInt8) {
        let a24 = address & 0x00FFFFFF
        var device = getDevice(address: a24)

        device?.write8(address, value: value)
    }
    
    func write16(_ address: UInt32, value: UInt16) {
        let a24 = address & 0x00FFFFFF
        var device = getDevice(address: a24)

        device?.write16(address, value: value)
    }
    
    func write32(_ address: UInt32, value: UInt32) {
        let a24 = address & 0x00FFFFFF
        var device = getDevice(address: a24)

        device?.write32(address, value: value)
    }
    
    func getDevice(address: UInt32) -> AddressableDevice? {
        // This mapping is boot configuration with 
        switch address {
        case 0x0..<0x40_0000:
            return rom
        case 0x40_0000..<0x60_000:
            return rom
        case 0x60_0000..<0x60_0000+UInt32(ram.count):
            return ram
        default:
            return nil
        }
    }
}

struct RAM: AddressableDevice {
    var data: Data
    
    var count: Int {
        data.count
    }
    
    init(count: Int) {
        data = Data(count: count)
    }

    func read8(_ address: UInt32) -> UInt8 {
        data.read8(Int(address) % data.count)
    }
    
    func read16(_ address: UInt32) -> UInt16 {
        data.read16(Int(address) % data.count)
    }
    
    func read32(_ address: UInt32) -> UInt32 {
        data.read32(Int(address) % data.count)
    }
    
    mutating func write8(_ address: UInt32, value: UInt8) {
        data.write8(Int(address) % data.count, value: value)
    }
    
    mutating func write16(_ address: UInt32, value: UInt16) {
        data.write16(Int(address) % data.count, value: value)
    }
    
    mutating func write32(_ address: UInt32, value: UInt32) {
        data.write32(Int(address) % data.count, value: value)
    }
}

struct ROM: AddressableDevice {
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    func read8(_ address: UInt32) -> UInt8 {
        data.read8(Int(address) % data.count)
    }
    
    func read16(_ address: UInt32) -> UInt16 {
        data.read16(Int(address) % data.count)
    }
    
    func read32(_ address: UInt32) -> UInt32 {
        data.read32(Int(address) % data.count)
    }
    
    func write8(_ address: UInt32, value: UInt8) {}
    func write16(_ address: UInt32, value: UInt16) {}
    func write32(_ address: UInt32, value: UInt32) {}
}

struct CPU {
    var pc: UInt32
    var sr: StatusRegister
    var disassembler = Disassembler()

    var ccr: StatusRegister {
        get {
            sr.intersection(.ccr)
        }

        set {
            sr = sr.union(newValue.intersection(.ccr))
        }
    }

    var usp: UInt32
    var isp: UInt32

    var a0: UInt32
    var a1: UInt32
    var a2: UInt32
    var a3: UInt32
    var a4: UInt32
    var a5: UInt32
    var a6: UInt32

    var a7: UInt32 {
        get {
            switch sr.intersection(.stackSelectionMask) {
            case .isp:
                return isp
            default:
                return usp
            }
        }

        set {
            switch sr.intersection(.stackSelectionMask) {
            case .isp:
                isp = newValue
            default:
                usp = newValue
            }
        }
    }

    var d0: UInt32
    var d1: UInt32
    var d2: UInt32
    var d3: UInt32
    var d4: UInt32
    var d5: UInt32
    var d6: UInt32
    var d7: UInt32

    weak var bus: Machine?
    
    init() {
        pc = 0
        sr = StatusRegister()

        usp = 0
        isp = 0
        
        d0 = 0
        d1 = 0
        d2 = 0
        d3 = 0
        d4 = 0
        d5 = 0
        d6 = 0
        d7 = 0
        
        a0 = 0
        a1 = 0
        a2 = 0
        a3 = 0
        a4 = 0
        a5 = 0
        a6 = 0
    }
    
    mutating func reset() {
        isp = read32(0x0)
        pc = read32(0x4)
    }
    
    mutating func step() {
        let insn = fetchNextInstruction()
        
        pc += UInt32(insn.data.count)
        
        switch (insn.op) {
        default:
            break
        }
    }
    
    mutating func fetchNextInstruction() -> Instruction {
//        disassembler.operation(at: pc, cpu: self)
        
        Instruction(op: .unknown(0), address: pc, data: Data([0x0, 0x0]))
    }
    
    func read8(_ address: UInt32) -> UInt8 {
        bus?.read8(address) ?? 0
    }
    
    func read16(_ address: UInt32) -> UInt16 {
        bus?.read16(address) ?? 0
    }
    
    func read32(_ address: UInt32) -> UInt32 {
        bus?.read32(address) ?? 0
    }
    
    func write8(_ address: UInt32, value: UInt8) {
        bus?.write8(address, value: value)
    }
    
    func write16(_ address: UInt32, value: UInt16) {
        bus?.write16(address, value: value)
    }
    
    func write32(_ address: UInt32, value: UInt32) {
        bus?.write32(address, value: value)
    }
}


public struct StatusRegister: OptionSet {
    public let rawValue: UInt16

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public init() {
        rawValue = 0
    }
    
    // CCR bits
    public static let c = StatusRegister(rawValue: 1 << 0)
    public static let v = StatusRegister(rawValue: 1 << 1)
    public static let z = StatusRegister(rawValue: 1 << 2)
    public static let n = StatusRegister(rawValue: 1 << 3)
    public static let x = StatusRegister(rawValue: 1 << 4)

    public static let ccr: StatusRegister = [x, n, z, v, c]

    // System bits

    // Interrupt priority mask
    public static let i0 = StatusRegister(rawValue: 1 << 8)
    public static let i1 = StatusRegister(rawValue: 1 << 9)
    public static let i2 = StatusRegister(rawValue: 1 << 10)

    public static let s  = StatusRegister(rawValue: 1 << 13)

    // Trace enable
    public static let t0 = StatusRegister(rawValue: 1 << 14)

    static let all: StatusRegister = [t0, s, i2, i1, i0, x, n, z, v, c]

    // stack selection
    static let stackSelectionMask: StatusRegister = s
    static let isp: StatusRegister = s
}
