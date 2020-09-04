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
private func vadd(_ s: UInt8, _ d: UInt8, _ r: UInt8) -> Bool {
    return ((s^r) & (d^r)) >> 7 == 1
}

private func vadd(_ s: UInt16, _ d: UInt16, _ r: UInt16) -> Bool {
    return ((s^r) & (d^r)) >> 15 == 1
}

private func vadd(_ s: UInt32, _ d: UInt32, _ r: UInt32) -> Bool {
    return ((s^r) & (d^r)) >> 31 == 1
}


private func vsub(_ s: UInt8, _ d: UInt8, _ r: UInt8) -> Bool {
    return ((s^d) & (r^d)) >> 7 == 1
}

private func vsub(_ s: UInt16, _ d: UInt16, _ r: UInt16) -> Bool {
    return ((s^d) & (r^d)) >> 15 == 1
}

private func vsub(_ s: UInt32, _ d: UInt32, _ r: UInt32) -> Bool {
    return ((s^d) & (r^d)) >> 31 == 1
}

// negative flag
private func neg(_ v: UInt8) -> Bool {
    v >= 0x80
}

private func neg(_ v: UInt16) -> Bool {
    v >= 0x8000
}

private func neg(_ v: UInt32) -> Bool {
    v >= 0x8000_0000
}


