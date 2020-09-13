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
    
    var s: Bool {
        get { sr.contains(.s) }
        
        set {
            if newValue {
                sr.insert(.s)
            } else {
                sr.remove(.s)
            }
        }
    }
    
    var t0: Bool {
        get { sr.contains(.t0) }
        
        set {
            if newValue {
                sr.insert(.t0)
            } else {
                sr.remove(.t0)
            }
        }
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
            s ? isp : usp
        }

        set {
            if s {
                isp = newValue
            } else {
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
                let v2 = cpu.readReg8(Dn)
                                
                let res = v1 &+ v2
                cpu.writeReg8(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vadd(v1, v2, res)
                cpu.c = res < v1
                cpu.x = cpu.c
            }
        case let .addMR(.w, address, Dn):
            return { cpu in
                let v1 = cpu.read(address, UInt16.self)
                let v2 = cpu.readReg16(Dn)

                let res = v1 &+ v2
                cpu.writeReg16(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vadd(v1, v2, res)
                cpu.c = res < v1
                cpu.x = cpu.c
            }
        case let .addMR(.l, address, Dn):
            return { cpu in
                let v1 = cpu.read(address, UInt32.self)
                let v2 = cpu.readReg32(Dn)

                let res = v1 &+ v2
                cpu.writeReg32(Dn, value: res)
                
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
                let v2 = cpu.readReg8(Dn)
                
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
                let v2 = cpu.readReg16(Dn)
                
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
                let v2 = cpu.readReg32(Dn)
                
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
                let v2 = cpu.readReg8(Dn)
                                
                let res = v1 & v2
                cpu.writeReg8(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andMR(.w, ea, Dn):
            return { cpu in
                let v1 = cpu.read(EffectiveAddress(ea), UInt16.self)
                let v2 = cpu.readReg16(Dn)

                let res = v1 & v2
                cpu.writeReg16(Dn, value: res)

                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andMR(.l, ea, Dn):
            return { cpu in
                let v1 = cpu.read(EffectiveAddress(ea), UInt32.self)
                let v2 = cpu.readReg32(Dn)

                let res = v1 & v2
                cpu.writeReg32(Dn, value: res)

                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .andRM(.b, Dn, ea):
            return { cpu in
                let v1 = cpu.readReg8(Dn)
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
                let v1 = cpu.readReg16(Dn)
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
                let v1 = cpu.readReg32(Dn)
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
                let current = cpu.readReg8(Dn)
                let data = UInt8(truncatingIfNeeded: data)

                let res = current & data
                cpu.writeReg8(Dn, value: res)
                
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
                let current = cpu.readReg16(Dn)
                let data = UInt16(truncatingIfNeeded: data)

                let res = current & data
                cpu.writeReg16(Dn, value: res)

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
                let current = cpu.readReg32(Dn)
                let data = UInt32(bitPattern: data)

                let res = current & data
                cpu.writeReg32(Dn, value: res)

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
        case let .bclr(.imm(n), .dd(Dn)):
            return { cpu in
                let bit: UInt32 = 1 << (UInt32(n) % 32)
                let v = cpu.readReg32(Dn)
                cpu.writeReg32(Dn, value: v & ~bit)
                
                cpu.z = v & bit == 0
            }
        case let .bclr(.imm(n), .m(ea)):
            return { cpu in
                let bit = 1 << (n%8)
                let addr = cpu.address(for: ea, size: .b)
                
                let v = cpu.read8(addr)
                cpu.write8(addr, value: v & ~bit)
                
                cpu.z = v & bit == 0
            }
        case let .bclr(.r(Dnum), .dd(Dn)):
            return { cpu in
                let n = cpu.readReg32(Dnum)
                let bit = 1 << (n%32)
                let v = cpu.readReg32(Dn)
                cpu.writeReg32(Dn, value: v & ~bit)
                
                cpu.z = v & bit == 0
            }
        case let .bclr(.r(Dnum), .m(ea)):
            return { cpu in
                let n = cpu.readReg8(Dnum)
                let bit = 1 << (n%8)
                let addr = cpu.address(for: ea, size: .b)
                
                let v = cpu.read8(addr)
                cpu.write8(addr, value: v & ~bit)
                
                cpu.z = v & bit == 0
            }
        case let .bra(_, pc, displacement):
            return { cpu in
                cpu.pc = UInt32(Int64(pc) + Int64(displacement))
            }
        case let .bset(.imm(n), .dd(Dn)):
            return { cpu in
                let bit: UInt32 = 1 << (UInt32(n) % 32)
                
                let v = cpu.readReg32(Dn)
                cpu.writeReg32(Dn, value: v | bit)
                
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
        case let .bset(.r(Dnum), .dd(Dn)):
            return { cpu in
                let n = cpu.readReg32(Dnum)
                
                let bit = 1 << (n%32)
                
                let v = cpu.readReg32(Dn)
                cpu.writeReg32(Dn, value: v | bit)
                
                cpu.z = v & bit == 0
            }
        case let .bset(.r(Dnum), .m(ea)):
            return { cpu in
                let n = cpu.readReg8(Dnum)
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
                
                var count = cpu.readReg16(Dn)
                count = count &- 1
                cpu.writeReg16(Dn, value: count)
                
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
                
                cpu.writeReg32(An, value: address)
            }
        case let .lsl(.b, .imm(n), Dn):
            return { cpu in
                let mask: UInt8 = 1 << (8-n)
                let v = cpu.readReg8(Dn)
                let res = v << n
                
                cpu.writeReg8(Dn, value: res)
                
                cpu.x = v & mask > 0
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = v & mask > 0
            }
        case let .lsl(.b, .r(Dshift), Dn):
            return { cpu in
                let n = cpu.readReg8(Dshift) % 64
                let mask: UInt8 = n > 8 ? 0 : 1 << (8-n)
                let v = cpu.readReg8(Dn)
                let res = v << n
                
                cpu.writeReg8(Dn, value: res)

                if n > 0 { cpu.x = v & mask > 0 }
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = n > 0 ? v & mask > 0 : false
            }
        case let .lsl(.w, .imm(n), Dn):
            return { cpu in
                let mask: UInt16 = 1 << (16-UInt16(n))
                let v = cpu.readReg16(Dn)
                let res = v << n
                
                cpu.writeReg16(Dn, value: res)
                
                cpu.x = v & mask > 0
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = v & mask > 0
            }
        case let .lsl(.w, .r(Dshift), Dn):
            return { cpu in
                let n = cpu.readReg16(Dshift) % 64
                let mask: UInt16 = n > 16 ? 0 : 1 << (16-n)
                let v = cpu.readReg16(Dn)
                let res = v << n
                
                cpu.writeReg16(Dn, value: res)

                if n > 0 { cpu.x = v & mask > 0 }
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = n > 0 ? v & mask > 0 : false
            }
        case let .lsl(.l, .imm(n), Dn):
            return { cpu in
                let mask: UInt32 = 1 << (32-UInt32(n))
                let v = cpu.readReg32(Dn)
                let res = v << n
                
                cpu.writeReg32(Dn, value: res)
                
                cpu.x = v & mask > 0
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = v & mask > 0
            }
        case let .lsl(.l, .r(Dshift), Dn):
            return { cpu in
                let n = cpu.readReg32(Dshift) % 64
                let mask: UInt32 = n > 16 ? 0 : 1 << (16-n)
                let v = cpu.readReg32(Dn)
                let res = v << n
                
                cpu.writeReg32(Dn, value: res)

                if n > 0 { cpu.x = v & mask > 0 }
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = n > 0 ? v & mask > 0 : false
            }
        case let .lsr(.b, .imm(n), Dn):
            return { cpu in
                let mask: UInt8 = 1 << (n-1)
                let v = cpu.readReg8(Dn)
                let res = v >> n
                
                cpu.writeReg8(Dn, value: res)
                
                cpu.x = v & mask > 0
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = v & mask > 0
            }
        case let .lsr(.b, .r(Dshift), Dn):
            return { cpu in
                let n = cpu.readReg8(Dshift) % 64
                let mask: UInt8 = n > 0 ? 1 << (n-1) : 0
                let v = cpu.readReg8(Dn)
                let res = v >> n
                
                cpu.writeReg8(Dn, value: res)

                if n > 0 { cpu.x = v & mask > 0 }
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = n > 0 ? v & mask > 0 : false
            }
        case let .lsr(.w, .imm(n), Dn):
            return { cpu in
                let mask: UInt16 = 1 << (UInt16(n)-1)
                let v = cpu.readReg16(Dn)
                let res = v >> n
                
                cpu.writeReg16(Dn, value: res)
                
                cpu.x = v & mask > 0
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = v & mask > 0
            }
        case let .lsr(.w, .r(Dshift), Dn):
            return { cpu in
                let n = cpu.readReg16(Dshift) % 64
                let mask: UInt16 = n > 0 ? 1 << (n-1) : 0
                let v = cpu.readReg16(Dn)
                let res = v >> n
                
                cpu.writeReg16(Dn, value: res)

                if n > 0 { cpu.x = v & mask > 0 }
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = n > 0 ? v & mask > 0 : false
            }
        case let .lsr(.l, .imm(n), Dn):
            return { cpu in
                let mask: UInt32 = 1 << (UInt32(n)-1)
                let v = cpu.readReg32(Dn)
                let res = v >> n
                
                cpu.writeReg32(Dn, value: res)
                
                cpu.x = v & mask > 0
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = v & mask > 0
            }
        case let .lsr(.l, .r(Dshift), Dn):
            return { cpu in
                let n = cpu.readReg32(Dshift) % 64
                let mask: UInt32 = n > 0 ? 1 << (n-1) : 0
                let v = cpu.readReg32(Dn)
                let res = v >> n
                
                cpu.writeReg32(Dn, value: res)

                if n > 0 { cpu.x = v & mask > 0 }
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = n > 0 ? v & mask > 0 : false
            }
        case let .move(.b, src, .dd(Dn)):
            return { cpu in
                let data = cpu.read(src, UInt8.self)
                cpu.writeReg8(Dn, value: data)
                
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
                cpu.writeReg16(Dn, value: data)
                
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
                cpu.writeReg32(Dn, value: data)

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
                cpu.writeReg16(An, value: data)
            }
        case let .movea(.l, src, An):
            return { cpu in
                let data = cpu.read(src, UInt32.self)
                cpu.writeReg32(An, value: data)
            }
        case let .movemMR(.w, .postInc(An), regList):
            return { cpu in
                for Rn in regList.registers {
                    let addr = cpu.address(for: MemoryAddress.postInc(An), size: .w)
                    
                    cpu.writeReg16(Rn, value: cpu.read16(addr))
                }
            }
        case let .movemMR(.w, .c(ea), regList):
            return { cpu in
                var addr = cpu.address(for: ea)
                
                for Rn in regList.registers {
                    cpu.writeReg16(Rn, value: cpu.read16(addr))
                    addr += 2
                }
            }
        case let .movemMR(.l, .postInc(An), regList):
            return { cpu in
                for Rn in regList.registers {
                    let addr = cpu.address(for: MemoryAddress.postInc(An), size: .l)
                    
                    cpu.writeReg32(Rn, value: cpu.read32(addr))
                }
            }
        case let .movemMR(.l, .c(ea), regList):
            return { cpu in
                var addr = cpu.address(for: ea)
                
                for Rn in regList.registers {
                    cpu.writeReg32(Rn, value: cpu.read32(addr))
                    addr += 4
                }
            }
        case let .movemRM(.w, regList, .preDec(An)):
            return { cpu in
                let initialAddr = cpu.readReg16(An)
                
                for Rn in regList.registers.reversed() {
                    let addr = cpu.address(for: MemoryAddress.preDec(An), size: .w)
                    
                    let value: UInt16
                    if Rn == .a(An) {
                        // TODO: 68020, 68030, 68040, value should be initialAddr - 2
                        value = initialAddr
                    } else {
                        value = cpu.readReg16(Rn)
                    }
                    
                    cpu.write16(addr, value: value)
                }
            }
        case let .movemRM(.w, regList, .c(ea)):
            return { cpu in
                var addr = cpu.address(for: ea)
                
                for Rn in regList.registers {
                    cpu.write16(addr, value: cpu.readReg16(Rn))
                    addr += 2
                }
            }
        case let .movemRM(.l, regList, .preDec(An)):
            return { cpu in
                let initialAddr = cpu.readReg32(An)
                
                for Rn in regList.registers.reversed() {
                    let addr = cpu.address(for: MemoryAddress.preDec(An), size: .l)
                    
                    let value: UInt32
                    if Rn == .a(An) {
                        // TODO: 68020, 68030, 68040, value should be initialAddr - 4
                        value = initialAddr
                    } else {
                        value = cpu.readReg32(Rn)
                    }
                    
                    cpu.write32(addr, value: value)
                }
            }
        case let .movemRM(.l, regList, .c(ea)):
            return { cpu in
                var addr = cpu.address(for: ea)
                
                for Rn in regList.registers {
                    cpu.write32(addr, value: cpu.readReg32(Rn))
                    addr += 4
                }
            }
        case let .moveq(data, Dn):
            return { cpu in
                cpu.writeReg32(Dn, value: UInt32(truncatingIfNeeded: data))
                
                cpu.n = data < 0
                cpu.z = data == 0
                cpu.v = false
                cpu.c = false
            }
        case let .moveToSR(address):
            return { cpu in
                if !cpu.s {
                    cpu.privilegeViolation()
                    return
                }
                    
                let value = cpu.read(EffectiveAddress(address), UInt16.self)

                cpu.sr = StatusRegister(rawValue: value)
            }
        case let .orMR(.b, ea, Dn):
            return { cpu in
                let src = cpu.read(EffectiveAddress(ea), UInt8.self)
                let dst = cpu.readReg8(Dn)
                let res = src | dst
                cpu.writeReg8(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .orMR(.w, ea, Dn):
            return { cpu in
                let src = cpu.read(EffectiveAddress(ea), UInt16.self)
                let dst = cpu.readReg16(Dn)
                let res = src | dst
                cpu.writeReg16(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .orMR(.l, ea, Dn):
            return { cpu in
                let src = cpu.read(EffectiveAddress(ea), UInt32.self)
                let dst = cpu.readReg32(Dn)
                let res = src | dst
                cpu.writeReg32(Dn, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .orRM(.b, Dn, ea):
            return { cpu in
                let src = cpu.readReg8(Dn)
                let addr = cpu.address(for: ea, size: .b)
                let dst = cpu.read8(addr)
                let res = src | dst
                
                cpu.write8(addr, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .orRM(.w, Dn, ea):
            return { cpu in
                let src = cpu.readReg16(Dn)
                let addr = cpu.address(for: ea, size: .w)
                let dst = cpu.read16(addr)
                let res = src | dst
                
                cpu.write16(addr, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .orRM(.l, Dn, ea):
            return { cpu in
                let src = cpu.readReg32(Dn)
                let addr = cpu.address(for: ea, size: .l)
                let dst = cpu.read32(addr)
                let res = src | dst
                
                cpu.write32(addr, value: res)
                
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = false
            }
        case let .oriToSR(value):
            return { cpu in
                if !cpu.s {
                    cpu.privilegeViolation()
                    return
                }

                let value = UInt16(truncatingIfNeeded: value)
                let current = cpu.sr.rawValue
                cpu.sr = StatusRegister(rawValue: value | current)
            }
        case let .ror(.b, .imm(n), Dn):
            return { cpu in
                var v = cpu.readReg8(Dn)
                
                v = v>>n | v<<(8-n)
                
                cpu.writeReg8(Dn, value: v)

                cpu.n = neg(v)
                cpu.z = v == 0
                cpu.v = false
                cpu.c = neg(v) && n > 0
            }
        case let .ror(.w, .imm(n), Dn):
            return { cpu in
                var v = cpu.readReg16(Dn)
                
                v = v>>n | v<<(16-n)

                cpu.writeReg16(Dn, value: v)
                
                cpu.n = neg(v)
                cpu.z = v == 0
                cpu.v = false
                cpu.c = neg(v) && n > 0
            }
        case let .ror(.l, .imm(n), Dn):
            return { cpu in
                var v = cpu.readReg32(Dn)
                
                v = v>>n | v<<(32-n)

                cpu.writeReg32(Dn, value: v)
                
                cpu.n = neg(v)
                cpu.z = v == 0
                cpu.v = false
                cpu.c = neg(v) && n > 0
            }
        case let .roxl(.b, .imm(n), Dn):
            return { cpu in
                var v = UInt16(cpu.readReg8(Dn))
                
                let xb: UInt16 = cpu.x ? 1 : 0
                
                v = xb<<8 | v
                v = v<<n | v>>(9-n)
                
                let res = UInt8(truncatingIfNeeded: v)
                
                cpu.writeReg8(Dn, value: res)
                
                if n > 0 { cpu.x = (v>>8) & 1 == 1 }
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = cpu.x
            }
        case let .roxl(.w, .imm(n), Dn):
            return { cpu in
                var v = UInt32(cpu.readReg16(Dn))
                
                let xb: UInt32 = cpu.x ? 1 : 0
                
                v = xb<<16 | v
                v = v<<n | v>>(17-n)
                
                let res = UInt16(truncatingIfNeeded: v)
                
                cpu.writeReg16(Dn, value: res)
                
                if n > 0 { cpu.x = (v>>16) & 1 == 1}
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = cpu.x
            }
        case let .roxl(.l, .imm(n), Dn):
            return { cpu in
                var v = UInt64(cpu.readReg32(Dn))
                
                let xb: UInt64 = cpu.x ? 1 : 0
                
                v = xb<<32 | v
                v = v<<n | v>>(33-n)
                
                let res = UInt32(truncatingIfNeeded: v)
                
                cpu.writeReg32(Dn, value: res)
                
                if n > 0 { cpu.x = (v>>32) & 1 == 1}
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = false
                cpu.c = cpu.x
            }
        case let .suba(.w, ea, An):
            return { cpu in
                let src = UInt32(truncatingIfNeeded: Int16(bitPattern: cpu.read(ea, UInt16.self)))
                
                let dst = cpu.readReg32(An)
                
                cpu.writeReg32(An, value: dst &- src)
            }
        case let .suba(.l, ea, An):
            return { cpu in
                let src = cpu.read(ea, UInt32.self)
                let dst = cpu.readReg32(An)
                
                cpu.writeReg32(An, value: dst &- src)
            }
        case let .subqB(src, .dd(Dn)):
            return { cpu in
                let dst = cpu.readReg8(Dn)
                let res = dst &- src
                cpu.writeReg8(Dn, value: res)
                
                cpu.x = src > dst
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vsub(src, dst, res)
                cpu.c = src > dst
            }
        case let .subqB(src, .m(ea)):
            return { cpu in
                let addr = cpu.address(for: ea, size: .b)
                let dst = cpu.read8(addr)
                let res = dst &- src
                
                cpu.write8(addr, value: res)
                                
                cpu.x = src > dst
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vsub(src, dst, res)
                cpu.c = src > dst
            }
        case let .subqWL(.w, src, .dd(Dn)):
            return { cpu in
                let dst = cpu.readReg16(Dn)
                let src = UInt16(src)
                let res = dst &- src
                
                cpu.writeReg16(Dn, value: res)

                cpu.x = src > dst
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vsub(src, dst, res)
                cpu.c = src > dst
            }
        case let .subqWL(.w, src, .m(ea)):
            return { cpu in
                let addr = cpu.address(for: ea, size: .w)
                let dst = cpu.read16(addr)
                let src = UInt16(src)
                
                let res = dst &- src
                cpu.write16(addr, value: res)
                                
                cpu.x = src > dst
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vsub(src, dst, res)
                cpu.c = src > dst
            }
        case let .subqWL(.l, src, .dd(Dn)):
            return { cpu in
                let dst = cpu.readReg32(Dn)
                let src = UInt32(src)
                let res = dst &- src
                
                cpu.writeReg32(Dn, value: res)
                
                cpu.x = src > dst
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vsub(src, dst, res)
                cpu.c = src > dst
            }
        case let .subqWL(.l, src, .m(ea)):
            return { cpu in
                let addr = cpu.address(for: ea, size: .l)
                let dst = cpu.read32(addr)
                let src = UInt32(src)
                
                let res = dst &- src
                cpu.write32(addr, value: res)
                                                
                cpu.x = src > dst
                cpu.n = neg(res)
                cpu.z = res == 0
                cpu.v = vsub(src, dst, res)
                cpu.c = src > dst
            }
        // From everything I can find, address direct subq.w
        // and subq.l behave the same.
        case let .subqWL(_, src, .ad(An)):
            return { cpu in
                let dst = cpu.readReg32(An)
                let src = UInt32(src)
                let res = dst &- src

                cpu.writeReg32(An, value: res)
            }
        case let .tst(.b, ea):
            return { cpu in
                let dst = cpu.read(ea, UInt8.self)

                cpu.n = neg(dst)
                cpu.z = dst == 0
                cpu.v = false
                cpu.c = false
            }
        case let .tst(.w, ea):
            return { cpu in
                let dst = cpu.read(ea, UInt16.self)

                cpu.n = neg(dst)
                cpu.z = dst == 0
                cpu.v = false
                cpu.c = false
            }
        case let .tst(.l, ea):
            return { cpu in
                let dst = cpu.read(ea, UInt32.self)

                cpu.n = neg(dst)
                cpu.z = dst == 0
                cpu.v = false
                cpu.c = false
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
    
    mutating func privilegeViolation() {
        let tmp = sr
        
        t0 = false
        s = true
        
        // TODO: for other exception types, mask interrupt levels if this is an interrupt
        
        let vectorAddr = ExceptionVector.privilegeViolation.address
        
        push32(pc)
        push16(tmp.rawValue)
        
        pc = read32(vectorAddr)
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
            return readReg32(An)
        case let .postInc(An):
            let address = readReg32(An)
            writeReg32(An, value: address &+ size.byteCount)
            
            return address
        case let .preDec(An):
            let address = readReg32(An) &- size.byteCount
            writeReg32(An, value: address)
            
            return address
        case let .d16An(d, An):
            return UInt32(truncatingIfNeeded: Int64(readReg32(An)) + Int64(d))
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
            return readReg8(Dn)
        case let .ad(An):
            return readReg8(An)
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
            return readReg16(Dn)
        case let .ad(An):
            return readReg16(An)
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
            return readReg32(Dn)
        case let .ad(An):
            return readReg32(An)
        case let .m(mem):
            let addr = address(for: mem, size: .l)
            
            return read32(addr)
        case let .imm(value):
            return UInt32(truncatingIfNeeded: value)
        }
    }

    func readReg8(_ An: AddressRegister) -> UInt8 {
        UInt8(truncatingIfNeeded: self[keyPath: An.keyPath])
    }
    
    func readReg16(_ An: AddressRegister) -> UInt16 {
        UInt16(truncatingIfNeeded: self[keyPath: An.keyPath])
    }
    
    func readReg32(_ An: AddressRegister) -> UInt32 {
        self[keyPath: An.keyPath]
    }
    
    func readReg8(_ Dn: DataRegister) -> UInt8 {
        UInt8(truncatingIfNeeded: self[keyPath: Dn.keyPath])
    }
    
    func readReg16(_ Dn: DataRegister) -> UInt16 {
        UInt16(truncatingIfNeeded: self[keyPath: Dn.keyPath])
    }

    func readReg32(_ Dn: DataRegister) -> UInt32 {
        self[keyPath: Dn.keyPath]
    }
    
    func readReg16(_ Rn: Register) -> UInt16 {
        switch Rn {
        case let .a(An): return readReg16(An)
        case let .d(Dn): return readReg16(Dn)
        }
    }
    
    func readReg32(_ Rn: Register) -> UInt32 {
        switch Rn {
        case let .a(An): return readReg32(An)
        case let .d(Dn): return readReg32(Dn)
        }
    }
    
    mutating func writeReg16(_ An: AddressRegister, value: UInt16) {
        self[keyPath: An.keyPath] = UInt32(truncatingIfNeeded: Int16(bitPattern: value))
    }
    
    mutating func writeReg32(_ An: AddressRegister, value: UInt32) {
        self[keyPath: An.keyPath] = value
    }
    
    mutating func writeReg8(_ Dn: DataRegister, value: UInt8) {
        let mask: UInt32 = 0xffffff00
        let existing = readReg32(Dn)

        self[keyPath: Dn.keyPath] = (existing & mask) | UInt32(value)
    }
    
    mutating func writeReg16(_ Dn: DataRegister, value: UInt16) {
        let mask: UInt32 = 0xffff0000
        let existing = readReg32(Dn)

        self[keyPath: Dn.keyPath] = (existing & mask) | UInt32(value)
    }
    
    mutating func writeReg32(_ Dn: DataRegister, value: UInt32) {
        self[keyPath: Dn.keyPath] = value
    }
    
    mutating func writeReg16(_ Rn: Register, value: UInt16) {
        switch Rn {
        case let .a(An): writeReg16(An, value: value)
        case let .d(Dn): writeReg16(Dn, value: value)
        }
    }

    mutating func writeReg32(_ Rn: Register, value: UInt32) {
        switch Rn {
        case let .a(An): writeReg32(An, value: value)
        case let .d(Dn): writeReg32(Dn, value: value)
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
    
    mutating func push16(_ value: UInt16) {
        a7 -= 2
        write16(a7, value: value)
    }
    
    mutating func push32(_ value: UInt32) {
        a7 -= 4
        write32(a7, value: value)
    }
}


public struct StatusRegister: OptionSet, Hashable, CustomStringConvertible {
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
    
    var labels: [StatusRegister: String] {
        [
            .t0: "t0",
            .s: "s",
            .i2: "i2",
            .i1: "i1",
            .i0: "i0",
            .x: "x",
            .n: "n",
            .z: "z",
            .v: "v",
            .c: "c",
        ]
    }
    
    public var description: String {
        var res: [String] = []
        
        for k in labels.keys {
            if contains(k), let label = labels[k] {
                res.append(label)
            }
        }
        
        return "StatusRegister(rawValue: \(rawValue)) \(res)"
    }
}

enum ExceptionVector: UInt8 {
    case reset = 0
    case busError = 2
    case addressError = 3
    case illegalInstruction = 4
    case zeroDivide = 5
    case chk = 6
    case trapv = 7
    case privilegeViolation = 8
    case trace = 9
    case line1010 = 10
    case line1111 = 11
    case uninitializedInterrupt = 15
    case spuriousInterrupt = 24
    case l1Autovector = 25
    case l2Autovector = 26
    case l3Autovector = 27
    case l4Autovector = 28
    case l5Autovector = 29
    case l6Autovector = 30
    case l7Autovector = 31
    
    var address: UInt32 {
        UInt32(rawValue) << 2
    }
}
