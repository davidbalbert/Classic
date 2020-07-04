//
//  M68K.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Foundation

private extension Data {
    func chunked(by count: Int) -> [Data] {
        stride(from: startIndex, to: endIndex, by: count).map { i in
            self[i..<Swift.min(i+count, endIndex)]
        }
    }

    func hexDump() -> String {
        chunked(by: 2).map { word in
            word.map { String(format: "%02x", $0) }.joined(separator: "")
        }.joined(separator: " ")
    }
}

private extension BinaryInteger {
    var bitSwapped: Self {
        var res: Self = 0
        var v = self

        for _ in 0..<bitWidth {
            let b = v & 1
            res <<= 1
            res |= b
            v >>= 1
        }
        
        return res
    }
}


struct StatusRegister: OptionSet {
    let rawValue: UInt16

    // CCR bits
    static let c = StatusRegister(rawValue: 1 << 0)
    static let v = StatusRegister(rawValue: 1 << 1)
    static let z = StatusRegister(rawValue: 1 << 2)
    static let n = StatusRegister(rawValue: 1 << 3)
    static let x = StatusRegister(rawValue: 1 << 4)

    static let ccr: StatusRegister = [x, n, z, v, c]

    // System bits

    // Interrupt priority mask
    static let i0 = StatusRegister(rawValue: 1 << 8)
    static let i1 = StatusRegister(rawValue: 1 << 9)
    static let i2 = StatusRegister(rawValue: 1 << 10)

    static let m  = StatusRegister(rawValue: 1 << 12)
    static let s  = StatusRegister(rawValue: 1 << 13)

    // Trace enable
    static let t0 = StatusRegister(rawValue: 1 << 14)
    static let t1 = StatusRegister(rawValue: 1 << 15)

    static let all: StatusRegister = [t1, t0, s, m, i2, i1, i0, x, n, z, v, c]

    // stack selection
    static let stackSelectionMask: StatusRegister = [m, s]
    static let msp: StatusRegister = [m, s]
    static let isp: StatusRegister = [s]
}