typealias InstructionHandler = (inout CPU) -> Void

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
    
    var c: Bool {
        get { sr.contains(.c) }
        
        set {
            if newValue {
                sr.insert(.c)
            } else {
                sr.remove(.c)
            }
        }
    }
    
    var v: Bool {
        get { sr.contains(.v) }
        
        set {
            if newValue {
                sr.insert(.v)
            } else {
                sr.remove(.v)
            }
        }
    }
    
    var z: Bool {
        get { sr.contains(.z) }
        
        set {
            if newValue {
                sr.insert(.z)
            } else {
                sr.remove(.z)
            }
        }
    }
    
    var n: Bool {
        get { sr.contains(.n) }
        
        set {
            if newValue {
                sr.insert(.n)
            } else {
                sr.remove(.n)
            }
        }
    }
    
    var x: Bool {
        get { sr.contains(.x) }
        
        set {
            if newValue {
                sr.insert(.x)
            } else {
                sr.remove(.x)
            }
        }
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
        
        guard let handler = handler(for: op) else { return }
        
        handler(&self)
    }
    
    public func implements(_ insn: Instruction) -> Bool {
        handler(for: insn.op) != nil
    }
    
    func handler(for op: Operation) -> InstructionHandler? {
        switch op {
        case let .addMR(.b, address, Dn):
            return { cpu in
                let v1 = cpu.read(address, UInt8.self)
                let v2 = cpu.readD8(Dn)
                                
                let res = v1 &+ v2
                cpu.writeD8(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vadd(v1, v2, res)
                cpu.c = res < v1
                cpu.x = cpu.c
            }
        case let .addMR(.w, address, Dn):
            return { cpu in
                let v1 = cpu.read(address, UInt16.self)
                let v2 = cpu.readD16(Dn)

                let res = v1 &+ v2
                cpu.writeD16(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vadd(v1, v2, res)
                cpu.c = res < v1
                cpu.x = cpu.c
            }
        case let .addMR(.l, address, Dn):
            return { cpu in
                let v1 = cpu.read(address, UInt32.self)
                let v2 = cpu.readD32(Dn)

                let res = v1 &+ v2
                cpu.writeD32(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vadd(v1, v2, res)
                cpu.c = res < v1
                cpu.x = cpu.c
            }
        case let .addRM(.b, Dn, ea):
            return { cpu in
                let addr = cpu.address(for: ea, size: .b)
                let v1 = cpu.read8(addr)
                let v2 = cpu.readD8(Dn)
                
                let res = v1 &+ v2
                cpu.write8(addr, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vadd(v1, v2, res)
                cpu.c = res < v1
                cpu.x = cpu.c
            }
        case let .addRM(.w, Dn, ea):
            return { cpu in
                let addr = cpu.address(for: ea, size: .w)
                let v1 = cpu.read16(addr)
                let v2 = cpu.readD16(Dn)
                
                let res = v1 &+ v2
                cpu.write16(addr, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vadd(v1, v2, res)
                cpu.c = res < v1
                cpu.x = cpu.c
            }
        case let .addRM(.l, Dn, ea):
            return { cpu in
                let addr = cpu.address(for: ea, size: .l)
                let v1 = cpu.read32(addr)
                let v2 = cpu.readD32(Dn)
                
                let res = v1 &+ v2
                cpu.write32(addr, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vadd(v1, v2, res)
                cpu.c = res < v1
                cpu.x = cpu.c
            }
        case let .andMR(.b, ea, Dn):
            return { cpu in
                let v1 = cpu.read(EffectiveAddress(ea), UInt8.self)
                let v2 = cpu.readD8(Dn)
                                
                let res = v1 & v2
                cpu.writeD8(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andMR(.w, ea, Dn):
            return { cpu in
                let v1 = cpu.read(EffectiveAddress(ea), UInt16.self)
                let v2 = cpu.readD16(Dn)

                let res = v1 & v2
                cpu.writeD16(Dn, value: res)

                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andMR(.l, ea, Dn):
            return { cpu in
                let v1 = cpu.read(EffectiveAddress(ea), UInt32.self)
                let v2 = cpu.readD32(Dn)

                let res = v1 & v2
                cpu.writeD32(Dn, value: res)

                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andRM(.b, Dn, ea):
            return { cpu in
                let v1 = cpu.readD8(Dn)
                let addr = cpu.address(for: ea, size: .b)
                let v2 = cpu.read8(addr)
                
                let res = v1 & v2
                cpu.write8(addr, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andRM(.w, Dn, ea):
            return { cpu in
                let v1 = cpu.readD16(Dn)
                let addr = cpu.address(for: ea, size: .w)
                let v2 = cpu.read16(addr)
                
                let res = v1 & v2
                cpu.write16(addr, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andRM(.l, Dn, ea):
            return { cpu in
                let v1 = cpu.readD32(Dn)
                let addr = cpu.address(for: ea, size: .l)
                let v2 = cpu.read32(addr)
                
                let res = v1 & v2
                cpu.write32(addr, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andi(.b, data, .dd(Dn)):
            return { cpu in
                let current = cpu.readD8(Dn)
                let data = UInt8(truncatingIfNeeded: data)

                let res = current & data
                cpu.writeD8(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andi(.b, data, .m(ea)):
            return { cpu in
                let addr = cpu.address(for: ea, size: .b)
                let current = cpu.read8(addr)
                let data = UInt8(truncatingIfNeeded: data)

                let res = current & data
                cpu.write8(addr, value: res)
                                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andi(.w, data, .dd(Dn)):
            return { cpu in
                let current = cpu.readD16(Dn)
                let data = UInt16(truncatingIfNeeded: data)

                let res = current & data
                cpu.writeD16(Dn, value: res)

                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andi(.w, data, .m(ea)):
            return { cpu in
                let addr = cpu.address(for: ea, size: .b)
                let current = cpu.read16(addr)
                let data = UInt16(truncatingIfNeeded: data)

                let res = current & data
                cpu.write16(addr, value: res)

                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andi(.l, data, .dd(Dn)):
            return { cpu in
                let current = cpu.readD32(Dn)
                let data = UInt32(bitPattern: data)

                let res = current & data
                cpu.writeD32(Dn, value: res)

                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andi(.l, data, .m(ea)):
            return { cpu in
                let addr = cpu.address(for: ea, size: .b)
                let current = cpu.read32(addr)
                let data = UInt32(bitPattern: data)

                let res = current & data
                cpu.write32(addr, value: res)

                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .bcc(_, condition, pc, displacement):
            return { cpu in
                if cpu.conditionIsSatisfied(condition) {
                    cpu.pc = UInt32(Int64(pc) + Int64(displacement))
                }
            }
        case let .bra(_, pc, displacement):
            return { cpu in
                cpu.pc = UInt32(Int64(pc) + Int64(displacement))
            }
        case let .bset(.imm(n), .dd(Dn)):
            return { cpu in
                let bit: UInt32 = 1 << (UInt32(n) % 32)
                
                let v = cpu.readD32(Dn)
                cpu.writeD32(Dn, value: v | bit)
                
                cpu.z = v & bit == 0
            }
        case let .bset(.imm(n), .m(ea)):
            return { cpu in
                let bit = 1 << (n%8)
                let address = cpu.address(for: ea, size: .b)
                
                let v = cpu.read8(address)
                cpu.write8(address, value: v | bit)
                
                cpu.z = v & bit == 0
            }
        case let .bset(.r(bitNumberRegister), .dd(Dn)):
            return { cpu in
                let n = cpu.readD32(bitNumberRegister)
                
                let bit = 1 << (n%32)
                
                let v = cpu.readD32(Dn)
                cpu.writeD32(Dn, value: v | bit)
                
                cpu.z = v & bit == 0
            }
        case let .bset(.r(bitNumberRegister), .m(ea)):
            return { cpu in
                let n = UInt8(cpu[keyPath: bitNumberRegister.keyPath])

                let bit = 1 << (n%8)
                let address = cpu.address(for: ea, size: .b)

                let v = cpu.read8(address)
                cpu.write8(address, value: v | bit)
                
                cpu.z = v & bit == 0
            }
        case let .cmpi(.b, source, destination):
            return { cpu in
                let destination = cpu.read(EffectiveAddress(destination), UInt8.self)
                let source = UInt8(truncatingIfNeeded: source)
                let res = destination &- source
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vsub(source, destination, res)
                cpu.c = source > destination
            }
        case let .cmpi(.w, source, destination):
            return { cpu in
                let destination = cpu.read(EffectiveAddress(destination), UInt16.self)
                let source = UInt16(truncatingIfNeeded: source)
                let res = destination &- source
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vsub(source, destination, res)
                cpu.c = source > destination
            }
        case let .cmpi(.l, source, destination):
            return { cpu in
                let destination = cpu.read(EffectiveAddress(destination), UInt32.self)
                let source = UInt32(bitPattern: source)
                let res = destination &- source
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vsub(source, destination, res)
                cpu.c = source > destination
            }
        case let .dbcc(condition, Dn, pc, displacement):
            return { cpu in
                if cpu.conditionIsSatisfied(condition) {
                    return
                }
                
                var count = cpu.readD16(Dn)
                count = count &- 1
                cpu.writeD16(Dn, value: count)
                
                if count != UInt16(bitPattern: -1) {
                    cpu.pc = UInt32(Int64(pc) + Int64(displacement))
                }
            }
        case let .jmp(address):
            return { cpu in
                cpu.pc = cpu.address(for: address)
            }
        case let .lea(ea, An):
            return { cpu in
                let address = cpu.address(for: ea)
                
                cpu.writeA32(An, value: address)
            }
        case let .move(.b, src, .dd(Dn)):
            return { cpu in
                let data = cpu.read(src, UInt8.self)
                cpu.writeD8(Dn, value: data)
                
                cpu.n = neg(data)
                cpu.z = data == 0
                cpu.v = false
                cpu.c = false
            }
        case let .move(.b, src, .m(ea)):
            return { cpu in
                let data = cpu.read(src, UInt8.self)
                
                let addr = cpu.address(for: ea, size: .b)
                cpu.write8(addr, value: data)
                
                cpu.n = neg(data)
                cpu.z = data == 0
                cpu.v = false
                cpu.c = false
            }
        case let .move(.w, src, .dd(Dn)):
            return { cpu in
                let data = cpu.read(src, UInt16.self)
                cpu.writeD16(Dn, value: data)
                
                cpu.n = neg(data)
                cpu.z = data == 0
                cpu.v = false
                cpu.c = false
            }
        case let .move(.w, src, .m(ea)):
            return { cpu in
                let data = cpu.read(src, UInt16.self)
                
                let addr = cpu.address(for: ea, size: .w)
                cpu.write16(addr, value: data)
                
                cpu.n = neg(data)
                cpu.z = data == 0
                cpu.v = false
                cpu.c = false
            }
        case let .move(.l, src, .dd(Dn)):
            return { cpu in
                let data = cpu.read(src, UInt32.self)
                cpu.writeD32(Dn, value: data)

                cpu.n = neg(data)
                cpu.z = data == 0
                cpu.v = false
                cpu.c = false
            }
        case let .move(.l, src, .m(ea)):
            return { cpu in
                let data = cpu.read(src, UInt32.self)
                
                let addr = cpu.address(for: ea, size: .l)
                cpu.write32(addr, value: data)

                cpu.n = neg(data)
                cpu.z = data == 0
                cpu.v = false
                cpu.c = false
            }
        case let .movea(.w, src, An):
            return { cpu in
                let data = cpu.read(src, UInt16.self)
                cpu.writeA16(An, value: data)
            }
        case let .movea(.l, src, An):
            return { cpu in
                let data = cpu.read(src, UInt32.self)
                cpu.writeA32(An, value: data)
            }
        case let .movemMR(.w, .postInc(An), registers):
            return nil
        case let .movemMR(.w, .c(ea), registers):
            return nil
        case let .movemMR(.l, .postInc(An), registers):
            return nil
        case let .movemMR(.l, .c(ea), registers):
            return nil
        case let .movemRM(.w, registers, .preDec(An)):
            return { cpu in
                for Rn in registers.registers.reversed() {
                    let addr = cpu.address(for: MemoryAddress.preDec(An), size: .w)
                    cpu.write16(addr, value: cpu.readR16(Rn))
                }
            }
        case let .movemRM(.w, registers, .c(ea)):
            return { cpu in
                var addr = cpu.address(for: ea)
                
                for Rn in registers.registers {
                    cpu.write16(addr, value: cpu.readR16(Rn))
                    addr += 2
                }
            }
        case let .movemRM(.l, registers, .preDec(An)):
            return nil
        case let .movemRM(.l, registers, .c(ea)):
            return nil
//        case let .movemMR(size, address, registers):
//            return { cpu in
//                let inc = Size(size).byteCount
//
//                switch address {
//                case let .XXXl(addr):
//                    var a = addr
//                    for path in registers.keyPaths {
//                        cpu[keyPath: path] = cpu.read32(a)
//                        a += inc
//                    }
//                default:
//                    fatalError("movem: unsupported address type")
//                }
//            }
        case let .moveq(data, Dn):
            return { cpu in
                cpu[keyPath: Dn.keyPath] = UInt32(truncatingIfNeeded: data)
                
                var cc = cpu.ccr.intersection(.x)

                if data < 0             { cc.insert(.n) }
                if data == 0            { cc.insert(.z) }

                cpu.ccr = cc
            }
        case let .moveToSR(address):
            return { cpu in
                if !cpu.inSupervisorMode {
                    fatalError("moveToSR but not supervisor, should trap here")
                }
                    
                let value = cpu.read(EffectiveAddress(address), UInt16.self)

                cpu.sr = StatusRegister(rawValue: value)
            }
        case let .oriToSR(value):
            return { cpu in
                if !cpu.inSupervisorMode {
                    fatalError("moveToSR but not supervisor, should trap here")
                }

                let value = UInt16(truncatingIfNeeded: value)
                let current = cpu.sr.rawValue
                cpu.sr = StatusRegister(rawValue: value | current)
            }
        case let .ror(.b, .imm(count), Dn):
            return { cpu in
                var v = UInt8(truncatingIfNeeded: cpu[keyPath: Dn.keyPath])
                
                // starting carry at 0 clears the carry bit if count == 0
                var carry: UInt8 = 0
                
                for _ in 0..<count {
                    carry = v & 1
                    v >>= 1
                }
                
                cpu.writeEffectiveAddress(.dd(Dn), value: UInt32(truncatingIfNeeded: v), size: .b)
                
                var cc = cpu.ccr.intersection(.x)
                
                if v >= 0x80     { cc.insert(.n) }
                if v == 0        { cc.insert(.z) }
                if carry == 1    { cc.insert(.c) }
                
                cpu.ccr = cc
            }
        case let .ror(.w, .imm(count), Dn):
            return { cpu in
                var v = UInt16(truncatingIfNeeded: cpu[keyPath: Dn.keyPath])
                
                // starting carry at 0 clears the carry bit if count == 0
                var carry: UInt16 = 0
                
                for _ in 0..<count {
                    carry = v & 1
                    v >>= 1
                }
                
                cpu.writeEffectiveAddress(.dd(Dn), value: UInt32(truncatingIfNeeded: v), size: .b)
                
                var cc = cpu.ccr.intersection(.x)
                
                if v >= 0x8000   { cc.insert(.n) }
                if v == 0        { cc.insert(.z) }
                if carry == 1    { cc.insert(.c) }
                
                cpu.ccr = cc
            }
        case let .ror(.l, .imm(count), Dn):
            return { cpu in
                var v = cpu[keyPath: Dn.keyPath]
                
                // starting carry at 0 clears the carry bit if count == 0
                var carry: UInt32 = 0
                
                for _ in 0..<count {
                    carry = v & 1
                    v >>= 1
                }
                
                cpu.writeEffectiveAddress(.dd(Dn), value: UInt32(truncatingIfNeeded: v), size: .b)
                
                var cc = cpu.ccr.intersection(.x)
                
                if v >= 0x8000_0000   { cc.insert(.n) }
                if v == 0             { cc.insert(.z) }
                if carry == 1         { cc.insert(.c) }
                
                cpu.ccr = cc
            }
        case let .roxl(.b, .imm(count), Dn):
            return { cpu in
                var v = UInt8(truncatingIfNeeded: cpu[keyPath: Dn.keyPath])
                
                var extend: UInt8 = cpu.ccr.contains(.x) ? 1 : 0
                
                for _ in 0..<count {
                    let prevExtend = extend
                    extend = v >> 7
                    v = (v << 1) | prevExtend
                }
                
                cpu.writeEffectiveAddress(.dd(Dn), value: UInt32(truncatingIfNeeded: v), size: .b)
                
                var cc = StatusRegister()
                
                if v >= 0x80     { cc.insert(.n) }
                if v == 0        { cc.insert(.z) }
                if extend == 1   { cc.insert(.x); cc.insert(.c) }
                
                cpu.ccr = cc
            }
        case let .roxl(.w, .imm(count), Dn):
            return { cpu in
                var v = UInt16(truncatingIfNeeded: cpu[keyPath: Dn.keyPath])
                
                var extend: UInt16 = cpu.ccr.contains(.x) ? 1 : 0
                
                for _ in 0..<count {
                    let prevExtend = extend
                    extend = v >> 15
                    v = (v << 1) | prevExtend
                }
                
                cpu.writeEffectiveAddress(.dd(Dn), value: UInt32(truncatingIfNeeded: v), size: .w)
                
                var cc = StatusRegister()
                
                if v >= 0x8000     { cc.insert(.n) }
                if v == 0          { cc.insert(.z) }
                if extend == 1     { cc.insert(.x); cc.insert(.c) }
                
                cpu.ccr = cc
            }
        case let .roxl(.l, .imm(count), Dn):
            return { cpu in
                var v = cpu[keyPath: Dn.keyPath]
                
                var extend: UInt32 = cpu.ccr.contains(.x) ? 1 : 0
                
                for _ in 0..<count {
                    let prevExtend = extend
                    extend = v >> 15
                    v = (v << 1) | prevExtend
                }
                
                cpu.writeEffectiveAddress(.dd(Dn), value: UInt32(truncatingIfNeeded: v), size: .l)
                
                var cc = StatusRegister()
                
                if v >= 0x8000_0000 { cc.insert(.n) }
                if v == 0           { cc.insert(.z) }
                if extend == 1      { cc.insert(.x); cc.insert(.c) }
                
                cpu.ccr = cc
            }
        case let .suba(.w, sourceAddress, An):
            return { cpu in
                let destination = UInt16(truncatingIfNeeded: cpu[keyPath: An.keyPath])
                let source = UInt16(truncatingIfNeeded: cpu.read(from: sourceAddress, size: .w))
                let res = destination &- source
                
                cpu[keyPath: An.keyPath] = UInt32(truncatingIfNeeded: res)
            }
        case let .suba(.l, sourceAddress, An):
            return { cpu in
                let destination = cpu[keyPath: An.keyPath]
                let source = cpu.read(from: sourceAddress, size: .l)
                let res = destination &- source
                
                cpu[keyPath: An.keyPath] = res
            }
        case let .subqB(data, .dd(Dn)):
            return { cpu in
                let v = cpu.readD8(Dn)
                let res = v &- data
                cpu.writeD8(Dn, value: res)
                
                let overflow = vsub(data, v, res)
                var cc = StatusRegister()

                if res >= 0x80          { cc.insert(.n) }
                if res == 0             { cc.insert(.z) }
                if overflow             { cc.insert(.v) }
                if data > v             { cc.insert(.c); cc.insert(.x) }
                
                cpu.ccr = cc
            }
        case let .subqB(data, .m(ea)):
            return { cpu in
                let addr = cpu.address(for: ea, size: .b)
                let v = cpu.read8(addr)
                
                let res = v &- data
                cpu.write8(addr, value: res)
                                
                let overflow = vsub(data, v, res)
                var cc = StatusRegister()

                if res >= 0x80          { cc.insert(.n) }
                if res == 0             { cc.insert(.z) }
                if overflow             { cc.insert(.v) }
                if data > v             { cc.insert(.c); cc.insert(.x) }
                
                cpu.ccr = cc
            }
        case let .subqWL(.w, data, .dd(Dn)):
            return { cpu in
                let v = cpu.readD16(Dn)
                let data = UInt16(data)
                let res = v &- data
                
                cpu.writeD16(Dn, value: res)
                
                let overflow = vsub(data, v, res)
                var cc = StatusRegister()

                if res >= 0x8000        { cc.insert(.n) }
                if res == 0             { cc.insert(.z) }
                if overflow             { cc.insert(.v) }
                if data > v             { cc.insert(.c); cc.insert(.x) }
                
                cpu.ccr = cc
            }
        case let .subqWL(.w, data, .ad(An)):
            return { cpu in
                let v = cpu.readA16(An)
                let data = UInt16(data)
                let res = v &- data
                
                cpu.writeA16(An, value: res)
            }
        case let .subqWL(.w, data, .m(ea)):
            return { cpu in
                let addr = cpu.address(for: ea, size: .w)
                let v = cpu.read16(addr)
                let data = UInt16(data)
                
                let res = v &- data
                cpu.write16(addr, value: res)
                                
                let overflow = vsub(data, v, res)
                var cc = StatusRegister()

                if res >= 0x8000        { cc.insert(.n) }
                if res == 0             { cc.insert(.z) }
                if overflow             { cc.insert(.v) }
                if data > v             { cc.insert(.c); cc.insert(.x) }
                
                cpu.ccr = cc
            }
        case let .subqWL(.l, data, .dd(Dn)):
            return { cpu in
                let v = cpu.readD32(Dn)
                let data = UInt32(data)
                let res = v &- data
                
                cpu.writeD32(Dn, value: res)
                
                let overflow = vsub(data, v, res)
                var cc = StatusRegister()

                if res >= 0x8000_0000   { cc.insert(.n) }
                if res == 0             { cc.insert(.z) }
                if overflow             { cc.insert(.v) }
                if data > v             { cc.insert(.c); cc.insert(.x) }
                
                cpu.ccr = cc
            }
        case let .subqWL(.l, data, .ad(An)):
            return { cpu in
                let v = cpu.read(from: .ad(An), size: .l)
                let data = UInt32(data)
                let res = v &- data

                cpu.writeEffectiveAddress(.ad(An), value: UInt32(truncatingIfNeeded: res), size: .l)
            }
        case let .subqWL(.l, data, .m(ea)):
            return { cpu in
                let addr = cpu.address(for: ea, size: .l)
                let v = cpu.read32(addr)
                let data = UInt32(data)
                
                let res = v &- data
                cpu.write32(addr, value: data)
                                                
                let overflow = vsub(data, v, res)
                var cc = StatusRegister()

                if res >= 0x8000_0000   { cc.insert(.n) }
                if res == 0             { cc.insert(.z) }
                if overflow             { cc.insert(.v) }
                if data > v             { cc.insert(.c); cc.insert(.x) }
                
                cpu.ccr = cc
            }
        case let .tst(.b, destination):
            return { cpu in
                let destination = UInt8(truncatingIfNeeded: cpu.read(from: destination, size: .b))
                
                var cc = cpu.ccr.intersection(.x)

                if destination > 0x80   { cc.insert(.n) }
                if destination == 0     { cc.insert(.z) }

                cpu.ccr = cc
            }
        case let .tst(.w, destination):
            return { cpu in
                let destination = UInt16(truncatingIfNeeded: cpu.read(from: destination, size: .b))
                
                var cc = cpu.ccr.intersection(.x)

                if destination > 0x8000 { cc.insert(.n) }
                if destination == 0     { cc.insert(.z) }

                cpu.ccr = cc
            }
        case let .tst(.l, destination):
            return { cpu in
                let destination = cpu.read(from: destination, size: .b)
                
                var cc = cpu.ccr.intersection(.x)

                if destination > 0x80000000 { cc.insert(.n) }
                if destination == 0         { cc.insert(.z) }

                cpu.ccr = cc
            }
        default:
            return nil
        }
    }
    
    public func fetchNextInstruction() -> Instruction {
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
    
    mutating func read(from effectiveAddress: EffectiveAddress, size: Size) -> UInt32 {
        switch effectiveAddress {
        case let .dd(Dn):
            return self[keyPath: Dn.keyPath]
        case let .ad(An):
            return self[keyPath: An.keyPath]
        case let .m(.ind(An)):
            let address = self[keyPath: An.keyPath]
            
            return read(address, size: size)
        case let .m(.postInc(An)):
            let address = self[keyPath: An.keyPath]
            self[keyPath: An.keyPath] += size.byteCount
            
            return read(address, size: size)
        case let .m(.preDec(An)):
            self[keyPath: An.keyPath] -= size.byteCount
            let address = self[keyPath: An.keyPath]
            
            return read(address, size: size)
        case let .m(.d16An(d, An)):
            let address = UInt32(truncatingIfNeeded: Int64(self[keyPath: An.keyPath]) + Int64(d))
            
            return read(address, size: size)
        case .m(.d8AnXn(_, _, _, _)):
            fatalError("d8AnXn not implemented")
        case let .m(.XXXw(address)):
            return read(address, size: size)
        case let .m(.XXXl(address)):
            return read(address, size: size)
        case let .m(.d16PC(pc, displacement)):
            let address = UInt32(Int64(pc) + Int64(displacement))
            
            return read(address, size: size)
        case .m(.d8PCXn(_, _, _, _)):
            fatalError("d8PCXn not implemented yet")
        case let .imm(value):
            return UInt32(truncatingIfNeeded: value)
        }
    }
    
    mutating func writeEffectiveAddress(_ effectiveAddress: EffectiveAddress, value: UInt32, size: Size) {
        switch effectiveAddress {
        case let .dd(Dn):
            let existingMask: UInt32
            let newMask: UInt32
            switch size {
            case .b:
                existingMask = 0xffffff00
                newMask      = 0x000000ff
            case .w:
                existingMask = 0xffff0000
                newMask      = 0x0000ffff
            case .l:
                existingMask = 0x00000000
                newMask      = 0xffffffff
            }
            
            let existing = self[keyPath: Dn.keyPath]
            
            self[keyPath: Dn.keyPath] = (existing & existingMask) | (value & newMask)
        case let .ad(An):
            self[keyPath: An.keyPath] = UInt32(truncatingIfNeeded: value)
        case let .m(.ind(An)):
            let address = self[keyPath: An.keyPath]
            
            write(address, value, size: size)
        case let .m(.postInc(An)):
            let address = self[keyPath: An.keyPath]
            self[keyPath: An.keyPath] += 2
            
            write(address, value, size: size)
        case let .m(.preDec(An)):
            self[keyPath: An.keyPath] -= 2
            let address = self[keyPath: An.keyPath]
            
            write(address, value, size: size)
        case let .m(.d16An(d, An)):
            let address = UInt32(Int64(self[keyPath: An.keyPath]) + Int64(d))
            
            write(address, value, size: size)
        case .m(.d8AnXn(_, _, _, _)):
            fatalError("d8AnXn not implemented")
        case let .m(.XXXw(address)):
            write(address, value, size: size)
        case let .m(.XXXl(address)):
            write(address, value, size: size)
        case let .m(.d16PC(pc, d)):
            let address = UInt32(Int64(pc) + Int64(d))

            write(address, value, size: size)
        case .m(.d8PCXn(_, _, _, _)):
            fatalError("d8PCXn not implemented")
        case .imm(_):
            fatalError("can't write to an immediate value")
        }
    }
    
    
    mutating func address(for ea: ControlAddress) -> UInt32 {
        // Control addressing modes don't require size to evaluate
        // the address. The .b is unused.
        address(for: MemoryAddress(ea), size: .b)
    }
    
    mutating func address(for ea: ControlAlterableAddress) -> UInt32 {
        // Control addressing modes don't require size to evaluate
        // the address. The .b is unused.
        address(for: MemoryAddress(ea), size: .b)
    }
        
    mutating func address(for ea: MemoryAlterableAddress, size: Size) -> UInt32 {
        address(for: MemoryAddress(ea), size: size)
    }
    
    mutating func address(for ea: MemoryAddress, size: Size) -> UInt32 {
        switch ea {
        case let .ind(An):
            return readA32(An)
        case let .postInc(An):
            let address = readA32(An)
            writeA32(An, value: address &+ size.byteCount)
            
            return address
        case let .preDec(An):
            let address = readA32(An) &- size.byteCount
            writeA32(An, value: address)
            
            return address
        case let .d16An(d, An):
            return UInt32(truncatingIfNeeded: Int64(readA32(An)) + Int64(d))
        case .d8AnXn(_, _, _, _):
            fatalError("d8AnXn not implemented")
        case let .XXXw(address):
            return address
        case let .XXXl(address):
            return address
        case let .d16PC(pc, d):
            return UInt32(truncatingIfNeeded: Int64(pc) + Int64(d))
        case .d8PCXn(_, _, _, _):
            fatalError("d8PCXn not implemented")
        }
    }
    
    mutating func read(_ ea: EffectiveAddress, _ size: UInt8.Type) -> UInt8 {
        switch ea {
        case let .dd(Dn):
            return readD8(Dn)
        case let .ad(An):
            return readA8(An)
        case let .m(mem):
            let addr = address(for: mem, size: .b)
            
            return read8(addr)
        case let .imm(value):
            return UInt8(truncatingIfNeeded: value)
        }
    }
    
    mutating func read(_ ea: EffectiveAddress, _ size: UInt16.Type) -> UInt16 {
        switch ea {
        case let .dd(Dn):
            return readD16(Dn)
        case let .ad(An):
            return readA16(An)
        case let .m(mem):
            let addr = address(for: mem, size: .w)
            
            return read16(addr)
        case let .imm(value):
            return UInt16(truncatingIfNeeded: value)
        }
    }
    
    mutating func read(_ ea: EffectiveAddress, _ size: UInt32.Type) -> UInt32 {
        switch ea {
        case let .dd(Dn):
            return readD32(Dn)
        case let .ad(An):
            return readA32(An)
        case let .m(mem):
            let addr = address(for: mem, size: .l)
            
            return read32(addr)
        case let .imm(value):
            return UInt32(truncatingIfNeeded: value)
        }
    }

    func readA8(_ An: AddressRegister) -> UInt8 {
        UInt8(truncatingIfNeeded: self[keyPath: An.keyPath])
    }
    
    func readA16(_ An: AddressRegister) -> UInt16 {
        UInt16(truncatingIfNeeded: self[keyPath: An.keyPath])
    }
    
    func readA32(_ An: AddressRegister) -> UInt32 {
        self[keyPath: An.keyPath]
    }
    
    func readD8(_ Dn: DataRegister) -> UInt8 {
        UInt8(truncatingIfNeeded: self[keyPath: Dn.keyPath])
    }
    
    func readD16(_ Dn: DataRegister) -> UInt16 {
        UInt16(truncatingIfNeeded: self[keyPath: Dn.keyPath])
    }

    func readD32(_ Dn: DataRegister) -> UInt32 {
        self[keyPath: Dn.keyPath]
    }
    
    func readR16(_ Rn: Register) -> UInt16 {
        switch Rn {
        case let .a(An): return readA16(An)
        case let .d(Dn): return readD16(Dn)
        }
    }
    
    func readR32(_ Rn: Register) -> UInt32 {
        switch Rn {
        case let .a(An): return readA32(An)
        case let .d(Dn): return readD32(Dn)
        }
    }
    
    mutating func writeA16(_ An: AddressRegister, value: UInt16) {
        self[keyPath: An.keyPath] = UInt32(truncatingIfNeeded: value)
    }
    
    mutating func writeA32(_ An: AddressRegister, value: UInt32) {
        self[keyPath: An.keyPath] = value
    }
    
    mutating func writeD8(_ Dn: DataRegister, value: UInt8) {
        let mask: UInt32 = 0xffffff00
        let existing = readD32(Dn)

        self[keyPath: Dn.keyPath] = (existing & mask) | UInt32(value)
    }
    
    mutating func writeD16(_ Dn: DataRegister, value: UInt16) {
        let mask: UInt32 = 0xffff0000
        let existing = readD32(Dn)

        self[keyPath: Dn.keyPath] = (existing & mask) | UInt32(value)
    }
    
    mutating func writeD32(_ Dn: DataRegister, value: UInt32) {
        self[keyPath: Dn.keyPath] = value
    }
    
    mutating func writeR16(_ Rn: Register, value: UInt16) {
        switch Rn {
        case let .a(An): writeA16(An, value: value)
        case let .d(Dn): writeD16(Dn, value: value)
        }
    }

    mutating func writeR32(_ Rn: Register, value: UInt32) {
        switch Rn {
        case let .a(An): writeA32(An, value: value)
        case let .d(Dn): writeD32(Dn, value: value)
        }
    }
    
    func read(_ address: UInt32, size: Size) -> UInt32 {
        switch size {
        case .b: return UInt32(read8(address))
        case .w: return UInt32(read16(address))
        case .l: return read32(address)
        }
    }
    
    func write(_ address: UInt32, _ value: UInt32, size: Size) {
        switch size {
        case .b: write8(address, value: UInt8(truncatingIfNeeded: value))
        case .w: write16(address, value: UInt16(truncatingIfNeeded: value))
        case .l: write32(address, value: value)
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
