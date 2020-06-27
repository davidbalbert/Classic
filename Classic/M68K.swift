//
//  M68K.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Foundation

extension Data {
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

enum OpName: String {
    case bra
}


struct OpInfo {
    let name: OpName
    let mask: UInt16
    let value: UInt16
}

enum Operation {
    case bra(UInt32, UInt16)
}

extension Operation : CustomStringConvertible {
    var description: String {
        switch self {
        case let .bra(address, displacement):
            return "bra\t$\(String(address + 2 + UInt32(displacement), radix: 16))"
        }
    }
}

struct Instruction: CustomStringConvertible {
    let op: Operation
    let address: UInt32
    let data: Data
    
    var description: String {
        "\(data.hexDump())\t\(op)"
    }
}

let ops = [
    OpInfo(name: .bra, mask: 0xff00, value: 0x6000),
//    OpInfo(name: "exg", mask: 0xf130, value: 0xc100)
]

let opTable: [OpName?] = Array(repeating: nil, count: Int(UInt16.max))

struct Disassembler {
    var opTable: [OpName?]
    let data: Data
    var offset: Data.Index
    
    init(_ data: Data) {
        self.data = data
        offset = data.startIndex
        opTable = Array(repeating: nil, count: Int(UInt16.max))
        
        for i in 0...Int(UInt16.max) {
            for opInfo in ops {
                if UInt16(i) & opInfo.mask == opInfo.value {
                    opTable[i] = opInfo.name
                }
            }
        }
    }
    
    mutating func disassemble(loadAddress: UInt32) -> [Instruction] {
        var insns: [Instruction] = []
        
        while offset < data.endIndex {
            let startOffset = offset
            let instructionWord = readWord()
            
            guard let opName = opTable[Int(instructionWord)] else {
                return insns
            }
            
            switch opName {
            case .bra:
                // TODO: '20, '30, and '40 support 32 bit displacement
                var displacement = instructionWord & 0xFF

                if displacement == 0 {
                    displacement = readWord()
                }
                
                let op = Operation.bra(loadAddress+UInt32(startOffset), displacement)
                
                insns.append(Instruction(op: op, address: loadAddress+UInt32(startOffset), data: data[startOffset..<offset]))
            }
        }
        
        return insns
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
