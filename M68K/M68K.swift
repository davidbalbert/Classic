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
    func readRange(_ range: Range<UInt32>) -> Data

    func write8(_ address: UInt32, value: UInt8)
    func write16(_ address: UInt32, value: UInt16)
    func write32(_ address: UInt32, value: UInt32)
    
    var readableWithoutSideEffects: Bool { get }
}

public protocol InstructionStorage {
    func read16(_ address: UInt32) -> UInt16
    func read32(_ address: UInt32) -> UInt32
    func readRange(_ range: Range<UInt32>) -> Data

    func canReadWithoutSideEffects(_ address: UInt32) -> Bool
}

protocol Bus: class {
    func read8(_ address: UInt32) -> UInt8
    func read16(_ address: UInt32) -> UInt16
    func read32(_ address: UInt32) -> UInt32

    func write8(_ address: UInt32, value: UInt8)
    func write16(_ address: UInt32, value: UInt16)
    func write32(_ address: UInt32, value: UInt32)
}

protocol Machine: Bus, InstructionStorage {
    
}

struct Mapping {
    let range: Range<UInt32>
    let device: AddressableDevice
    
    var size: UInt32 {
        UInt32(range.count)
    }
    
    var readableWithoutSideEffects: Bool {
        device.readableWithoutSideEffects
    }
}

public class MacPlus: Machine {
    let ram = RAM(count: 0x400000)
    let rom: ROM
    @Published public var cpu = CPU()
    
    var mappings: [Mapping] = []
    
    public init(rom romData: Data) {
        rom = ROM(data: romData)

        // This mapping is boot configuration which has ROM mapped at 0x0 in addition to its normal location of 0x400000
        map(0x0..<0x40_0000, to: rom)
        map(0x40_0000..<0x60_0000, to: rom)
        map(0x60_0000..<0x60_0000+UInt32(ram.count), to: ram)
        
        cpu.bus = self
        cpu.reset()
    }
    
    public func reset() {
        cpu.reset()
    }
    
    public func step() {
        cpu.step()
    }
    
    func read8(_ address: UInt32) -> UInt8 {
        let a24 = address & 0x00FFFFFF
        guard let m = mapping(for: a24) else {
            return 0
        }
        
        return m.device.read8(a24 % m.size)
    }
    
    public func read16(_ address: UInt32) -> UInt16 {
        let a24 = address & 0x00FFFFFF
        guard let m = mapping(for: a24) else {
            return 0
        }
        
        return m.device.read16(a24 % m.size)
    }
    
    public func read32(_ address: UInt32) -> UInt32 {
        let a24 = address & 0x00FFFFFF
        guard let m = mapping(for: a24) else {
            return 0
        }
        
        return m.device.read32(a24 % m.size)
    }
    
    func write8(_ address: UInt32, value: UInt8) {
        let a24 = address & 0x00FFFFFF
        guard let m = mapping(for: a24) else { return }
        
        return m.device.write8(a24 % m.size, value: value)
    }
    
    func write16(_ address: UInt32, value: UInt16) {
        let a24 = address & 0x00FFFFFF
        guard let m = mapping(for: a24) else { return }
        
        return m.device.write16(a24 % m.size, value: value)
    }
    
    func write32(_ address: UInt32, value: UInt32) {
        let a24 = address & 0x00FFFFFF
        guard let m = mapping(for: a24) else { return }
        
        return m.device.write32(a24 % m.size, value: value)
    }
    
    func map(_ range: Range<UInt32>, to device: AddressableDevice) {
        if mappings.contains(where: { $0.range.overlaps(range) }) {
            fatalError("Trying to map \(range), but some addresses in that range are already mapped")
        }
        
        mappings.append(Mapping(range: range, device: device))
    }
    
    func mapping(for address: UInt32) -> Mapping? {
        mappings.first { $0.range.contains(address) }
    }
    
    func mappings(for range: Range<UInt32>) -> [Mapping] {
        mappings.filter { $0.range.overlaps(range) }
    }
}

extension MacPlus: InstructionStorage {
    public func readRange(_ range: Range<UInt32>) -> Data {
        let r24 = (range.lowerBound & 0x00ffffff)..<(range.upperBound & 0x00ffffff)
        let ms = mappings(for: r24)
        
        if ms.count == 0 {
            return Data(repeating: 0, count: r24.count)
        } else if ms.count == 1 {
            let m = ms[0]
            return m.device.readRange((r24.lowerBound % m.size)..<(r24.upperBound % m.size))
        } else {
            fatalError("Reading acrossing mappings is not currently supported")
        }
    }

    public func canReadWithoutSideEffects(_ address: UInt32) -> Bool {
        return mapping(for: address)?.readableWithoutSideEffects ?? false
    }
}

class RAM: AddressableDevice {
    var data: Data
    
    var count: Int {
        data.count
    }
    
    var readableWithoutSideEffects: Bool {
        true
    }
    
