//
//  Instruction.swift
//  M68K
//
//  Created by David Albert on 7/26/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Foundation

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

enum DataRegister: Int, Equatable, CustomStringConvertible {
    case d0, d1, d2, d3, d4, d5, d6, d7
    
    var description: String {
        "D\(rawValue)"
    }
    
    var keyPath: WritableKeyPath<CPU, UInt32> {
        switch self {
        case .d0: return \.d0
        case .d1: return \.d1
        case .d2: return \.d2
        case .d3: return \.d3
        case .d4: return \.d4
        case .d5: return \.d5
        case .d6: return \.d6
        case .d7: return \.d7
        }
    }
}

enum AddressRegister: Int, Equatable, CustomStringConvertible {
    case a0, a1, a2, a3, a4, a5, a6, a7
    
    var description: String {
        "A\(rawValue)"
    }
    
    var keyPath: WritableKeyPath<CPU, UInt32> {
        switch self {
        case .a0: return \.a0
        case .a1: return \.a1
        case .a2: return \.a2
        case .a3: return \.a3
        case .a4: return \.a4
        case .a5: return \.a5
        case .a6: return \.a6
        case .a7: return \.a7
        }
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

enum MemoryAddress: Equatable, CustomStringConvertible {
    case ind(AddressRegister)
    case postInc(AddressRegister)
    case preDec(AddressRegister)
    case d16An(Int16, AddressRegister)
    case d8AnXn(Int8, AddressRegister, Register, Size)
    case XXXw(UInt32)
    case XXXl(UInt32)
    case d16PC(UInt32, Int16)
    case d8PCXn(UInt32, Int8, Register, Size)
    
    init(_ ea: MemoryAlterableAddress) {
        switch ea {
        case let .ind(An):                 self = .ind(An)
        case let .postInc(An):             self = .postInc(An)
        case let .preDec(An):              self = .preDec(An)
        case let .d16An(d, An):            self = .d16An(d, An)
        case let .d8AnXn(d, An, Xn, size): self = .d8AnXn(d, An, Xn, size)
        case let .XXXw(address):           self = .XXXw(address)
        case let .XXXl(address):           self = .XXXl(address)
        }
    }
    
    init(_ ea: ControlAddress) {
        switch ea {
        case let .ind(An):                 self = .ind(An)
        case let .d16An(d, An):            self = .d16An(d, An)
        case let .d8AnXn(d, An, Xn, size): self = .d8AnXn(d, An, Xn, size)
        case let .XXXw(address):           self = .XXXw(address)
        case let .XXXl(address):           self = .XXXl(address)
        case let .d16PC(pc, d):            self = .d16PC(pc, d)
        case let .d8PCXn(pc, d, Xn, size): self = .d8PCXn(pc, d, Xn, size)
        }
    }
    
    init(_ ea: ControlAlterableOrPostIncrementAddress) {
        switch ea {
        case let .ind(An):                 self = .ind(An)
        case let .postInc(An):             self = .postInc(An)
        case let .d16An(d, An):            self = .d16An(d, An)
        case let .d8AnXn(d, An, Xn, size): self = .d8AnXn(d, An, Xn, size)
        case let .XXXw(address):           self = .XXXw(address)
        case let .XXXl(address):           self = .XXXl(address)
        }
    }

    init(_ ea: ControlAlterableOrPreDecrementAddress) {
        switch ea {
        case let .ind(An):                 self = .ind(An)
        case let .preDec(An):              self = .preDec(An)
        case let .d16An(d, An):            self = .d16An(d, An)
        case let .d8AnXn(d, An, Xn, size): self = .d8AnXn(d, An, Xn, size)
        case let .XXXw(address):           self = .XXXw(address)
        case let .XXXl(address):           self = .XXXl(address)
        }
    }
    
    var description: String {
        switch self {
        case let .ind(An):            return "(\(An))"
        case let .postInc(An):        return "(\(An))+"
        case let .preDec(An):         return "-(\(An))"
        case let .d16An(d16, An):     return "$\(String(d16, radix: 16))(\(An))"
        case let .d8AnXn(d8, An, Xn, size): return "$\(String(d8, radix: 16))(\(An), \(Xn).\(size))"
        case let .XXXw(address):      return "($\(String(address, radix: 16)))"
        case let .XXXl(address):      return "($\(String(address, radix: 16)))"
        case let .d16PC(pc, d16):     return "$\(String(Int(pc)+Int(d16), radix: 16))(PC)"
        case let .d8PCXn(pc, d8, Xn, size): return "$\(String(Int(pc) + Int(d8), radix: 16))(PC, \(Xn).\(size))"
        }
    }
}

enum MemoryAlterableAddress: Equatable, CustomStringConvertible {
    case ind(AddressRegister)
    case postInc(AddressRegister)
    case preDec(AddressRegister)
    case d16An(Int16, AddressRegister)
    case d8AnXn(Int8, AddressRegister, Register, Size)
    case XXXw(UInt32)
    case XXXl(UInt32)
    
    var description: String {
        String(describing: MemoryAddress(self))
    }
}

enum ControlAddress: Equatable, CustomStringConvertible {
    case ind(AddressRegister)
    case d16An(Int16, AddressRegister)
    case d8AnXn(Int8, AddressRegister, Register, Size)
    case XXXw(UInt32)
    case XXXl(UInt32)
    case d16PC(UInt32, Int16)
    case d8PCXn(UInt32, Int8, Register, Size)
    
    var description: String {
        String(describing: MemoryAddress(self))
    }
}

enum ControlAlterableOrPostIncrementAddress: Equatable, CustomStringConvertible {
    case ind(AddressRegister)
    case postInc(AddressRegister)
    case d16An(Int16, AddressRegister)
    case d8AnXn(Int8, AddressRegister, Register, Size)
    case XXXw(UInt32)
    case XXXl(UInt32)

    var description: String {
        String(describing: MemoryAddress(self))
    }
}

enum ControlAlterableOrPreDecrementAddress: Equatable, CustomStringConvertible {
    case ind(AddressRegister)
    case preDec(AddressRegister)
    case d16An(Int16, AddressRegister)
    case d8AnXn(Int8, AddressRegister, Register, Size)
    case XXXw(UInt32)
    case XXXl(UInt32)

    var description: String {
        String(describing: MemoryAddress(self))
    }
}

enum EffectiveAddress: Equatable, CustomStringConvertible {
    case dd(DataRegister)
    case ad(AddressRegister)
    case m(MemoryAddress)
    
    // The M68K programmers manual clasifies immediate mode addressing
    // as part of the "memory" group, but we don't classify it as MemoryAddress
    // because we want to be able to call address(for:) on MemoryAddress, and
    // immediate values don't have an address.
    case imm(Int32)
    
    init(_ ea: DataAddress) {
        switch ea {
        case let .dd(Dn):     self = .dd(Dn)
        case let .m(address): self = .m(address)
        case let .imm(value): self = .imm(value)
        }
    }
    
    var description: String {
        switch self {
        case let .dd(Dn):             return "\(Dn)"
        case let .ad(An):             return "\(An)"
        case let .m(address):         return "\(address)"
        case let .imm(value):         return "#$\(String(value, radix: 16))"
        }
    }
}

enum AlterableAddress: Equatable, CustomStringConvertible {
    case dd(DataRegister)
    case ad(AddressRegister)
    case m(MemoryAlterableAddress)
    
    var description: String {
        switch self {
        case let .dd(Dn):     return "\(Dn)"
        case let .ad(An):     return "\(An)"
        case let .m(address): return "\(address)"
        }
    }
}

enum DataAddress: Equatable, CustomStringConvertible {
    case dd(DataRegister)
    case m(MemoryAddress)
    case imm(Int32)
    
    var description: String {
        switch self {
        case let .dd(Dn):             return "\(Dn)"
        case let .m(address):         return "\(address)"
        case let .imm(value):         return "#$\(String(value, radix: 16))"
        }
    }
}

enum DataAlterableAddress: Equatable, CustomStringConvertible {
    case dd(DataRegister)
    case m(MemoryAlterableAddress)
    
    var description: String {
        switch self {
        case let .dd(Dn):     return "\(Dn)"
        case let .m(address): return "\(address)"
        }
    }
}

struct ExtensionWord {
    let indexRegister: Register
    let indexSize: Size
    let displacement: Int8
}

enum SizeWL: Equatable {
    case w
    case l
}

enum Size: Equatable {
    case b
    case w
    case l
    
    init(_ sizeWL: SizeWL) {
        switch sizeWL {
        case .w: self = .w
        case .l: self = .l
        }
    }
    
    var byteCount: UInt32 {
        switch self {
        case .b: return 1
        case .w: return 2
        case .l: return 3
        }
    }
}

enum Condition: Int, Equatable, CaseIterable {
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
    
    var keyPaths: [WritableKeyPath<CPU, UInt32>] {
        var res: [WritableKeyPath<CPU, UInt32>] = []
        
        if contains(.d0) { res.append(\CPU.d0) }
        if contains(.d1) { res.append(\CPU.d1) }
        if contains(.d2) { res.append(\CPU.d2) }
        if contains(.d3) { res.append(\CPU.d3) }
        if contains(.d4) { res.append(\CPU.d4) }
        if contains(.d5) { res.append(\CPU.d5) }
        if contains(.d6) { res.append(\CPU.d6) }
        if contains(.d7) { res.append(\CPU.d7) }
        
        if contains(.a0) { res.append(\CPU.a0) }
        if contains(.a1) { res.append(\CPU.a1) }
        if contains(.a2) { res.append(\CPU.a2) }
        if contains(.a3) { res.append(\CPU.a3) }
        if contains(.a4) { res.append(\CPU.a4) }
        if contains(.a5) { res.append(\CPU.a5) }
        if contains(.a6) { res.append(\CPU.a6) }
        if contains(.a7) { res.append(\CPU.a7) }

        return res
    }
    
    var registers: [Register] {
        var res: [Register] = []
    
        if contains(.d0) { res.append(.d(.d0)) }
        if contains(.d1) { res.append(.d(.d1)) }
        if contains(.d2) { res.append(.d(.d2)) }
        if contains(.d3) { res.append(.d(.d3)) }
        if contains(.d4) { res.append(.d(.d4)) }
        if contains(.d5) { res.append(.d(.d5)) }
        if contains(.d6) { res.append(.d(.d6)) }
        if contains(.d7) { res.append(.d(.d7)) }
        
        if contains(.a0) { res.append(.a(.a0)) }
        if contains(.a1) { res.append(.a(.a1)) }
        if contains(.a2) { res.append(.a(.a2)) }
        if contains(.a3) { res.append(.a(.a3)) }
        if contains(.a4) { res.append(.a(.a4)) }
        if contains(.a5) { res.append(.a(.a5)) }
        if contains(.a6) { res.append(.a(.a6)) }
        if contains(.a7) { res.append(.a(.a7)) }

        return res
    }
}

enum ShiftCount: Equatable {
    case r(DataRegister)
    case imm(UInt8)
}

enum RotateCount: Equatable {
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
    case adda
    case addib, addiw, addil
    case addqb, addqw, addql
    case andb, andw, andl
    case andib, andiw, andil
    case aslb, aslw, asll, aslm
    case asrb, asrw, asrl, asrm
    case bra
    case bcc
    case bchgr, bchgi
    case cmpb, cmpw, cmpl
    case cmpa
    case cmpib, cmpiw, cmpil
    case eorb, eorw, eorl
    case extw, extl
    case extbl
    case dbcc
    case lea
    case moveb, movew, movel
    case moveaw, moveal
    case movem
    case moveq
    case moveToSR, moveFromSR
    case nop
    case notb, notw, notl
    case pea
    case rts
    case scc
    case subb, subw, subl
    case subaw, subal
    case subib, subiw, subil
    case subqb, subqw, subql
    case jmp
    case jsr
    case tstb, tstw, tstl
    case orb, orw, orl
    case oriToSR
    case lslb, lslw, lsll, lslm
    case lsrb, lsrw, lsrl, lsrm
    case clrb, clrw, clrl
    case bseti, bsetr
    case bclri, bclrr
    case btsti, btstr
    case swap
    case rolb, rolw, roll, rolm
    case rorb, rorw, rorl, rorm
    case roxlb, roxlw, roxll, roxlm
    case roxrb, roxrw, roxrl, roxrm
    case mulu
}

enum OpClass: String {
    case add
    case adda
    case addi
    case addq
    case and
    case andi
    case aslr, aslrm
    case bra
    case bcc
    case bchgr, bchgi
    case cmp
    case cmpa
    case cmpi
    case dbcc
    case eor
    case ext
    case lea
    case move
    case movea
    case movem
    case moveq
    case moveToSR, moveFromSR
    case nop
    case not
    case pea
    case rts
    case scc
    case sub
    case suba
    case subi
    case subq
    case jmp
    case jsr
    case tst
    case or
    case oriToSR
    case lslr, lslrm
    case clr
    case bseti, bsetr
    case bclri, bclrr
    case btsti, btstr
    case swap
    case rolr, rolrm
    case roxlr, roxlrm
    case mulu
    
    case unknown
}

struct OpInfo {
    let name: OpName
    let opClass: OpClass
    let mask: UInt16
    let value: UInt16
}

enum Operation: Equatable {
    case addMR(Size, EffectiveAddress, DataRegister)
    case addRM(Size, DataRegister, MemoryAlterableAddress)
    case adda(SizeWL, EffectiveAddress, AddressRegister)
    case addi(Size, Int32, DataAlterableAddress)
    case addq(Size, UInt8, AlterableAddress)
    case andMR(Size, DataAddress, DataRegister)
    case andRM(Size, DataRegister, MemoryAlterableAddress)
    case andi(Size, Int32, DataAlterableAddress)
    case asl(Size, ShiftCount, DataRegister)
    case asr(Size, ShiftCount, DataRegister)
    case aslm(MemoryAlterableAddress)
    case asrm(MemoryAlterableAddress)
    case bra(Size, UInt32, Int16)
    case bcc(Size, Condition, UInt32, Int16)
    case bchg(Size, BitNumber, DataAlterableAddress)
    case bclr(BitNumber, DataAlterableAddress)
    case bset(BitNumber, DataAlterableAddress)
    case btst(BitNumber, DataAddress)
    case cmp(Size, EffectiveAddress, DataRegister)
    case cmpa(Size, EffectiveAddress, AddressRegister)
    case cmpi(Size, Int32, DataAddress)
    case dbcc(Condition, DataRegister, UInt32, Int16)
    case eor(Size, DataRegister, DataAlterableAddress)
    case ext(Size, DataRegister)
    case extbl(DataRegister)
    case lea(ControlAddress, AddressRegister)
    case move(Size, EffectiveAddress, DataAlterableAddress)
    case movea(SizeWL, EffectiveAddress, AddressRegister)
    case movemMR(SizeWL, ControlAlterableOrPostIncrementAddress, RegisterList)
    case movemRM(SizeWL, RegisterList, ControlAlterableOrPreDecrementAddress)
    case moveq(Int8, DataRegister)
    case moveToSR(DataAddress)
    case moveFromSR(DataAlterableAddress)
    case nop
    case not(Size, DataAlterableAddress)
    case pea(ControlAddress)
    case rts
    case scc(Condition, DataAlterableAddress)
    case subMR(Size, EffectiveAddress, DataRegister)
    case subRM(Size, DataRegister, MemoryAlterableAddress)
    case suba(SizeWL, EffectiveAddress, AddressRegister)
    case subi(Size, Int32, EffectiveAddress)
    case subq(Size, UInt8, EffectiveAddress)
    case jmp(ControlAddress)
    case jsr(EffectiveAddress)
    case tst(Size, EffectiveAddress)
    case or(Size, Direction, EffectiveAddress, DataRegister)
    case oriToSR(Int16)
    case lsl(Size, ShiftCount, DataRegister)
    case lsr(Size, ShiftCount, DataRegister)
    case lslm(EffectiveAddress)
    case lsrm(EffectiveAddress)
    case clr(Size, EffectiveAddress)
    case swap(DataRegister)
    case rol(Size, RotateCount, DataRegister)
    case ror(Size, RotateCount, DataRegister)
    case rolm(EffectiveAddress)
    case rorm(EffectiveAddress)
    case roxl(Size, RotateCount, DataRegister)
    case roxr(Size, RotateCount, DataRegister)
    case roxlm(EffectiveAddress)
    case roxrm(EffectiveAddress)
    case mulu(EffectiveAddress, DataRegister)
    
    case unknown(UInt16)
}

extension Operation: CustomStringConvertible {
    var description: String {
        switch self {
        case let .addMR(size, address, register):
            return "add.\(size) \(address), \(register)"
        case let .addRM(size, register, address):
            return "add.\(size) \(register), \(address)"
        case let .adda(size, address, register):
            return "adda.\(size) \(address), \(register)"
        case let .addi(size, data, address):
            return "addi.\(size) #$\(String(data, radix: 16)), \(address)"
        case let .addq(size, data, address):
            return "addq.\(size) #$\(String(data, radix: 16)), \(address)"
        case let .andMR(size, address, register):
            return "and.\(size) \(address), \(register)"
        case let .andRM(size, register, address):
            return "and.\(size) \(register), \(address)"
        case let .andi(size, data, address):
            return "and.\(size) #$\(String(data, radix: 16)), \(address)"
        case let .asl(size, .imm(count), register):
            return "asl.\(size) #$\(String(count, radix: 16)), \(register)"
        case let .asl(size, .r(countRegister), register):
            return "asl.\(size) \(countRegister), \(register)"
        case let .aslm(address):
            return "asl \(address)"
        case let .asr(size, .imm(count), register):
            return "asr.\(size) #$\(String(count, radix: 16)), \(register)"
        case let .asr(size, .r(countRegister), register):
            return "asr.\(size) \(countRegister), \(register)"
        case let .asrm(address):
            return "asr \(address)"
        case let .bra(size, pc, displacement):
            return "bra.\(size) $\(String(Int64(pc) + Int64(displacement), radix: 16))"
        case let .bcc(size, condition, pc, displacement):
            return "b\(condition).\(size) $\(String(Int64(pc) + Int64(displacement), radix: 16))"
        case let .bchg(size, .r(register), address):
            return "bchg.\(size) \(register), \(address)"
        case let .bchg(size, .imm(data), address):
            return "bchg.\(size) #$\(String(data, radix: 16)), \(address)"
        case let .dbcc(condition, register, pc, displacement):
            return "db\(condition) \(register), $\(String(Int64(pc) + Int64(displacement), radix: 16))"
        case let .eor(size, register, address):
            return "eor.\(size) \(register), \(address)"
        case let .ext(size, register):
            return "ext.\(size) \(register)"
        case let .extbl(register):
            return "extb.l \(register)"
        case let .move(size, from, to):
            return "move.\(size) \(from), \(to)"
        case let .movea(size, from, to):
            return "movea.\(size) \(from), \(to)"
        case let .lea(address, register):
            return "lea \(address), \(register)"
        case let .scc(condition, address):
            return "s\(condition) \(address)"
        case let .subMR(size, address, register):
            return "sub.\(size) \(address), \(register)"
        case let .subRM(size, register, address):
            return "sub.\(size) \(register), \(address)"
        case let .suba(size, address, register):
            return "suba.\(size) \(address), \(register)"
        case let .subi(size, data, address):
            return "sub.\(size) #$\(String(data, radix: 16)), \(address)"
        case let .subq(size, data, address):
            return "subq.\(size) #$\(String(data, radix: 16)), \(address)"
        case let .movemRM(size, registers, address):
            return "movem.\(size) \(registers), \(address)"
        case let .movemMR(size, address, registers):
            return "movem.\(size) \(address), \(registers)"
        case let .moveq(data, register):
            return "moveq #$\(String(data, radix: 16)), \(register)"
        case let .moveToSR(address):
            return "move \(address), SR"
        case let .moveFromSR(address):
            return "move SR, \(address)"
        case .nop:
            return "nop"
        case let .not(size, address):
            return "not.\(size), \(address)"
        case let .pea(address):
            return "pea \(address)"
        case .rts:
            return "rts"
        case let .cmp(size, address, register):
            return "cmp.\(size) \(address), \(register)"
        case let .cmpa(size, address, register):
            return "cmpa.\(size) \(address), \(register)"
        case let .cmpi(size, data, address):
            return "cmp.\(size) #$\(String(data, radix: 16)), \(address)"
        case let .jmp(address):
            return "jmp \(address)"
        case let .jsr(address):
            return "jsr \(address)"
        case let .tst(size, address):
            return "tst.\(size) \(address)"
        case let .or(size, .mToR, address, register):
            return "or.\(size) \(address), \(register)"
        case let .or(size, .rToM, address, register):
            return "or.\(size) \(register), \(address)"
        case let .oriToSR(data):
            return "or #$\(String(data, radix: 16)), SR"
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
        case let .bclr(.imm(bitNumber), address):
            return "bclr #$\(String(bitNumber, radix: 16)), \(address)"
        case let .bclr(.r(register), address):
            return "bclr \(register), \(address)"
        case let .btst(.imm(bitNumber), address):
            return "btst #$\(String(bitNumber, radix: 16)), \(address)"
        case let .btst(.r(register), address):
            return "btst \(register), \(address)"
        case let .swap(register):
            return "swap \(register)"
        case let .rol(size, .r(countRegister), register):
            return "rol.\(size) \(countRegister), \(register)"
        case let .rol(size, .imm(count), register):
            return "rol.\(size) #$\(String(count, radix: 16)), \(register)"
        case let .ror(size, .r(countRegister), register):
            return "ror.\(size) \(countRegister), \(register)"
        case let .ror(size, .imm(count), register):
            return "ror.\(size) #$\(String(count, radix: 16)), \(register)"
        case let .rolm(address):
            return "rol \(address)"
        case let .rorm(address):
            return "ror \(address)"
        case let .roxl(size, .imm(count), register):
            return "roxl.\(size) #$\(String(count, radix: 16)), \(register)"
        case let .roxl(size, .r(countRegister), register):
            return "roxl.\(size) \(countRegister), \(register)"
        case let .roxr(size, .imm(count), register):
            return "roxr.\(size) #$\(String(count, radix: 16)), \(register)"
        case let .roxr(size, .r(countRegister), register):
            return "roxr.\(size) \(countRegister), \(register)"
        case let .roxlm(address):
            return "roxl \(address)"
        case let .roxrm(address):
            return "roxr \(address)"
        case let .mulu(address, register):
            return "mulu.w \(address), \(register)"
            
        case let .unknown(word):
            return "dc.w $\(String(word, radix: 16))"
        }
    }
}


public struct Instruction: CustomStringConvertible {
    let op: Operation
    public let address: UInt32
    public let data: Data
    
    public var description: String {
        return String(describing: op)
    }
    
    public var length: Int {
        data.count
    }
    
    public var isUnknown: Bool {
        if case .unknown(_) = op {
            return true
        } else {
            return false
        }
    }

    public var isEndOfFunction: Bool {
        op == .rts
    }
}

let ops = [
    OpInfo(name: .addb,     opClass: .add,      mask: 0xf0c0, value: 0xd000),
    OpInfo(name: .addw,     opClass: .add,      mask: 0xf0c0, value: 0xd040),
    OpInfo(name: .addl,     opClass: .add,      mask: 0xf0c0, value: 0xd080),
    
    OpInfo(name: .adda,     opClass: .adda,     mask: 0xf0c0, value: 0xd0c0),
    
    OpInfo(name: .addib,    opClass: .addi,     mask: 0xffc0, value: 0x0600),
    OpInfo(name: .addiw,    opClass: .addi,     mask: 0xffc0, value: 0x0640),
    OpInfo(name: .addil,    opClass: .addi,     mask: 0xffc0, value: 0x0680),
 
    OpInfo(name: .addqb,    opClass: .addq,     mask: 0xf1c0, value: 0x5000),
    OpInfo(name: .addqw,    opClass: .addq,     mask: 0xf1c0, value: 0x5040),
    OpInfo(name: .addql,    opClass: .addq,     mask: 0xf1c0, value: 0x5080),
    
    OpInfo(name: .andb,     opClass: .and,      mask: 0xf0c0, value: 0xc000),
    OpInfo(name: .andw,     opClass: .and,      mask: 0xf0c0, value: 0xc040),
    OpInfo(name: .andl,     opClass: .and,      mask: 0xf0c0, value: 0xc080),
    
    OpInfo(name: .andib,    opClass: .andi,     mask: 0xffc0, value: 0x0200),
    OpInfo(name: .andiw,    opClass: .andi,     mask: 0xffc0, value: 0x0240),
    OpInfo(name: .andil,    opClass: .andi,     mask: 0xffc0, value: 0x0280),
    
    OpInfo(name: .asrb,     opClass: .aslr,     mask: 0xf1d8, value: 0xe000),
    OpInfo(name: .asrw,     opClass: .aslr,     mask: 0xf1d8, value: 0xe040),
    OpInfo(name: .asrl,     opClass: .aslr,     mask: 0xf1d8, value: 0xe080),
    OpInfo(name: .asrm,     opClass: .aslrm,    mask: 0xffc0, value: 0xe0c0),

    OpInfo(name: .aslb,     opClass: .aslr,     mask: 0xf1d8, value: 0xe100),
    OpInfo(name: .aslw,     opClass: .aslr,     mask: 0xf1d8, value: 0xe140),
    OpInfo(name: .asll,     opClass: .aslr,     mask: 0xf1d8, value: 0xe180),
    OpInfo(name: .aslm,     opClass: .aslrm,    mask: 0xffc0, value: 0xe1c0),
    
    OpInfo(name: .bra,      opClass: .bra,      mask: 0xff00, value: 0x6000),
    OpInfo(name: .bcc,      opClass: .bcc,      mask: 0xf000, value: 0x6000),
    
    OpInfo(name: .bchgr,    opClass: .bchgr,    mask: 0xf1c0, value: 0x0140),
    OpInfo(name: .bchgi,    opClass: .bchgi,    mask: 0xffc0, value: 0x0840),

    OpInfo(name: .dbcc,     opClass: .dbcc,     mask: 0xf0f8, value: 0x50c8),
    
    // CLK omits bit 8 from the mask and the value. Not sure why.
    OpInfo(name: .eorb,     opClass: .eor,      mask: 0xf1c0, value: 0xb100),
    OpInfo(name: .eorw,     opClass: .eor,      mask: 0xf1c0, value: 0xb140),
    OpInfo(name: .eorl,     opClass: .eor,      mask: 0xf1c0, value: 0xb180),

    // NOTE: for now, Ext instructions have to be listed before MoveM. This
    // is because Ext can have the same value as MoveM, but a more specific
    // mask. This will remain necessary until we encode valid addressing modes
    // for each instruction.
    OpInfo(name: .extw,     opClass: .ext,      mask: 0xfff8, value: 0x4880),
    OpInfo(name: .extl,     opClass: .ext,      mask: 0xfff8, value: 0x48c0),
    OpInfo(name: .extbl,    opClass: .ext,      mask: 0xfff8, value: 0x49c0),

    OpInfo(name: .lea,      opClass: .lea,      mask: 0xf1c0, value: 0x41c0),
    
    // For now, movea must come before move.
    OpInfo(name: .moveaw,   opClass: .movea,    mask: 0xf1c0, value: 0x3040),
    OpInfo(name: .moveal,   opClass: .movea,    mask: 0xf1c0, value: 0x2040),

    OpInfo(name: .moveb,    opClass: .move,     mask: 0xf000, value: 0x1000),
    OpInfo(name: .movew,    opClass: .move,     mask: 0xf000, value: 0x3000),
    OpInfo(name: .movel,    opClass: .move,     mask: 0xf000, value: 0x2000),
    
    OpInfo(name: .movem,    opClass: .movem,    mask: 0xfb80, value: 0x4880),
    OpInfo(name: .moveq,    opClass: .moveq,    mask: 0xf100, value: 0x7000),
    OpInfo(name: .moveToSR, opClass: .moveToSR, mask: 0xffc0, value: 0x46c0),
    OpInfo(name: .moveFromSR, opClass: .moveFromSR, mask: 0xffc0, value: 0x40c0),
    
    OpInfo(name: .nop,      opClass: .nop,      mask: 0xffff, value: 0x4e71),
    
    OpInfo(name: .notb,     opClass: .not,      mask: 0xffc0, value: 0x4600),
    OpInfo(name: .notw,     opClass: .not,      mask: 0xffc0, value: 0x4640),
    OpInfo(name: .notl,     opClass: .not,      mask: 0xffc0, value: 0x4680),

    OpInfo(name: .rts,      opClass: .rts,      mask: 0xffff, value: 0x4e75),
    
    OpInfo(name: .scc,      opClass: .scc,      mask: 0xf0c0, value: 0x50c0),
    
    OpInfo(name: .subb,     opClass: .sub,      mask: 0xf0c0, value: 0x9000),
    OpInfo(name: .subw,     opClass: .sub,      mask: 0xf0c0, value: 0x9040),
    OpInfo(name: .subl,     opClass: .sub,      mask: 0xf0c0, value: 0x9080),

    OpInfo(name: .subaw,    opClass: .suba,     mask: 0xf1c0, value: 0x90c0),
    OpInfo(name: .subal,    opClass: .suba,     mask: 0xf1c0, value: 0x91c0),

    OpInfo(name: .subib,    opClass: .subi,     mask: 0xffc0, value: 0x0400),
    OpInfo(name: .subiw,    opClass: .subi,     mask: 0xffc0, value: 0x0440),
    OpInfo(name: .subil,    opClass: .subi,     mask: 0xffc0, value: 0x0480),
    
    OpInfo(name: .subqb,    opClass: .subq,     mask: 0xf1c0, value: 0x5100),
    OpInfo(name: .subqw,    opClass: .subq,     mask: 0xf1c0, value: 0x5140),
    OpInfo(name: .subql,    opClass: .subq,     mask: 0xf1c0, value: 0x5180),
    
    OpInfo(name: .cmpb,     opClass: .cmp,      mask: 0xf1c0, value: 0xb000),
    OpInfo(name: .cmpw,     opClass: .cmp,      mask: 0xf1c0, value: 0xb040),
    OpInfo(name: .cmpl,     opClass: .cmp,      mask: 0xf1c0, value: 0xb080),
    
    OpInfo(name: .cmpa,     opClass: .cmpa,     mask: 0xf0c0, value: 0xb0c0),
    
    OpInfo(name: .cmpib,    opClass: .cmpi,     mask: 0xffc0, value: 0x0c00),
    OpInfo(name: .cmpiw,    opClass: .cmpi,     mask: 0xffc0, value: 0x0c40),
    OpInfo(name: .cmpil,    opClass: .cmpi,     mask: 0xffc0, value: 0x0c80),
    
    OpInfo(name: .jmp,      opClass: .jmp,      mask: 0xffc0, value: 0x4ec0),
    OpInfo(name: .jsr,      opClass: .jsr,      mask: 0xffc0, value: 0x4e80),

    OpInfo(name: .tstb,     opClass: .tst,      mask: 0xffc0, value: 0x4a00),
    OpInfo(name: .tstw,     opClass: .tst,      mask: 0xffc0, value: 0x4a40),
    OpInfo(name: .tstl,     opClass: .tst,      mask: 0xffc0, value: 0x4a80),

    OpInfo(name: .orb,      opClass: .or,       mask: 0xf0c0, value: 0x8000),
    OpInfo(name: .orw,      opClass: .or,       mask: 0xf0c0, value: 0x8040),
    OpInfo(name: .orl,      opClass: .or,       mask: 0xf0c0, value: 0x8080),

    OpInfo(name: .oriToSR,  opClass: .oriToSR,  mask: 0xffff, value: 0x007c),
    
    OpInfo(name: .lsrb,     opClass: .lslr,     mask: 0xf1d8, value: 0xe008),
    OpInfo(name: .lsrw,     opClass: .lslr,     mask: 0xf1d8, value: 0xe048),
    OpInfo(name: .lsrl,     opClass: .lslr,     mask: 0xf1d8, value: 0xe088),
    OpInfo(name: .lsrm,     opClass: .lslrm,    mask: 0xffc0, value: 0xe2c0),

    OpInfo(name: .lslb,     opClass: .lslr,     mask: 0xf1d8, value: 0xe108),
    OpInfo(name: .lslw,     opClass: .lslr,     mask: 0xf1d8, value: 0xe148),
    OpInfo(name: .lsll,     opClass: .lslr,     mask: 0xf1d8, value: 0xe188),
    OpInfo(name: .lslm,     opClass: .lslrm,    mask: 0xffc0, value: 0xe3c0),

    OpInfo(name: .rorb,     opClass: .rolr,     mask: 0xf1d8, value: 0xe018),
    OpInfo(name: .rorw,     opClass: .rolr,     mask: 0xf1d8, value: 0xe058),
    OpInfo(name: .rorl,     opClass: .rolr,     mask: 0xf1d8, value: 0xe098),
    OpInfo(name: .rorm,     opClass: .rolrm,    mask: 0xffc0, value: 0xe6c0),
    
    OpInfo(name: .rolb,     opClass: .rolr,     mask: 0xf1d8, value: 0xe118),
    OpInfo(name: .rolw,     opClass: .rolr,     mask: 0xf1d8, value: 0xe158),
    OpInfo(name: .roll,     opClass: .rolr,     mask: 0xf1d8, value: 0xe198),
    OpInfo(name: .rolm,     opClass: .rolrm,    mask: 0xffc0, value: 0xe7c0),
    
    OpInfo(name: .roxrb,    opClass: .roxlr,    mask: 0xf1d8, value: 0xe010),
    OpInfo(name: .roxrw,    opClass: .roxlr,    mask: 0xf1d8, value: 0xe050),
    OpInfo(name: .roxrl,    opClass: .roxlr,    mask: 0xf1d8, value: 0xe090),
    OpInfo(name: .roxrm,    opClass: .roxlrm,   mask: 0xffc0, value: 0xe4c0),

    OpInfo(name: .roxlb,    opClass: .roxlr,    mask: 0xf1d8, value: 0xe110),
    OpInfo(name: .roxlw,    opClass: .roxlr,    mask: 0xf1d8, value: 0xe150),
    OpInfo(name: .roxll,    opClass: .roxlr,    mask: 0xf1d8, value: 0xe190),
    OpInfo(name: .roxlm,    opClass: .roxlrm,   mask: 0xffc0, value: 0xe5c0),

    OpInfo(name: .clrb,     opClass: .clr,      mask: 0xffc0, value: 0x4200),
    OpInfo(name: .clrw,     opClass: .clr,      mask: 0xffc0, value: 0x4240),
    OpInfo(name: .clrl,     opClass: .clr,      mask: 0xffc0, value: 0x4280),

    OpInfo(name: .bseti,    opClass: .bseti,    mask: 0xffc0, value: 0x08c0),
    OpInfo(name: .bsetr,    opClass: .bsetr,    mask: 0xf1c0, value: 0x01c0),

    OpInfo(name: .bclri,    opClass: .bclri,    mask: 0xffc0, value: 0x0880),
    OpInfo(name: .bclrr,    opClass: .bclrr,    mask: 0xf1c0, value: 0x0180),

    OpInfo(name: .btsti,    opClass: .btsti,    mask: 0xffc0, value: 0x0800),
    OpInfo(name: .btstr,    opClass: .btstr,    mask: 0xf1c0, value: 0x0100),
    
    OpInfo(name: .swap,     opClass: .swap,     mask: 0xfff8, value: 0x4840),
    
    OpInfo(name: .pea,      opClass: .pea,      mask: 0xffc0, value: 0x4840),
    
    OpInfo(name: .mulu,     opClass: .mulu,     mask: 0xf1c0, value: 0xc0c0),
//    OpInfo(name: "exg", mask: 0xf130, value: 0xc100)
]

class DisassemblyState {
    var address: UInt32
    var storage: InstructionStorage
    var skipSideEffectingReads: Bool
    
    init(address: UInt32, storage: InstructionStorage, skipSideEffectingReads: Bool) {
        self.address = address
        self.storage = storage
        self.skipSideEffectingReads = skipSideEffectingReads
    }
    
    func readWord() -> UInt16 {
        defer { address += 2 }
        
        if skipSideEffectingReads && !storage.canReadWithoutSideEffects(address) {
            return 0
        } else {
            return storage.read16(address)
        }
    }
    
    func readLong() -> UInt32 {
        defer { address += 4 }
        
        if skipSideEffectingReads && !storage.canReadWithoutSideEffects(address) {
            return 0
        } else {
            return storage.read32(address)
        }
    }
}

public struct Disassembler {
    var opTable: [OpClass]

    public init() {
        opTable = Array(repeating: .unknown, count: Int(UInt16.max) + 1)
        
        for i in 0...Int(UInt16.max) {
            for opInfo in ops {
                if UInt16(i) & opInfo.mask == opInfo.value {
                    opTable[i] = opInfo.opClass
                    break
                }
            }
        }
    }

    public func instruction(at address: UInt32, storage: InstructionStorage, returningZeroForSideEffectingReads: Bool = false) -> Instruction {
        let startAddress = address
        
        let state = DisassemblyState(address: address, storage: storage, skipSideEffectingReads: returningZeroForSideEffectingReads)
        
        let instructionWord = state.readWord()
        let opClass = opTable[Int(instructionWord)]
        
        let op: Operation

        switch opClass {
        case .unknown:
            op = .unknown(instructionWord)
        case .add:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let register = DataRegister(rawValue: Int(instructionWord >> 9) & 7) else {
                op = .unknown(instructionWord)
                break
            }
            
            let size0 = (instructionWord >> 6) & 3
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }


            let direction = (instructionWord >> 8) & 1

            if direction == 1 {
                guard let address = readMemoryAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                    op = .unknown(instructionWord)
                    break
                }
                
                op = .addRM(size, register, address)
            } else {
                guard let address = readAddress(state, eaMode, Int(eaReg), size: size) else {
                    op = .unknown(instructionWord)
                    break
                }

                op = .addMR(size, address, register)
            }
        case .adda:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            guard let register = AddressRegister(rawValue: Int((instructionWord >> 9) & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let opmode = (instructionWord >> 6) & 7
            let size: SizeWL
            if opmode == 0b11 {
                size = .w
            } else if opmode == 0b111 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readAddress(state, eaMode, Int(eaReg), size: Size(size)) else {
                op = .unknown(instructionWord)
                break
            }

            op = .adda(size, address, register)
        case .addi:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            let size0 = (instructionWord >> 6) & 3
            let size: Size
            let data: Int32

            if size0 == 0 {
                let w = state.readWord()

                size = .b
                data = Int32(Int8(truncatingIfNeeded: w))
            } else if size0 == 1 {
                let w = state.readWord()
                
                size = .w
                data = Int32(Int16(bitPattern: w))
            } else if size0 == 2 {
                let l = state.readLong()
                
                size = .l
                data = Int32(bitPattern: l)
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .addi(size, data, address)
        case .addq:
            var data = UInt8((instructionWord >> 9) & 7)
            if data == 0 {
                data = 8
            }
            
            let size0 = (instructionWord >> 6) & 3
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            guard let address = readAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .addq(size, data, address)
        case .and:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let register = DataRegister(rawValue: Int(instructionWord >> 9) & 7) else {
                op = .unknown(instructionWord)
                break
            }
            
            let size0 = (instructionWord >> 6) & 3
            let size: Size
            
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            

            let direction = (instructionWord >> 8) & 1
            
            if direction == 1 {
                guard let address = readMemoryAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                    op = .unknown(instructionWord)
                    break
                }
                
                op = .andRM(size, register, address)
            } else {
                guard let address = readDataAddress(state, eaMode, Int(eaReg), size: size) else {
                    op = .unknown(instructionWord)
                    break
                }

                op = .andMR(size, address, register)
            }
        case .andi:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            let size0 = (instructionWord >> 6) & 3
            let size: Size
            let data: Int32

            if size0 == 0 {
                let w = state.readWord()

                size = .b
                data = Int32(Int8(truncatingIfNeeded: w))
            } else if size0 == 1 {
                let w = state.readWord()
                
                size = .w
                data = Int32(Int16(bitPattern: w))
            } else if size0 == 2 {
                let l = state.readLong()

                size = .l
                data = Int32(bitPattern: l)
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .andi(size, data, address)
        case .aslr:
            let countOrRegister = (instructionWord >> 9) & 7
            let direction = (instructionWord >> 8) & 1
            let size0 = (instructionWord >> 6) & 3
            let immOrReg = (instructionWord >> 5) & 1
            
            guard let register = DataRegister(rawValue: Int(instructionWord & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let count: ShiftCount
            if immOrReg == 1 {
                guard let r = DataRegister(rawValue: Int(countOrRegister)) else {
                    op = .unknown(instructionWord)
                    break
                }
                count = .r(r)
            } else {
                count = .imm(UInt8(countOrRegister == 0 ? 8 : countOrRegister))
            }
            
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
                
            if (direction == 1) {
                op = .asl(size, count, register)
            } else {
                op = .asr(size, count, register)
            }
        case .aslrm:
            let direction = (instructionWord >> 8) & 1
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readMemoryAlterableAddress(state, eaMode, Int(eaReg), size: .w) else {
                op = .unknown(instructionWord)
                break
            }

            if (direction == 1) {
                op = .aslm(address)
            } else {
                op = .asrm(address)
            }
        case .bra:
            // TODO: '20, '30, and '40 support 32 bit displacement
            var displacement = Int16(Int8(bitPattern: UInt8(instructionWord & 0xFF)))
            var size = Size.b
            
            if displacement == 0 {
                let w = state.readWord()

                displacement = Int16(bitPattern: w)
                size = .w
            }
            
            op = .bra(size, startAddress+2, displacement)
        case .bcc:
            // TODO: '20, '30, and '40 support 32 bit displacement
            guard let condition = Condition(rawValue: Int((instructionWord >> 8) & 0xf)) else {
                op = .unknown(instructionWord)
                break
            }
            
            var displacement = Int16(Int8(bitPattern: UInt8(instructionWord & 0xFF)))
            var size = Size.b
            
            if displacement == 0 {
                let w = state.readWord()

                displacement = Int16(bitPattern: w)
                size = .w
            }

            op = .bcc(size, condition, startAddress+2, displacement)
        case .bchgr:
            let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7))!
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let size: Size
            if case .dd = eaMode {
                size = .l
            } else {
                size = .b
            }
            
            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .bchg(size, .r(register), address)
        case .bchgi:
            let w = state.readWord()
            
            let bitNumber = UInt8(truncatingIfNeeded: w)
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let size: Size
            if case .dd = eaMode {
                size = .l
            } else {
                size = .b
            }
            
            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .bchg(size, .imm(bitNumber), address)
        case .dbcc:
            guard let condition = Condition(rawValue: Int((instructionWord >> 8) & 0xf)),
                  let register = DataRegister(rawValue: Int(instructionWord & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let w = state.readWord()
            
            let displacement = Int16(bitPattern: w)
            
            op = .dbcc(condition, register, startAddress+2, displacement)
        case .eor:
            let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7))!
            let opmode = (instructionWord >> 6) & 7

            let size: Size
            if opmode == 0b100 {
                size = .b
            } else if opmode == 0b101 {
                size = .w
            } else if opmode == 0b110 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7

            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .eor(size, register, address)
        case .ext:
            let opmode = (instructionWord >> 6) & 7
            let register = DataRegister(rawValue: Int(instructionWord & 7))!
            
            if opmode == 0b010 {
                op = .ext(.w, register)
            } else if opmode == 0b011 {
                op = .ext(.l, register)
            } else if opmode == 0b111 {
                op = .extbl(register)
            } else {
                op = .unknown(instructionWord)
            }
        case .move:
            let size0 = (instructionWord >> 12) & 3
            
            var size: Size
            if size0 == 1 {
                size = .b
            } else if size0 == 3 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            let dstReg = (instructionWord >> 9) & 7
            let dstModeNum = (instructionWord >> 6) & 7
            guard let dstMode = AddressingMode.for(Int(dstModeNum), reg: Int(dstReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            
            let srcModeNum = (instructionWord >> 3) & 7
            let srcReg = instructionWord & 7
            guard let srcMode = AddressingMode.for(Int(srcModeNum), reg: Int(srcReg)) else {
                op = .unknown(instructionWord)
                break

            }
            
            guard let srcAddr = readAddress(state, srcMode, Int(srcReg), size: size),
                  let dstAddr = readDataAlterableAddress(state, dstMode, Int(dstReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .move(size, srcAddr, dstAddr)
        case .movea:
            let size0 = (instructionWord >> 12) & 3
            
            let size: SizeWL
            if size0 == 0b11 {
                size = .w
            } else if size0 == 0b10 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7

            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readAddress(state, eaMode, Int(eaReg), size: Size(size)) else {
                op = .unknown(instructionWord)
                break
            }

            let dstReg = AddressRegister(rawValue: Int((instructionWord >> 9) & 7))!

            op = .movea(size, address, dstReg)
        case .pea:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readControlAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            op = .pea(address)
        case .rts:
            op = .rts
        case .lea:
            guard let dstReg = AddressRegister(rawValue: Int((instructionWord >> 9) & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let srcModeNum = (instructionWord >> 3) & 7
            let srcReg = instructionWord & 7
            guard let srcMode = AddressingMode.for(Int(srcModeNum), reg: Int(srcReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let srcAddr = readControlAddress(state, srcMode, Int(srcReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .lea(srcAddr, dstReg)
        case .scc:
            guard let condition = Condition(rawValue: Int((instructionWord >> 8) & 0xf)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: .b) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .scc(condition, address)
        case .sub:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let register = DataRegister(rawValue: Int(instructionWord >> 9) & 7) else {
                op = .unknown(instructionWord)
                break
            }
            
            let size0 = (instructionWord >> 6) & 3
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }

            let direction = (instructionWord >> 8) & 1
            
            if direction == 1 {
                guard let address = readMemoryAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                    op = .unknown(instructionWord)
                    break
                }

                op = .subRM(size, register, address)
            } else {
                guard let address = readAddress(state, eaMode, Int(eaReg), size: size) else {
                    op = .unknown(instructionWord)
                    break
                }
                
                op = .subMR(size, address, register)
            }
        case .suba:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)),
                  let register = AddressRegister(rawValue: Int((instructionWord >> 9) & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let opmode = (instructionWord >> 6) & 7
            let size: SizeWL
            if opmode == 7 {
                size = .l
            } else if opmode == 3 {
                size = .w
            } else {
                op = .unknown(instructionWord)
                break
            }

            guard let address = readAddress(state, eaMode, Int(eaReg), size: Size(size)) else {
                op = .unknown(instructionWord)
                break
            }

            op = .suba(size, address, register)
        case .subi:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            let size0 = (instructionWord >> 6) & 3
            let size: Size
            let data: Int32

            if size0 == 0 {
                let w = state.readWord()

                size = .b
                data = Int32(Int8(truncatingIfNeeded: w))
            } else if size0 == 1 {
                let w = state.readWord()

                size = .w
                data = Int32(Int16(bitPattern: w))
            } else if size0 == 2 {
                let l = state.readLong()
                
                size = .l
                data = Int32(bitPattern: l)
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            op = .subi(size, data, address)
        case .subq:
            var data = UInt8((instructionWord >> 9) & 7)
            if data == 0 {
                data = 8
            }
            
            let size0 = (instructionWord >> 6) & 3
            
            var size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }

            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            op = .subq(size, data, address)
        case .movem:
            let direction = (instructionWord >> 10) & 1
            let size0 = (instructionWord >> 6) & 1
            let size = size0 == 1 ? SizeWL.l : SizeWL.w
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let registers0 = state.readWord()
            
            if direction == 1 {
                guard let address = readControlAlterableOrPostIncrementAddress(state, eaMode, Int(eaReg), size: Size(size)) else {
                    op = .unknown(instructionWord)
                    break
                }

                let registers = RegisterList(rawValue: registers0)

                op = .movemMR(size, address, registers)
            } else {
                guard let address = readControlAlterableOrPreDecrementAddress(state, eaMode, Int(eaReg), size: Size(size)) else {
                    op = .unknown(instructionWord)
                    break
                }

                let registers: RegisterList
                if case .preDec(_) = address {
                    registers = RegisterList(rawValue: registers0.bitSwapped)
                } else {
                    registers = RegisterList(rawValue: registers0)
                }

                op = .movemRM(size, registers, address)
            }
        case .cmp:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let opmode = (instructionWord >> 6) & 7
            
            let size: Size
            if opmode == 0 {
                size = .b
            } else if opmode == 1 {
                size = .w
            } else if opmode == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }

            guard let address = readAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            op = .cmp(size, address, register)
        case .cmpa:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let register = AddressRegister(rawValue: Int((instructionWord >> 9) & 7))!
            
            let size = (instructionWord >> 8) & 1 == 0 ? Size.w : Size.l
            
            guard let address = readAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            op = .cmpa(size, address, register)
        case .cmpi:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let size0 = (instructionWord >> 6) & 3
            let size: Size
            let data: Int32
            if size0 == 0 {
                let w = state.readWord()
                
                size = .b
                data = Int32(Int8(truncatingIfNeeded: w))
            } else if size0 == 1 {
                let w = state.readWord()
                
                size = .w
                data = Int32(Int16(bitPattern: w))
            } else if size0 == 2 {
                let l = state.readLong()

                size = .l
                data = Int32(bitPattern: l)
            } else {
                op = .unknown(instructionWord)
                break
            }

            guard let address = readDataAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .cmpi(size, data, address)
        case .jmp:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            guard let address = readControlAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            op = .jmp(address)
        case .jsr:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            guard let address = readAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            op = .jsr(address)
        case .moveToSR:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            guard let address = readDataAddress(state, eaMode, Int(eaReg), size: .w) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .moveToSR(address)
        case .moveFromSR:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: .w) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .moveFromSR(address)
        case .moveq:
            let data = Int8(truncatingIfNeeded: instructionWord)
            guard let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .moveq(data, register)
        case .nop:
            op = .nop
        case .not:
            let size0 = (instructionWord >> 6) & 3
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .not(size, address)
        case .tst:
            let size0 = (instructionWord >> 6) & 3
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            guard let address = readAddress(state, eaMode, Int(eaReg), size: .w) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .tst(size, address)
        case .or:
            let register = DataRegister(rawValue: Int(instructionWord >> 9) & 7)!

            let size0 = (instructionWord >> 6) & 3
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }

            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            let direction0 = (instructionWord >> 8) & 1
            let direction: Direction = direction0 == 1 ? .rToM : .mToR
            
            op = .or(size, direction, address, register)
        case .oriToSR:
            let w = state.readWord()
            
            op = .oriToSR(Int16(bitPattern: w))
        case .lslr:
            let countOrRegister = (instructionWord >> 9) & 7
            let direction = (instructionWord >> 8) & 1
            let size0 = (instructionWord >> 6) & 3
            let immOrReg = (instructionWord >> 5) & 1
            
            guard let register = DataRegister(rawValue: Int(instructionWord & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let count: ShiftCount
            if immOrReg == 1 {
                guard let r = DataRegister(rawValue: Int(countOrRegister)) else {
                    op = .unknown(instructionWord)
                    break
                }
                count = .r(r)
            } else {
                count = .imm(UInt8(countOrRegister == 0 ? 8 : countOrRegister))
            }
            
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
                
            if (direction == 1) {
                op = .lsl(size, count, register)
            } else {
                op = .lsr(size, count, register)
            }
        case .lslrm:
            let direction = (instructionWord >> 8) & 1
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            if (direction == 1) {
                op = .lslm(address)
            } else {
                op = .lsrm(address)
            }
        case .clr:
            let size0 = (instructionWord >> 6) & 3
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .clr(size, address)
        case .bseti:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let w = state.readWord()
            
            let bitNumber = UInt8(truncatingIfNeeded: w)
            
            let size: Size
            switch eaMode {
            case .dd: size = .l
            default:  size = .b
            }
            
            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .bset(.imm(bitNumber), address)
        case .bsetr:
            guard let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7)) else {
                op = .unknown(instructionWord)
                break
            }

            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let size: Size
            switch eaMode {
            case .dd: size = .l
            default:  size = .b
            }
            
            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .bset(.r(register), address)
        case .bclri:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let w = state.readWord()
            
            let bitNumber = UInt8(truncatingIfNeeded: w)
            
            let size: Size
            if eaMode == .dd {
                size = .l
            } else {
                size = .b
            }
            
            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .bclr(.imm(bitNumber), address)
        case .bclrr:
            guard let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7)) else {
                op = .unknown(instructionWord)
                break
            }

            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let size: Size
            if eaMode == .dd {
                size = .l
            } else {
                size = .b
            }
            
            guard let address = readDataAlterableAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .bclr(.r(register), address)
        case .btsti:
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let w = state.readWord()
            
            let bitNumber = UInt8(truncatingIfNeeded: w)
            
            let size: Size
            if eaMode == .dd {
                size = .l
            } else {
                size = .b
            }
            
            guard let address = readDataAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }

            op = .btst(.imm(bitNumber), address)
        case .btstr:
            guard let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7)) else {
                op = .unknown(instructionWord)
                break
            }

            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let size: Size
            if eaMode == .dd {
                size = .l
            } else {
                size = .b
            }
            
            guard let address = readDataAddress(state, eaMode, Int(eaReg), size: size) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .btst(.r(register), address)
        case .swap:
            guard let register = DataRegister(rawValue: Int(instructionWord & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            op = .swap(register)
        case .rolr:
            let countOrRegister = (instructionWord >> 9) & 7
            let direction = (instructionWord >> 8) & 1
            let size0 = (instructionWord >> 6) & 3
            let immOrReg = (instructionWord >> 5) & 1
            guard let register = DataRegister(rawValue: Int(instructionWord & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let count: RotateCount
            if immOrReg == 1 {
                guard let r = DataRegister(rawValue: Int(countOrRegister)) else {
                    op = .unknown(instructionWord)
                    break
                }
                count = .r(r)
            } else {
                count = .imm(UInt8(countOrRegister == 0 ? 8 : countOrRegister))
            }
            
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            if (direction == 1) {
                op = .rol(size, count, register)
            } else {
                op = .ror(size, count, register)
            }
        case .rolrm:
            let direction = (instructionWord >> 8) & 1
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            if (direction == 1) {
                op = .rolm(address)
            } else {
                op = .rorm(address)
            }
        case .mulu:
            guard let register = DataRegister(rawValue: Int((instructionWord >> 9) & 7)) else {
                op = .unknown(instructionWord)
                break
            }

            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readAddress(state, eaMode, Int(eaReg), size: .w) else {
                op = .unknown(instructionWord)
                break
            }

            op = .mulu(address, register)
        case .roxlr:
            let countOrRegister = (instructionWord >> 9) & 7
            let direction = (instructionWord >> 8) & 1
            let size0 = (instructionWord >> 6) & 3
            let immOrReg = (instructionWord >> 5) & 1
            guard let register = DataRegister(rawValue: Int(instructionWord & 7)) else {
                op = .unknown(instructionWord)
                break
            }
            
            let count: RotateCount
            if immOrReg == 1 {
                guard let r = DataRegister(rawValue: Int(countOrRegister)) else {
                    op = .unknown(instructionWord)
                    break
                }
                count = .r(r)
            } else {
                count = .imm(UInt8(countOrRegister == 0 ? 8 : countOrRegister))
            }
            
            let size: Size
            if size0 == 0 {
                size = .b
            } else if size0 == 1 {
                size = .w
            } else if size0 == 2 {
                size = .l
            } else {
                op = .unknown(instructionWord)
                break
            }
            
            if (direction == 1) {
                op = .roxl(size, count, register)
            } else {
                op = .roxr(size, count, register)
            }
        case .roxlrm:
            let direction = (instructionWord >> 8) & 1
            
            let eaModeNum = (instructionWord >> 3) & 7
            let eaReg = instructionWord & 7
            
            guard let eaMode = AddressingMode.for(Int(eaModeNum), reg: Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }
            
            guard let address = readAddress(state, eaMode, Int(eaReg)) else {
                op = .unknown(instructionWord)
                break
            }

            if (direction == 1) {
                op = .roxlm(address)
            } else {
                op = .roxrm(address)
            }
        }
        
        return Instruction(op: op, address: startAddress, data: storage.readRange(startAddress..<state.address))
    }

    func readAddress(_ state: DisassemblyState, _ mode: AddressingMode, _ reg: Int, size: Size? = nil) -> EffectiveAddress? {
        switch mode {
        case .dd: return .dd(DataRegister(rawValue: reg)!)
        case .ad: return .ad(AddressRegister(rawValue: reg)!)
        case .ind: return .m(.ind(AddressRegister(rawValue: reg)!))
        case .postInc: return .m(.postInc(AddressRegister(rawValue: reg)!))
        case .preDec: return .m(.preDec(AddressRegister(rawValue: reg)!))
        case .d16An:
            let w = state.readWord()
            
            let val = Int16(bitPattern: w)
            
            return .m(.d16An(val, AddressRegister(rawValue: reg)!))
        case .d8AnXn:
            guard let ex = readExtensionWord(state) else { return nil }
            let register = AddressRegister(rawValue: reg)!
            
            return .m(.d8AnXn(ex.displacement, register, ex.indexRegister, ex.indexSize))
        case .XXXw:
            let w = state.readWord()

            let val = UInt32(truncatingIfNeeded: Int16(bitPattern: w))
            
            return .m(.XXXw(val))
        case .XXXl:
            let val = state.readLong()
            
            return .m(.XXXl(val))
        case .d16PC:
            let exAddress = state.address
            let ex = state.readWord()
            return .m(.d16PC(exAddress, Int16(bitPattern: ex)))
        case .d8PCXn:
            let exAddress = state.address
            guard let ex = readExtensionWord(state) else { return nil }
            
            return .m(.d8PCXn(exAddress, ex.displacement, ex.indexRegister, ex.indexSize))
        case .imm:
            guard let size = size else { return nil }
            
            switch size {
            case .b:
                let w = state.readWord()
                return .imm(Int32(Int8(truncatingIfNeeded: w)))
            case .w:
                let w = state.readWord()
                return .imm(Int32(Int16(bitPattern: w)))
            case .l:
                let l = state.readLong()
                return .imm(Int32(bitPattern: l))
            }
        }
    }
    
    func readMemoryAlterableAddress(_ state: DisassemblyState, _ mode: AddressingMode, _ reg: Int, size: Size) -> MemoryAlterableAddress? {
        switch readAddress(state, mode, reg, size: size) {
        case let .m(.ind(An)):                 return .ind(An)
        case let .m(.postInc(An)):             return .postInc(An)
        case let .m(.preDec(An)):              return .preDec(An)
        case let .m(.d16An(d, An)):            return .d16An(d, An)
        case let .m(.d8AnXn(d, An, Xn, size)): return .d8AnXn(d, An, Xn, size)
        case let .m(.XXXw(address)):           return .XXXw(address)
        case let .m(.XXXl(address)):           return .XXXl(address)
        default:                               return nil
        }
    }
    
    func readDataAddress(_ state: DisassemblyState, _ mode: AddressingMode, _ reg: Int, size: Size) -> DataAddress? {
        switch readAddress(state, mode, reg, size: size) {
        case let .dd(Dn):                      return .dd(Dn)
        case let .m(.ind(An)):                 return .m(.ind(An))
        case let .m(.postInc(An)):             return .m(.postInc(An))
        case let .m(.preDec(An)):              return .m(.preDec(An))
        case let .m(.d16An(d, An)):            return .m(.d16An(d, An))
        case let .m(.d8AnXn(d, An, Xn, size)): return .m(.d8AnXn(d, An, Xn, size))
        case let .m(.XXXw(address)):           return .m(.XXXw(address))
        case let .m(.XXXl(address)):           return .m(.XXXl(address))
        case let .m(.d16PC(pc, d)):            return .m(.d16PC(pc, d))
        case let .m(.d8PCXn(pc, d, Xn, size)): return .m(.d8PCXn(pc, d, Xn, size))
        case let .imm(value):                  return .imm(value)
        default:                               return nil
        }
    }

    func readDataAlterableAddress(_ state: DisassemblyState, _ mode: AddressingMode, _ reg: Int, size: Size) -> DataAlterableAddress? {
        switch readAddress(state, mode, reg, size: size) {
        case let .dd(Dn):                      return .dd(Dn)
        case let .m(.ind(An)):                 return .m(.ind(An))
        case let .m(.postInc(An)):             return .m(.postInc(An))
        case let .m(.preDec(An)):              return .m(.preDec(An))
        case let .m(.d16An(d, An)):            return .m(.d16An(d, An))
        case let .m(.d8AnXn(d, An, Xn, size)): return .m(.d8AnXn(d, An, Xn, size))
        case let .m(.XXXw(address)):           return .m(.XXXw(address))
        case let .m(.XXXl(address)):           return .m(.XXXl(address))
        default:                               return nil
        }
    }
    
    func readAlterableAddress(_ state: DisassemblyState, _ mode: AddressingMode, _ reg: Int, size: Size) -> AlterableAddress? {
        switch readAddress(state, mode, reg, size: size) {
        case let .dd(Dn):                      return .dd(Dn)
        case let .ad(An):                      return .ad(An)
        case let .m(.ind(An)):                 return .m(.ind(An))
        case let .m(.postInc(An)):             return .m(.postInc(An))
        case let .m(.preDec(An)):              return .m(.preDec(An))
        case let .m(.d16An(d, An)):            return .m(.d16An(d, An))
        case let .m(.d8AnXn(d, An, Xn, size)): return .m(.d8AnXn(d, An, Xn, size))
        case let .m(.XXXw(address)):           return .m(.XXXw(address))
        case let .m(.XXXl(address)):           return .m(.XXXl(address))
        default:                               return nil
        }
    }

    func readControlAddress(_ state: DisassemblyState, _ mode: AddressingMode, _ reg: Int) -> ControlAddress? {
        switch readAddress(state, mode, reg) {
        case let .m(.ind(An)):                 return .ind(An)
        case let .m(.d16An(d, An)):            return .d16An(d, An)
        case let .m(.d8AnXn(d, An, Xn, size)): return .d8AnXn(d, An, Xn, size)
        case let .m(.XXXw(address)):           return .XXXw(address)
        case let .m(.XXXl(address)):           return .XXXl(address)
        case let .m(.d16PC(pc, d)):            return .d16PC(pc, d)
        case let .m(.d8PCXn(pc, d, Xn, size)): return .d8PCXn(pc, d, Xn, size)
        default:                               return nil
        }
    }

    func readControlAlterableOrPreDecrementAddress(_ state: DisassemblyState, _ mode: AddressingMode, _ reg: Int, size: Size) -> ControlAlterableOrPreDecrementAddress? {
        switch readAddress(state, mode, reg, size: size) {
        case let .m(.ind(An)):                 return .ind(An)
        case let .m(.preDec(An)):              return .preDec(An)
        case let .m(.d16An(d, An)):            return .d16An(d, An)
        case let .m(.d8AnXn(d, An, Xn, size)): return .d8AnXn(d, An, Xn, size)
        case let .m(.XXXw(address)):           return .XXXw(address)
        case let .m(.XXXl(address)):           return .XXXl(address)
        default:                               return nil
        }
    }
    
    func readControlAlterableOrPostIncrementAddress(_ state: DisassemblyState, _ mode: AddressingMode, _ reg: Int, size: Size) -> ControlAlterableOrPostIncrementAddress? {
        switch readAddress(state, mode, reg, size: size) {
        case let .m(.ind(An)):                 return .ind(An)
        case let .m(.postInc(An)):             return .postInc(An)
        case let .m(.d16An(d, An)):            return .d16An(d, An)
        case let .m(.d8AnXn(d, An, Xn, size)): return .d8AnXn(d, An, Xn, size)
        case let .m(.XXXw(address)):           return .XXXw(address)
        case let .m(.XXXl(address)):           return .XXXl(address)
        default:                               return nil
        }
    }


    func readExtensionWord(_ state: DisassemblyState) -> ExtensionWord? {
        let w = state.readWord()
        
        if (w & 0x100) == 0x100 {
            // TODO: full extension words are not yet supported
            return nil
        }
        
        let displacement = Int8(truncatingIfNeeded: w)
        
        let isAddressRegister = ((w >> 15) & 1) == 1
        let regNum = (w >> 12) & 7
        
        let indexRegister: Register
        if isAddressRegister {
            indexRegister = .a(AddressRegister(rawValue: Int(regNum))!)
        } else {
            indexRegister = .d(DataRegister(rawValue: Int(regNum))!)
        }
        
        let size: Size
        if ((w >> 11) & 1) == 1 {
            size = .l
        } else {
            size = .w
        }
        
        return ExtensionWord(indexRegister: indexRegister, indexSize: size, displacement: displacement)
    }
}
