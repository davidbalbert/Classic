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

enum DataRegister: Int, CustomStringConvertible {
    case d0, d1, d2, d3, d4, d5, d6, d7
    
    var description: String {
        "D\(rawValue)"
    }
}

enum AddressRegister: Int, CustomStringConvertible {
    case a0, a1, a2, a3, a4, a5, a6, a7
    
    var description: String {
        "A\(rawValue)"
    }
}

enum Register: CustomStringConvertible {
    case a(AddressRegister)
    case d(DataRegister)
    
    var description: String {
        switch self {
        case let .a(An): return "\(An)"
        case let .d(Dn): return "\(Dn)"
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


enum AddressingMode: Int {
    case dd
    case ad
    case ind
    case postInc
    case preDec
    case d16An
    case d8AnXn
    
    // TODO: these all have mode as 0b111
    // case XXXw
    // case XXXl
    case d16PC = 0x12
    // case d8PCXn
    // case imm
    
    static func mode(for mode: Int, reg: Int) -> AddressingMode? {
        if mode == 0b111 {
            return AddressingMode(rawValue: 0x10 + reg)
        } else {
            return AddressingMode(rawValue: mode)
        }
    }
}

enum EffectiveAddress: CustomStringConvertible {
    case dd(DataRegister)
    case ad(AddressRegister)
    case ind(AddressRegister)
    case postInc(AddressRegister)
    case preDec(AddressRegister)
    case d16An(Int16, AddressRegister)
    case d8AnXn(Int8, AddressRegister, Register)
    case d16PC(UInt32, Int16)
    
    var description: String {
        switch self {
        case let .dd(Dn):             return "\(Dn)"
        case let .ad(An):             return "\(An)"
        case let .ind(An):            return "(\(An))"
        case let .postInc(An):        return "(\(An))+"
        case let .preDec(An):         return "-(\(An))"
        case let .d16An(d16, An):     return "$\(String(d16, radix: 16))(\(An))"
        case let .d8AnXn(d8, An, Xn): return "$\(String(d8, radix: 16))(\(An),\(Xn))"
        case let .d16PC(pc, d16):         return "$\(String(Int(pc)+Int(d16), radix: 16))(PC)"
        }
    }
}

struct ExtensionWord {
    let displacement: Int8
}

enum Size: Int {
    case b = 1
    case w = 3
    case l = 2
}

enum OpName: String {
    case bra
    case moveb
    case movew
    case movel
    case lea
}

enum OpClass: String {
    case bra
    case move
    case lea
}

struct OpInfo {
    let name: OpName
    let opClass: OpClass
    let mask: UInt16
    let value: UInt16
}

enum Operation {
    case bra(Size, UInt32, UInt16)
    case move(Size, EffectiveAddress, EffectiveAddress)
    case lea(EffectiveAddress, AddressRegister)
}

extension Operation: CustomStringConvertible {
    var description: String {
        switch self {
        case let .bra(size, address, displacement):
            return "bra.\(size) $\(String(address + 2 + UInt32(displacement), radix: 16))"
        case let .move(size, from, to):
            return "move.\(size) \(from), \(to)"
        case let .lea(address, register):
            return "lea \(address), \(register)"
        }
    }
}


struct Instruction: CustomStringConvertible {
    let op: Operation
    let address: UInt32
    let data: Data
    
    var description: String {
        let hex = data.hexDump().padding(toLength: 16, withPad: " ", startingAt: 0)
        
        return "\(hex)\(op)"
    }
}

let ops = [
    OpInfo(name: .bra,   opClass: .bra,  mask: 0xff00, value: 0x6000),
    OpInfo(name: .moveb, opClass: .move, mask: 0xf000, value: 0x1000),
    OpInfo(name: .movew, opClass: .move, mask: 0xf000, value: 0x3000),
    OpInfo(name: .movel, opClass: .move, mask: 0xf000, value: 0x2000),
    OpInfo(name: .lea,   opClass: .lea,  mask: 0xf1c0, value: 0x41c0)

//    OpInfo(name: "exg", mask: 0xf130, value: 0xc100)
]

struct Disassembler {
    var opTable: [OpClass?]
    let data: Data
    var offset: Data.Index
    let loadAddress: UInt32
    
    init(_ data: Data, loadAddress: UInt32) {
        self.data = data
        self.loadAddress = loadAddress
        offset = data.startIndex
        opTable = Array(repeating: nil, count: Int(UInt16.max))
        
        for i in 0...Int(UInt16.max) {
            for opInfo in ops {
                if UInt16(i) & opInfo.mask == opInfo.value {
                    opTable[i] = opInfo.opClass
                }
            }
        }
    }
    
    mutating func disassemble() -> [Instruction] {
        var insns: [Instruction] = []
        
        while offset < data.endIndex {
            let startOffset = offset
            let instructionWord = readWord()
            
            guard let opClass = opTable[Int(instructionWord)] else {
                return insns
            }
            
            switch opClass {
            case .bra:
                // TODO: '20, '30, and '40 support 32 bit displacement
                var displacement = instructionWord & 0xFF
                var size = Size.b
                
                if displacement == 0 {
                    displacement = readWord()
                    size = .w
                }
                
                let op = Operation.bra(size, loadAddress+UInt32(startOffset), displacement)
                
                insns.append(Instruction(op: op, address: address(of: startOffset), data: data(from: startOffset)))
                
            case .move:
                let w = Int(instructionWord)
                
                let size = Size(rawValue: (w >> 12) & 3)!
                
                let dstReg = (w >> 9) & 7
                let dstMode = AddressingMode(rawValue: (w >> 6) & 7)!
                let srcMode = AddressingMode(rawValue: (w >> 3) & 7)!
                let srcReg = w & 7
                
                let dstAddr = readAddress(dstMode, dstReg)
                let srcAddr = readAddress(srcMode, srcReg)
                
                let op = Operation.move(size, srcAddr, dstAddr)
                
                insns.append(Instruction(op: op, address: address(of: startOffset), data: data(from: startOffset)))
                
            case .lea:
                let w = Int(instructionWord)
                
                let dstReg = AddressRegister(rawValue: (w >> 9) & 7)!
                
                let srcModeNum = (w >> 3) & 7
                let srcReg = w & 7
                let srcMode = AddressingMode.mode(for: srcModeNum, reg: srcReg)!
                
                let srcAddr = readAddress(srcMode, srcReg)
                
                let op = Operation.lea(srcAddr, dstReg)
                
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
    
    mutating func readAddress(_ mode: AddressingMode, _ reg: Int) -> EffectiveAddress {
        switch mode {
        case .dd: return .dd(DataRegister(rawValue: reg)!)
        case .ad: return .ad(AddressRegister(rawValue: reg)!)
        case .ind: return .ind(AddressRegister(rawValue: reg)!)
        case .postInc: return .postInc(AddressRegister(rawValue: reg)!)
        case .preDec: return .preDec(AddressRegister(rawValue: reg)!)
        case .d16An: fatalError("d16An not implemented")
        case .d8AnXn: fatalError("d8AnXn not implemented")
        case .d16PC:
            let exOffset = UInt32(offset)
            let ex = readExtensionWord()
            return .d16PC(loadAddress+exOffset, Int16(ex.displacement))
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