    init(count: Int) {
        data = Data(count: count)
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
    
    func readRange(_ range: Range<UInt32>) -> Data {
        data[range]
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
}

class ROM: AddressableDevice {
    var data: Data
    
    var readableWithoutSideEffects: Bool {
        true
    }
    
    init(data: Data) {
        self.data = data
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
    
    func readRange(_ range: Range<UInt32>) -> Data {
        data[range]
    }
    
    func write8(_ address: UInt32, value: UInt8) {}
    func write16(_ address: UInt32, value: UInt16) {}
    func write32(_ address: UInt32, value: UInt32) {}
}


// overflow
func vsub(_ s: UInt8, _ d: UInt8, _ r: UInt8) -> Bool {
    return ((s^d) & (r^d)) >> 7 == 1
}

func vsub(_ s: UInt16, _ d: UInt16, _ r: UInt16) -> Bool {
    return ((s^d) & (r^d)) >> 15 == 1
}

func vsub(_ s: UInt32, _ d: UInt32, _ r: UInt32) -> Bool {
    return ((s^d) & (r^d)) >> 31 == 1
}

public struct CPU {
    public var pc: UInt32
    public var sr: StatusRegister
    public var disassembler = Disassembler()

    public var ccr: StatusRegister {
        get {
            sr.intersection(.ccr)
        }

        set {
            sr.remove(.ccr)
            sr = sr.union(newValue.intersection(.ccr))            
        }
    }
    
    var inSupervisorMode: Bool {
        sr.contains(.s)
    }

    public var usp: UInt32
    public var isp: UInt32

    public var a0: UInt32
    public var a1: UInt32
    public var a2: UInt32
    public var a3: UInt32
    public var a4: UInt32
    public var a5: UInt32
    public var a6: UInt32

    public var a7: UInt32 {
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

    public var d0: UInt32
    public var d1: UInt32
    public var d2: UInt32
    public var d3: UInt32
    public var d4: UInt32
    public var d5: UInt32
    public var d6: UInt32
    public var d7: UInt32

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
        sr.insert(.s)
        sr.remove(.t0)
        
        isp = read32(0x0)
        pc = read32(0x4)
    }
    
    mutating func step() {
        let insn = fetchNextInstruction()
        execute(insn.op, length: insn.length)
    }
    
    mutating func execute(_ op: Operation, length: Int) {
        pc += UInt32(length)
        
        switch (op) {
        case let .bra(_, pc, displacement):
            self.pc = UInt32(Int64(pc) + Int64(displacement))
        case let .bcc(_, condition, pc, displacement):
            if conditionIsSatisfied(condition) {
                self.pc = UInt32(Int64(pc) + Int64(displacement))
            }
        case let .cmpi(.b, source, destination):
            let destination = UInt8(truncatingIfNeeded: readEffectiveAddress(destination, size: .b))
            let source = UInt8(truncatingIfNeeded: source)
            let res = destination &- source
            
            var cc = ccr.intersection(.x)
            
            let overflow = vsub(source, destination, res)
                        
            if res >= 0x80          { cc.insert(.n) }
            if res == 0             { cc.insert(.z) }
            if overflow             { cc.insert(.v) }
            if source > destination { cc.insert(.c) }
            
            ccr = cc
        case let .cmpi(.w, source, destination):
            let destination = UInt16(truncatingIfNeeded: readEffectiveAddress(destination, size: .w))
            let source = UInt16(truncatingIfNeeded: source)
            let res = destination &- source
            
            var cc = ccr.intersection(.x)
            
            let overflow = vsub(source, destination, res)
                        
            if res >= 0x8000        { cc.insert(.n) }
            if res == 0             { cc.insert(.z) }
            if overflow             { cc.insert(.v) }
            if source > destination { cc.insert(.c) }
            
            ccr = cc
        case let .cmpi(.l, source, destination):
            let destination = readEffectiveAddress(destination, size: .l)
            let source = UInt32(bitPattern: source)
            let res = destination &- source
            
            var cc = ccr.intersection(.x)
            
            let overflow = vsub(source, destination, res)
                        
            if res >= 0x80000000    { cc.insert(.n) }
            if res == 0             { cc.insert(.z) }
            if overflow             { cc.insert(.v) }
            if source > destination { cc.insert(.c) }
            
            ccr = cc
        case let .jmp(address):
            pc = loadEffectiveAddress(address)!
        case let .lea(address, register):
            let value = loadEffectiveAddress(address)!
            
            self[keyPath: register.keyPath] = value
        case let .movem(size, .mToR, address, registers):
            let inc = Size(size).byteCount

            switch address {
            case let .XXXl(addr):
                var a = addr
                for path in registers.keyPaths {
                    self[keyPath: path] = read32(a)
                    a += inc
                }
            default:
                fatalError("movem: unsupported address type")
            }
        case let .moveq(data, Dn):
            self[keyPath: Dn.keyPath] = UInt32(truncatingIfNeeded: data)
            
            var cc = ccr.intersection(.x)

            if data < 0             { cc.insert(.n) }
            if data == 0            { cc.insert(.z) }

            ccr = cc
        case let .moveToSR(address):
            if !inSupervisorMode {
                fatalError("moveToSR but not supervisor, should trap here")
            }
                
            let value = UInt16(truncatingIfNeeded: readEffectiveAddress(address, size: .w))
            
            sr = StatusRegister(rawValue: value)
        case let .tst(.b, destination):
            let destination = UInt8(truncatingIfNeeded: readEffectiveAddress(destination, size: .b))
            
            var cc = ccr.intersection(.x)

            if destination > 0x80   { cc.insert(.n) }
            if destination == 0     { cc.insert(.z) }

            ccr = cc
        case let .tst(.w, destination):
            let destination = UInt16(truncatingIfNeeded: readEffectiveAddress(destination, size: .b))
            
            var cc = ccr.intersection(.x)

            if destination > 0x8000 { cc.insert(.n) }
            if destination == 0     { cc.insert(.z) }

            ccr = cc
        case let .tst(.l, destination):
            let destination = readEffectiveAddress(destination, size: .b)
            
            var cc = ccr.intersection(.x)

            if destination > 0x80000000 { cc.insert(.n) }
            if destination == 0         { cc.insert(.z) }

            ccr = cc
        default:
            break
        }
    }
    
    func fetchNextInstruction() -> Instruction {
        disassembler.instruction(at: pc, storage: bus!)
    }
    
    func conditionIsSatisfied(_ conditionCode: Condition) -> Bool {
        switch conditionCode {
        case .t: return true
        case .f: return false
        case .hi: return !sr.contains(.c) && !sr.contains(.z)
        case .ls: return sr.contains(.c) || sr.contains(.z)
        case .cc: return !sr.contains(.c)
        case .cs: return sr.contains(.c)
        case .ne: return !sr.contains(.z)
        case .eq: return sr.contains(.z)
        case .vc: return !sr.contains(.v)
        case .vs: return sr.contains(.v)
        case .pl: return !sr.contains(.n)
        case .mi: return sr.contains(.n)
        case .ge: return sr.contains(.n) == sr.contains(.v)
        case .lt: return sr.contains(.n) != sr.contains(.v)
        case .gt: return !sr.contains(.z) && (sr.contains(.n) == sr.contains(.v))
        case .le: return sr.contains(.z) || (sr.contains(.n) != sr.contains(.v))
        }
    }
    
    mutating func readEffectiveAddress(_ effectiveAddress: EffectiveAddress, size: Size) -> UInt32 {
        switch effectiveAddress {
        case let .dd(Dn):
            return self[keyPath: Dn.keyPath]
        case let .ad(An):
            return self[keyPath: An.keyPath]
        case let .ind(An):
            let address = self[keyPath: An.keyPath]
            
            return read(address, size: size)
        case let .postInc(An):
            let address = self[keyPath: An.keyPath]
            self[keyPath: An.keyPath] += size.byteCount
            
            return read(address, size: size)
        case let .preDec(An):
            self[keyPath: An.keyPath] -= size.byteCount
            let address = self[keyPath: An.keyPath]
            
            return read(address, size: size)
        case let .d16An(displacement, An):
            let address = UInt32(Int64(self[keyPath: An.keyPath]) + Int64(displacement))
            
            return read(address, size: size)
        case .d8AnXn(_, _, _, _):
            fatalError("d8AnXn not implemented")
        case let .XXXw(address):
            return read(address, size: size)
        case let .XXXl(address):
            return read(address, size: size)
        case let .d16PC(pc, displacement):
            let address = UInt32(Int64(pc) + Int64(displacement))
            
            return read(address, size: size)
        case .d8PCXn(_, _, _, _):
            fatalError("d8PCXn not implemented yet")
        case let .imm(value):
            return UInt32(value)
        }
    }
    
    func loadEffectiveAddress(_ address: EffectiveAddress) -> UInt32? {
        switch address {
        case let .ind(An):
            return self[keyPath: An.keyPath]
        case let .d16An(d, An):
            return UInt32(Int64(self[keyPath: An.keyPath]) + Int64(d))
        case .d8AnXn(_, _, _, _):
            fatalError("d8AnXn not implemented")
        case let .XXXl(address):
            return address
        case let .XXXw(address):
            return address
        case let .d16PC(pc, d):
            return UInt32(Int64(pc) + Int64(d))
        case .d8PCXn(_, _, _, _):
            fatalError("d8PCXn not implemented")
        default:
            return nil
        }
    }
    
    func read(_ address: UInt32, size: Size) -> UInt32 {
        switch size {
        case .b: return UInt32(read8(address))
        case .w: return UInt32(read16(address))
        case .l: return read32(address)
        }
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


public struct StatusRegister: OptionSet, Hashable {
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
    public static let stackSelectionMask: StatusRegister = s
    public static let isp: StatusRegister = s
}
