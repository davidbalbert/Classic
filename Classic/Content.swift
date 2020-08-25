//
//  Content.swift
//  Classic
//
//  Created by David Albert on 5/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import Cocoa
import M68K

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

extension Disassembler {
    func disassembleUntilEndOfFunction(at address: UInt32, storage: InstructionStorage) -> [Instruction] {
        var insns: [Instruction] = []
        
        var address = address

        while storage.canReadWithoutSideEffects(address) {
            let insn = instruction(at: address, storage: storage, returningZeroForSideEffectingReads: true)
            
            insns.append(insn)
            address += UInt32(insn.length)
            
            if insn.isEndOfFunction {
                break
            }
        }

        return insns
    }
}

class Content: NSObject {
    var machine: MacPlus?
    
    lazy var instructions: [Instruction] = {
        guard let machine = machine else {
            return []
        }
        
        let cpu = machine.cpu
        let disassembler = cpu.disassembler
        
        return disassembler.disassembleUntilEndOfFunction(at: cpu.pc, storage: machine)
    }()
    
    var attributedAssembly: NSAttributedString {
        let res = NSMutableAttributedString()
                    
        for (i, insn) in instructions.enumerated() {
            var attributes: [NSAttributedString.Key : Any] = [.foregroundColor: NSColor.textColor]
            
            var s = insn.data.hexDump().padding(toLength: 26, withPad: " ", startingAt: 0)
            
            if insn.isUnknown, let atrap = ATrap(data: insn.data) {
                s += String(describing: atrap)
            } else if insn.isUnknown {
                s += String(describing: insn)
                attributes[.backgroundColor] = NSColor.red
            } else if !(machine?.cpu.implements(insn) ?? true) {
                s += String(describing: insn)
                attributes[.backgroundColor] = NSColor.yellow
            } else {
                s += String(describing: insn)
            }
            
            res.append(NSAttributedString(string: s, attributes: attributes))
            
            if i < instructions.count-1 {
                res.append(NSAttributedString(string: "\n", attributes: attributes))
            }
        }
        
        return res
    }
    
    // lineno is 1 indexed
    func address(for lineno: Int) -> UInt32? {
        let i = lineno-1
        
        if i >= instructions.count {
            return nil
        } else {
            return instructions[i].address
        }
    }
    
    func read(from data: Data) {
        machine = MacPlus(rom: data)
    }
}