struct Registers {
    var pc: UInt32
    var sr: StatusRegister

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
    var msp: UInt32

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
            case .msp:
                return msp
            case .isp:
                return isp
            default:
                return usp
            }
        }

        set {
            switch sr.intersection(.stackSelectionMask) {
            case .msp:
                msp = newValue
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
}

enum DataRegister: Int, Equatable, CustomStringConvertible {
    case d0, d1, d2, d3, d4, d5, d6, d7
    
    var description: String {
        "D\(rawValue)"
    }
}

enum AddressRegister: Int, Equatable, CustomStringConvertible {
    case a0, a1, a2, a3, a4, a5, a6, a7
    
    var description: String {
        "A\(rawValue)"
    }
}

enum Register: Equatable, CustomStringConvertible {
    case a(AddressRegister)
    case d(DataRegister)
    
    var description: String {
        switch self {
        case let .a(An): return "\(An)"
        case let .d(Dn): return "\(Dn)"
        }
    }
}

enum ImmediateValue: Equatable, CustomStringConvertible {
    case b(Int8)
    case w(Int16)
    case l(Int32)
    
    var description: String {
        switch self {
        case let .b(value): return "#$\(String(value, radix: 16))"
        case let .w(value): return "#$\(String(value, radix: 16))"
        case let .l(value): return "#$\(String(value, radix: 16))"
        }
    }
}

// List of instructions for the 68000 - p608


// List of address modes for the 68000 - p612

// Data Register Direct
// Address Register Direct
// Absolute Short
// Absolute Long
// PC Relative with Offset
// PC Relative with Index and Offset
// Register Indirect
// Postincrement Register Indirect
// Predecrement Register Indirect
// Register Indirect with Offset
// Indexed Register Indirect with Offse
// Immediate
// Quick Immediate
// Implied Register


enum AddressingMode: Int, Equatable {
    case dd
    case ad
    case ind
    case postInc
    case preDec
    case d16An
    case d8AnXn
    
    // These all have mode as 0b111
    case XXXw = 0x10
    case XXXl
    case d16PC
    case d8PCXn
    case imm
    
    static func `for`(_ mode: Int, reg: Int) -> AddressingMode? {
        if mode == 0b111 {
            return AddressingMode(rawValue: 0x10 + reg)
        } else {
            return AddressingMode(rawValue: mode)
        }
    }
}

enum EffectiveAddress: Equatable, CustomStringConvertible {
    case dd(DataRegister)
    case ad(AddressRegister)
    case ind(AddressRegister)
    case postInc(AddressRegister)
    case preDec(AddressRegister)
    case d16An(Int16, AddressRegister)
    case d8AnXn(Int8, AddressRegister, Register)
    case XXXw(UInt32)
    case XXXl(UInt32)
    case d16PC(UInt32, Int16)
    case imm(ImmediateValue)
    
    var description: String {
        switch self {
        case let .dd(Dn):             return "\(Dn)"
        case let .ad(An):             return "\(An)"
        case let .ind(An):            return "(\(An))"
        case let .postInc(An):        return "(\(An))+"
        case let .preDec(An):         return "-(\(An))"
        case let .d16An(d16, An):     return "$\(String(d16, radix: 16))(\(An))"
        case let .d8AnXn(d8, An, Xn): return "$\(String(d8, radix: 16))(\(An),\(Xn))"
        case let .XXXw(address):      return "($\(String(address, radix: 16)))"
        case let .XXXl(address):      return "($\(String(address, radix: 16)))"
        case let .d16PC(pc, d16):     return "$\(String(Int(pc)+Int(d16), radix: 16))(PC)"
        case let .imm(value):         return "\(value)"
        }
    }
}

struct ExtensionWord {
    let displacement: Int8
}

enum Size: Equatable {
    case b
    case w
    case l
}

enum Condition: Int, Equatable {
    case t
    case f
    case hi
    case ls
    case cc
    case cs
    case ne
    case eq
    case vc
    case vs
    case pl
    case mi
    case ge
    case lt
    case gt
    case le
}

// Bitwise run-length encoding. Returns pairsof [firstIndex, lastIndex]
// for runs of 1s.
private func rle(_ x: UInt8) -> [[Int]] {
    var res: [[Int]] = []
    
    var x0 = x
    var start = 0
    var end = 0
    
    while x0 > 0 {
        let b = x0 & 1
        
        if b == 1 {
            end += 1
        } else if start != end {
            res.append([start, end-1])
            end += 1
            start = end
        } else {
            start += 1
            end += 1
        }
        
        
        x0 = x0 >> 1
    }
    
    // deal with a run at the end
    if start != end {
        res.append([start, end-1])
    }
    
    return res
}

struct RegisterList: OptionSet, CustomStringConvertible {
    let rawValue: UInt16
    
    static let d0 = RegisterList(rawValue: 1 << 0)
    static let d1 = RegisterList(rawValue: 1 << 1)
    static let d2 = RegisterList(rawValue: 1 << 2)
    static let d3 = RegisterList(rawValue: 1 << 3)
    static let d4 = RegisterList(rawValue: 1 << 4)
    static let d5 = RegisterList(rawValue: 1 << 5)
    static let d6 = RegisterList(rawValue: 1 << 6)
    static let d7 = RegisterList(rawValue: 1 << 7)

    static let a0 = RegisterList(rawValue: 1 << 8)
    static let a1 = RegisterList(rawValue: 1 << 9)
    static let a2 = RegisterList(rawValue: 1 << 10)
    static let a3 = RegisterList(rawValue: 1 << 11)
    static let a4 = RegisterList(rawValue: 1 << 12)
    static let a5 = RegisterList(rawValue: 1 << 13)
    static let a6 = RegisterList(rawValue: 1 << 14)
    static let a7 = RegisterList(rawValue: 1 << 15)
    
    var description: String {
        let dataRegs = UInt8(rawValue & 0xff)
        let addrRegs = UInt8(rawValue >> 8)

        let d = rle(dataRegs).map { r in r[0] == r[1] ? "D\(r[0])" : "D\(r[0])-D\(r[1])"}.joined(separator: "/")
        let a = rle(addrRegs).map { r in r[0] == r[1] ? "A\(r[0])" : "A\(r[0])-A\(r[1])"}.joined(separator: "/")
        
        if d.count > 0 && a.count > 0 {
            return d + "/" + a
        } else if d.count > 0 {
            return d
        } else {
            return a
        }
    }
}

enum ShiftCount: Equatable {
    case r(DataRegister)
    case imm(UInt8)
}

enum BitNumber: Equatable {
    case r(DataRegister)
    case imm(UInt8)
}

enum Direction: Equatable {
    case rToM
    case mToR
}

enum OpName: String {
    case addb, addw, addl
    case andb, andw, andl
    case andib, andiw, andil
    case bra
    case bcc
    case moveb, movew, movel
    case movem
    case moveq
    case moveToSR
    case lea
    case subaw, subal
    case subqb, subqw, subql
    case cmpb, cmpw, cmpl
    case cmpib, cmpiw, cmpil
    case jmp
    case tstb, tstw, tstl
    case orb, orw, orl
    case lslb, lslw, lsll, lslm
    case lsrb, lsrw, lsrl, lsrm
    case clrb, clrw, clrl
    case bseti, bsetr
}

enum OpClass: String {
    case add
    case and
    case andi
    case bra
    case bcc
    case move
    case movem
    case moveq
    case moveToSR
    case lea
    case suba
    case subq
    case cmp
    case cmpi
    case jmp
    case tst
    case or
    case ls
    case lsm
    case clr
    case bseti, bsetr
}

struct OpInfo {
    let name: OpName
    let opClass: OpClass
    let mask: UInt16
    let value: UInt16
}

enum Operation: Equatable {
    case add(Size, Direction, EffectiveAddress, DataRegister)
    case and(Size, Direction, EffectiveAddress, DataRegister)
    case andi(Size, Int32, EffectiveAddress)
    case bra(Size, UInt32, Int16)
    case bcc(Size, Condition, UInt32, Int16)
    case move(Size, EffectiveAddress, EffectiveAddress)
    case movem(Size, Direction, EffectiveAddress, RegisterList)
    case moveq(Int8, DataRegister)
    case moveToSR(EffectiveAddress)
    case lea(EffectiveAddress, AddressRegister)
    case suba(Size, EffectiveAddress, AddressRegister)
    case subq(Size, UInt8, EffectiveAddress)
    case cmp(Size, EffectiveAddress, DataRegister)
    case cmpi(Size, Int32, EffectiveAddress)
    case jmp(EffectiveAddress)
    case tst(Size, EffectiveAddress)
    case or(Size, Direction, EffectiveAddress, DataRegister)
    case lsl(Size, ShiftCount, DataRegister)
    case lsr(Size, ShiftCount, DataRegister)
    case lslm(EffectiveAddress)
    case lsrm(EffectiveAddress)
    case clr(Size, EffectiveAddress)
    case bset(BitNumber, EffectiveAddress)
}

extension Operation: CustomStringConvertible {
    var description: String {
        switch self {
        case let .add(size, .mToR, address, register):
            return "add.\(size) \(address), \(register)"
        case let .add(size, .rToM, address, register):
            return "add.\(size) \(register), \(address)"
        case let .and(size, .mToR, address, register):
            return "and.\(size) \(address), \(register)"
        case let .and(size, .rToM, address, register):
            return "and.\(size) \(register), \(address)"
        case let .andi(size, data, address):
            return "and.\(size) #$\(String(data, radix: 16)), \(address)"
        case let .bra(size, pc, displacement):
            return "bra.\(size) $\(String(Int64(pc) + Int64(displacement), radix: 16))"
        case let .bcc(size, condition, pc, displacement):
            return "b\(condition).\(size) $\(String(Int64(pc) + Int64(displacement), radix: 16))"
        case let .move(size, from, to):
            return "move.\(size) \(from), \(to)"
        case let .lea(address, register):
            return "lea \(address), \(register)"
        case let .suba(size, address, register):
            return "suba.\(size) \(address), \(register)"
        case let .subq(size, data, address):
            return "subq.\(size) #$\(String(data, radix: 16)), \(address)"
        case let .movem(size, .rToM, address, registers):
            return "movem.\(size) \(registers), \(address)"
        case let .movem(size, .mToR, address, registers):
            return "movem.\(size) \(address), \(registers)"
        case let .moveq(data, register):
            return "moveq #$\(String(data, radix: 16)), \(register)"
        case let .moveToSR(address):
            return "move \(address), SR"
        case let .cmp(size, address, register):
            return "cmp.\(size) \(address), \(register)"
        case let .cmpi(size, data, address):
            return "cmp.\(size) #$\(String(data, radix: 16)), \(address)"
        case let .jmp(address):
            return "jmp \(address)"
        case let .tst(size, address):
            return "tst.\(size) \(address)"
        case let .or(size, .mToR, address, register):
            return "or.\(size) \(address), \(register)"
        case let .or(size, .rToM, address, register):
            return "or.\(size) \(register), \(address)"
        case let .lsl(size, .r(countRegister), register):
            return "lsl.\(size) \(countRegister), \(register)"
        case let .lsl(size, .imm(count), register):
            return "lsl.\(size) #$\(String(count, radix: 16)), \(register)"
        case let .lsr(size, .r(countRegister), register):
            return "lsr.\(size) \(countRegister), \(register)"
        case let .lsr(size, .imm(count), register):
            return "lsr.\(size) #$\(String(count, radix: 16)), \(register)"
        case let .lslm(address):
            return "lsl \(address)"
        case let .lsrm(address):
            return "lsr \(address)"
        case let .clr(size, address):
            return "clr.\(size) \(address)"
        case let .bset(.imm(bitNumber), address):
            return "bset #$\(String(bitNumber, radix: 16)), \(address)"
        case let .bset(.r(register), address):
            return "bset \(register), \(address)"
        }
    }
}


public struct Instruction: CustomStringConvertible {
    let op: Operation
    public let address: UInt32
    let data: Data
    
    public var description: String {
        let hex = data.hexDump().padding(toLength: 21, withPad: " ", startingAt: 0)
        
        return "\(hex)\(op)"
    }
}

let ops = [
    OpInfo(name: .addb,     opClass: .add,      mask: 0xf0c0, value: 0xd000),
    OpInfo(name: .addw,     opClass: .add,      mask: 0xf0c0, value: 0xd040),
    OpInfo(name: .addl,     opClass: .add,      mask: 0xf0c0, value: 0xd080),

    OpInfo(name: .andb,     opClass: .and,      mask: 0xf0c0, value: 0xc000),
    OpInfo(name: .andw,     opClass: .and,      mask: 0xf0c0, value: 0xc040),
    OpInfo(name: .andl,     opClass: .and,      mask: 0xf0c0, value: 0xc080),
    
    OpInfo(name: .andib,    opClass: .andi,     mask: 0xffc0, value: 0x0200),
    OpInfo(name: .andiw,    opClass: .andi,     mask: 0xffc0, value: 0x0240),
    OpInfo(name: .andil,    opClass: .andi,     mask: 0xffc0, value: 0x0280),
    
    OpInfo(name: .bra,      opClass: .bra,      mask: 0xff00, value: 0x6000),
    OpInfo(name: .bcc,      opClass: .bcc,      mask: 0xf000, value: 0x6000),
    
    OpInfo(name: .moveb,    opClass: .move,     mask: 0xf000, value: 0x1000),
    OpInfo(name: .movew,    opClass: .move,     mask: 0xf000, value: 0x3000),
    OpInfo(name: .movel,    opClass: .move,     mask: 0xf000, value: 0x2000),
    
    OpInfo(name: .movem,    opClass: .movem,    mask: 0xfb80, value: 0x4880),
    OpInfo(name: .moveq,    opClass: .moveq,    mask: 0xf100, value: 0x7000),
    OpInfo(name: .moveToSR, opClass: .moveToSR, mask: 0xffc0, value: 0x46c0),
    OpInfo(name: .lea,      opClass: .lea,      mask: 0xf1c0, value: 0x41c0),
    
    OpInfo(name: .subaw,    opClass: .suba,     mask: 0xf1c0, value: 0x90c0),
    OpInfo(name: .subal,    opClass: .suba,     mask: 0xf1c0, value: 0x91c0),

    OpInfo(name: .subqb,    opClass: .subq,     mask: 0xf1c0, value: 0x5100),
    OpInfo(name: .subqw,    opClass: .subq,     mask: 0xf1c0, value: 0x5140),
    OpInfo(name: .subql,    opClass: .subq,     mask: 0xf1c0, value: 0x5180),
    
    OpInfo(name: .cmpb,     opClass: .cmp,      mask: 0xf1c0, value: 0xb000),
    OpInfo(name: .cmpw,     opClass: .cmp,      mask: 0xf1c0, value: 0xb040),
    OpInfo(name: .cmpl,     opClass: .cmp,      mask: 0xf1c0, value: 0xb080),
    
    OpInfo(name: .cmpib,    opClass: .cmpi,     mask: 0xffc0, value: 0x0c00),
    OpInfo(name: .cmpiw,    opClass: .cmpi,     mask: 0xffc0, value: 0x0c40),
    OpInfo(name: .cmpil,    opClass: .cmpi,     mask: 0xffc0, value: 0x0c80),
    
    OpInfo(name: .jmp,      opClass: .jmp,      mask: 0xffc0, value: 0x4ec0),
    
    OpInfo(name: .tstb,     opClass: .tst,      mask: 0xffc0, value: 0x4a00),
    OpInfo(name: .tstw,     opClass: .tst,      mask: 0xffc0, value: 0x4a40),
    OpInfo(name: .tstl,     opClass: .tst,      mask: 0xffc0, value: 0x4a80),

    OpInfo(name: .orb,     opClass: .or,        mask: 0xf0c0, value: 0x8000),
    OpInfo(name: .orw,     opClass: .or,        mask: 0xf0c0, value: 0x8040),
    OpInfo(name: .orl,     opClass: .or,        mask: 0xf0c0, value: 0x8080),

    OpInfo(name: .lslb,     opClass: .ls,      mask: 0xf1d8, value: 0xe108),
    OpInfo(name: .lslw,     opClass: .ls,      mask: 0xf1d8, value: 0xe148),
    OpInfo(name: .lsll,     opClass: .ls,      mask: 0xf1d8, value: 0xe188),
    OpInfo(name: .lslm,     opClass: .lsm,     mask: 0xffc0, value: 0xe3c0),

    OpInfo(name: .lsrb,     opClass: .ls,      mask: 0xf1d8, value: 0xe008),
    OpInfo(name: .lsrw,     opClass: .ls,      mask: 0xf1d8, value: 0xe048),
    OpInfo(name: .lsrl,     opClass: .ls,      mask: 0xf1d8, value: 0xe088),
    OpInfo(name: .lsrm,     opClass: .lsm,     mask: 0xffc0, value: 0xe2c0),

    OpInfo(name: .clrb,     opClass: .clr,     mask: 0xffc0, value: 0x4200),
    OpInfo(name: .clrw,     opClass: .clr,     mask: 0xffc0, value: 0x4240),
    OpInfo(name: .clrl,     opClass: .clr,     mask: 0xffc0, value: 0x4280),

    OpInfo(name: .bseti,    opClass: .bseti,   mask: 0xffc0, value: 0x08c0),
    OpInfo(name: .bsetr,    opClass: .bsetr,   mask: 0xf1c0, value: 0x01c0),

//    OpInfo(name: "exg", mask: 0xf130, value: 0xc100)
]

public struct Disassembler {
    var opTable: [OpClass?]
    var data = Data()
    var offset: Data.Index = 0
    var loadAddress: UInt32 = 0
    
    public init() {
        opTable = Array(repeating: nil, count: Int(UInt16.max))
        
        for i in 0...Int(UInt16.max) {
            for opInfo in ops {
                if UInt16(i) & opInfo.mask == opInfo.value {
                    opTable[i] = opInfo.opClass
                    break
                }
            }
        }
    }
    
    public mutating func disassemble(_ data: Data, loadAddress: UInt32) -> [Instruction] {
        var insns: [Instruction] = []
        
        self.data = data
        self.loadAddress = loadAddress
        offset = data.startIndex
        
        while offset < data.endIndex {
            let startOffset = offset
            let instructionWord = readWord()
            
            guard let opClass = opTable[Int(instructionWord)] else {
                return insns
            }
            
            switch opClass {
            case .add:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!
                let address = readAddress(eaMode, Int(eaReg))

                let register = DataRegister(rawValue: Int(instructionWord >> 9) & 7)!

                let size0 = (instructionWord >> 6) & 3
                let size: Size?
                switch size0 {
                case 0: size = .b
                case 1: size = .w
                case 2: size = .l
                default: size = nil
                }

                let direction0 = (instructionWord >> 8) & 1
                let direction: Direction = direction0 == 1 ? .rToM : .mToR

                let op = Operation.add(size!, direction, address, register)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .and:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!
                let address = readAddress(eaMode, Int(eaReg))

                
                let register = DataRegister(rawValue: Int(instructionWord >> 9) & 7)!

                let size0 = (instructionWord >> 6) & 3
                let size: Size?
                switch size0 {
                case 0: size = .b
                case 1: size = .w
                case 2: size = .l
                default: size = nil
                }

                let direction0 = (instructionWord >> 8) & 1
                let direction: Direction = direction0 == 1 ? .rToM : .mToR
                
                let op = Operation.and(size!, direction, address, register)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .andi:
                let size0 = (instructionWord >> 6) & 3
                let size: Size
                let data: Int32
                switch size0 {
                case 0:
                    size = .b
                    data = Int32(Int8(truncatingIfNeeded: readWord()))
                case 1:
                    size = .w
                    data = Int32(Int16(bitPattern: readWord()))
                case 2:
                    size = .l
                    data = Int32(bitPattern: readLong())
                default:
                    fatalError("unknown size")
                }
                
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!

                let address = readAddress(eaMode, Int(eaReg))

                let op = Operation.andi(size, data, address)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))

            case .bra:
                // TODO: '20, '30, and '40 support 32 bit displacement
                var displacement = Int16(Int8(bitPattern: UInt8(instructionWord & 0xFF)))
                var size = Size.b
                
                if displacement == 0 {
                    displacement = Int16(bitPattern: readWord())
                    size = .w
                }
                
                let op = Operation.bra(size, loadAddress+UInt32(startOffset+2), displacement)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .bcc:
                // TODO: '20, '30, and '40 support 32 bit displacement
                let condition = Condition(rawValue: Int((instructionWord >> 8) & 0xf))!
                var displacement = Int16(Int8(bitPattern: UInt8(instructionWord & 0xFF)))
                var size = Size.b
                
                if displacement == 0 {
                    displacement = Int16(bitPattern: readWord())
                    size = .w
                }

                let op = Operation.bcc(size, condition, loadAddress+UInt32(startOffset+2), displacement)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
                
            case .move:
                let size0 = (instructionWord >> 12) & 3
                
                var size: Size?
                if size0 == 1 {
                    size = .b
                } else if size0 == 3 {
                    size = .w
                } else if size0 == 2 {
                    size = .l
                }
                
                let dstReg = (instructionWord >> 9) & 7
                let dstModeNum = (instructionWord >> 6) & 7
                let dstMode = AddressingMode.for(Int(dstModeNum), reg: Int(dstReg))!
                
                
                let srcModeNum = (instructionWord >> 3) & 7
                let srcReg = instructionWord & 7
                let srcMode = AddressingMode.for(Int(srcModeNum), reg: Int(srcReg))!
                
                let srcAddr = readAddress(srcMode, Int(srcReg), size: size!)
                let dstAddr = readAddress(dstMode, Int(dstReg), size: size!)
                
                let op = Operation.move(size!, srcAddr, dstAddr)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
                
            case .lea:
                let w = Int(instructionWord)
                
                let dstReg = AddressRegister(rawValue: (w >> 9) & 7)!
                
                let srcModeNum = (w >> 3) & 7
                let srcReg = w & 7
                let srcMode = AddressingMode.for(srcModeNum, reg: srcReg)!
                
                let srcAddr = readAddress(srcMode, srcReg)
                
                let op = Operation.lea(srcAddr, dstReg)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .suba:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!
                let address = readAddress(eaMode, Int(eaReg))

                let register = AddressRegister(rawValue: Int((instructionWord >> 9) & 7))!
                
                let opmode = (instructionWord >> 6) & 7
                let size: Size = opmode == 7 ? .l : .w
                
                let op = Operation.suba(size, address, register)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .subq:
                var data = UInt8((instructionWord >> 9) & 7)
                if data == 0 {
                    data = 8
                }
                
                let size0 = (instructionWord >> 6) & 3
                
                var size: Size?
                if size0 == 0 {
                    size = .b
                } else if size0 == 1 {
                    size = .w
                } else if size0 == 2 {
                    size = .l
                }

                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!
                
                let address = readAddress(eaMode, Int(eaReg))

                let op = Operation.subq(size!, data, address)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .movem:
                let direction0 = (instructionWord >> 10) & 1
                let size0 = (instructionWord >> 6) & 1
                let size = size0 == 1 ? Size.l : Size.w
                
                let registers0 = readWord()
                
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!
                
                let address = readAddress(eaMode, Int(eaReg))
                
                let registers: RegisterList
                if case .preDec(_) = address {
                    registers = RegisterList(rawValue: registers0.bitSwapped)
                } else {
                    registers = RegisterList(rawValue: registers0)
                }

                let direction: Direction = direction0 == 1 ? .mToR : .rToM
                
                let op = Operation.movem(size, direction, address, registers)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .cmp:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!
                
                let address = readAddress(eaMode, Int(eaReg))

                let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7))
                
                let opmode = (instructionWord >> 6) & 7
                
                let size: Size?
                switch opmode {
                case 0: size = .b
                case 1: size = .w
                case 2: size = .l
                default: size = nil
                }
                
                let op = Operation.cmp(size!, address, register!)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .cmpi:
                let size0 = (instructionWord >> 6) & 3
                let size: Size
                let data: Int32
                switch size0 {
                case 0:
                    size = .b
                    data = Int32(Int8(truncatingIfNeeded: readWord()))
                case 1:
                    size = .w
                    data = Int32(Int16(bitPattern: readWord()))
                case 2:
                    size = .l
                    data = Int32(bitPattern: readLong())
                default:
                    fatalError("unknown size")
                }
                
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!

                let address = readAddress(eaMode, Int(eaReg))

                let op = Operation.cmpi(size, data, address)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .jmp:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!

                let address = readAddress(eaMode, Int(eaReg))

                let op = Operation.jmp(address)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .moveToSR:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!

                let address = readAddress(eaMode, Int(eaReg), size: .w)
                
                let op = Operation.moveToSR(address)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .moveq:
                let data = Int8(truncatingIfNeeded: instructionWord)
                let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7))!
                
                let op = Operation.moveq(data, register)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .tst:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!

                let address = readAddress(eaMode, Int(eaReg), size: .w)

                
                let size0 = (instructionWord >> 6) & 3
                let size: Size?
                switch size0 {
                case 0: size = .b
                case 1: size = .w
                case 2: size = .l
                default: size = nil
                }
                
                let op = Operation.tst(size!, address)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .or:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!
                let address = readAddress(eaMode, Int(eaReg))

                
                let register = DataRegister(rawValue: Int(instructionWord >> 9) & 7)!

                let size0 = (instructionWord >> 6) & 3
                let size: Size?
                switch size0 {
                case 0: size = .b
                case 1: size = .w
                case 2: size = .l
                default: size = nil
                }

                let direction0 = (instructionWord >> 8) & 1
                let direction: Direction = direction0 == 1 ? .rToM : .mToR
                
                let op = Operation.or(size!, direction, address, register)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .ls:
                let countOrRegister = (instructionWord >> 9) & 7
                let direction = (instructionWord >> 8) & 1
                let size0 = (instructionWord >> 6) & 3
                let immOrReg = (instructionWord >> 5) & 1
                let register = DataRegister(rawValue: Int(instructionWord & 7))!
                
                let count: ShiftCount
                if immOrReg == 1 {
                    count = .r(DataRegister(rawValue: Int(countOrRegister))!)
                } else {
                    count = .imm(UInt8(countOrRegister == 0 ? 8 : countOrRegister))
                }
                
                let size: Size?
                switch size0 {
                case 0: size = .b
                case 1: size = .w
                case 2: size = .l
                default: size = nil
                }
                
                let op: Operation
                if (direction == 1) {
                    op = .lsl(size!, count, register)
                } else {
                    op = .lsr(size!, count, register)
                }
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .lsm:
                // TODO
                return insns
            case .clr:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!
                let address = readAddress(eaMode, Int(eaReg))

                let size0 = (instructionWord >> 6) & 3
                let size: Size?
                switch size0 {
                case 0: size = .b
                case 1: size = .w
                case 2: size = .l
                default: size = nil
                }

                let op = Operation.clr(size!, address)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .bseti:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!
                
                let bitNumber = UInt8(truncatingIfNeeded: readWord())
                let address = readAddress(eaMode, Int(eaReg))

                let op = Operation.bset(.imm(bitNumber), address)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            case .bsetr:
                let eaModeNum = (instructionWord >> 3) & 7
                let eaReg = instructionWord & 7
                
                let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg))!
                let address = readAddress(eaMode, Int(eaReg))

                let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7))!
                
                let op = Operation.bset(.r(register), address)
                
                insns.append(makeInstruction(op: op, startOffset: startOffset))
            }
        }
        
        return insns
    }
    
    func makeInstruction(op: Operation, startOffset: Int) -> Instruction {
        return Instruction(op: op, address: address(of: startOffset), data: data(from: startOffset))
    }
    
    func address(of offset: Int) -> UInt32 {
        loadAddress + UInt32(offset)
    }
    
    func data(from startOffset: Int) -> Data {
        data[startOffset..<offset]
    }
    
    mutating func readAddress(_ mode: AddressingMode, _ reg: Int, size: Size? = nil) -> EffectiveAddress {
        switch mode {
        case .dd: return .dd(DataRegister(rawValue: reg)!)
        case .ad: return .ad(AddressRegister(rawValue: reg)!)
        case .ind: return .ind(AddressRegister(rawValue: reg)!)
        case .postInc: return .postInc(AddressRegister(rawValue: reg)!)
        case .preDec: return .preDec(AddressRegister(rawValue: reg)!)
        case .d16An:
            let val = Int16(bitPattern: readWord())
            
            return .d16An(val, AddressRegister(rawValue: reg)!)
        case .d8AnXn: fatalError("d8AnXn not implemented")
        case .XXXw:
            let val = UInt32(truncatingIfNeeded: Int16(bitPattern: readWord()))
            
            return .XXXw(val)
        case .XXXl:
            let val = readLong()
            
            return .XXXl(val)
        case .d16PC:
            let exOffset = UInt32(offset)
            let ex = readExtensionWord()
            return .d16PC(loadAddress+exOffset, Int16(ex.displacement))
        case .d8PCXn:
            fatalError("d8PCXn not implemented")
        case .imm:
            switch size! {
            case .b: return .imm(.b(Int8(truncatingIfNeeded: readWord())))
            case .w: return .imm(.w(Int16(bitPattern: readWord())))
            case .l: return .imm(.l(Int32(bitPattern: readLong())))
            }
        }
    }

    mutating func readExtensionWord() -> ExtensionWord {
        let w = readWord()
        
        if (w & 0x100) == 0x100 {
            fatalError("Full extension words are not yet supported")
        }
        
        let displacement = Int8(w & 0xFF)
        
        return ExtensionWord(displacement: displacement)
    }
    
    mutating func readByte() -> UInt8 {
        defer { offset += 1 }
        return data[offset]
    }
    
    mutating func readWord() -> UInt16 {
        var w = UInt16(readByte()) << 8
        w += UInt16(readByte())
        
        return w
    }
    
    mutating func readLong() -> UInt32 {
        var l = UInt32(readByte()) << 24
        l += UInt32(readByte()) << 16
        l += UInt32(readByte()) << 8
        l += UInt32(readByte())
        
        return l
    }
}
