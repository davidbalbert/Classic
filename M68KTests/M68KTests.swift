//
//  M68KTests.swift
//  M68KTests
//
//  Created by David Albert on 6/29/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class M68KTests: XCTestCase {
    var d = Disassembler()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAdd() throws {
        let data = Data([0xd0, 0x42])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.add(.w, .mToR, .dd(.d2), .d0))
    }
    
    func testAddAWord() throws {
        let data = Data([0xd4, 0xc1])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.adda(.w, .dd(.d1), .a2))
    }
    
    func testAddALong() throws {
        let data = Data([0xd5, 0xc1])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.adda(.l, .dd(.d1), .a2))
    }
    
    func testAddiByte() throws {
        let data = Data([0x06, 0x38, 0x00, 0x15, 0x01, 0x0c])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.addi(.b, 0x15, .XXXw(0x10c)))
    }
    
    func testAddiWord() throws {
        let data = Data([0x06, 0x78, 0x04, 0x00, 0x01, 0x0c])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.addi(.w, 0x400, .XXXw(0x10c)))
    }
    
    func testAddiLong() throws {
        let data = Data([0x06, 0xb8, 0x00, 0x00, 0x04, 0x00, 0x01, 0x0c])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.addi(.l, 0x400, .XXXw(0x10c)))
    }

    func testAddQByte() throws {
        let data = Data([0x52, 0x00])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.addq(.b, 1, .dd(.d0)))
    }
    
    func testAddQWord() throws {
        let data = Data([0x52, 0x40])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.addq(.w, 1, .dd(.d0)))
    }
    
    func testAddQLong() throws {
        let data = Data([0x52, 0x80])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.addq(.l, 1, .dd(.d0)))
    }
    
    func testAnd() throws {
        let data = Data([0xc0, 0x47])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.and(.w, .mToR, .dd(.d7), .d0))
    }
    
    func testAndi() throws {
        let data = Data([0x02, 0x02, 0x00, 0x6b])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.andi(.b, 0x6b, .dd(.d2)))
    }

    func testBra() throws {
        var data = Data([0x60, 0x02])
        var op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bra(.b, 2, 0x2))
        
        data = Data([0x60, 0x00, 0x00, 0x16])
        op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bra(.w, 2, 0x16))
        
        data = Data([0x60, 0xee])
        op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bra(.b, 2, -18))
    }
    
    func testBne() throws {
        var data = Data([0x66, 0x00, 0x00, 0xfc])
        var op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bcc(.w, .ne, 2, 0xfc))
        
        data = Data([0x66, 0xee])
        op = d.disassemble(data, loadAddress: 0x40)[0].op
        
        XCTAssertEqual(op, Operation.bcc(.b, .ne, 0x42, -18))
    }
    
    func testDbf() throws {
        let data = Data([0x51, 0xcb, 0xff, 0xe6])
        let op = d.disassemble(data, loadAddress: 0x196)[0].op
        
        XCTAssertEqual(op, Operation.dbcc(.f, .d3, 0x198, -26))
    }

    
    func testMove() throws {
        var data = Data([0x10, 0x80])
        var op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.move(.b, .dd(.d0), .ind(.a0)))
        
        data = Data([0x20, 0x0f])
        op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.move(.l, .ad(.a7), .dd(.d0)))

        data = Data([0x1b, 0x7c, 0x00, 0x87, 0x04, 0x00])
        op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.move(.b, .imm(.b(-0x79)), .d16An(0x400, .a5)))
    }
    
    func testNotByte() throws {
        let data = Data([0x46, 0x18])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.not(.b, .postInc(.a0)))
    }
    
    func testNotWord() throws {
        let data = Data([0x46, 0x58])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.not(.w, .postInc(.a0)))
    }
    
    func testNotLong() throws {
        let data = Data([0x46, 0x98])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.not(.l, .postInc(.a0)))
    }
    
    func testEorb() throws {
        let data = Data([0xb3, 0x10])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.eor(.b, .d1, .ind(.a0)))
    }
    
    func testEorw() throws {
        let data = Data([0xb3, 0x50])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.eor(.w, .d1, .ind(.a0)))
    }

    func testEorl() throws {
        let data = Data([0xb3, 0x90])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.eor(.l, .d1, .ind(.a0)))
    }
    
    func testExtw() throws {
        let data = Data([0x48, 0x81])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.ext(.w, .d1))
    }
        
    func testExtl() throws {
        let data = Data([0x48, 0xc1])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.ext(.l, .d1))
    }
    
    func testExtbl() throws {
        let data = Data([0x49, 0xc1])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.extbl(.d1))
    }
    
    func testMoveQ() throws {
        let data = Data([0x7e, 0x01])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.moveq(1, .d7))

    }
    
    func testMoveM() throws {
        let data = Data([0x4c, 0xf9, 0x01, 0x01, 0x00, 0xf8, 0x00, 0x00])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.movem(.l, .mToR, .XXXl(0xf80000), [.d0, .a0]))
    }
    
    func testLea() throws {
        let data = Data([0x4d, 0xfa, 0x00, 0x06])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.lea(.d16PC(2, 0x6), .a6))
    }
    
    func testScc() throws {
        let template: UInt16 = 0b0101_0000_1100_0000
        
        for c in Condition.allCases {
            let value = template | UInt16(c.rawValue << 8)
            let data = Data([UInt8(value >> 8), UInt8(value & 0xff)])
            let op = d.disassemble(data, loadAddress: 0)[0].op
            
            XCTAssertEqual(op, Operation.scc(c, .dd(.d0)))
        }
    }
    
    func testSubByte() throws {
        let data = Data([0x90, 0x0b])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.sub(.b, .mToR, .ad(.a3), .d0))
    }
    
    func testSubWord() throws {
        let data = Data([0x90, 0x4b])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.sub(.w, .mToR, .ad(.a3), .d0))
    }
    
    func testSubLong() throws {
        let data = Data([0x90, 0x8b])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.sub(.l, .mToR, .ad(.a3), .d0))
    }
    
    func testSubRToM() throws {
        let data = Data([0x91, 0x8b])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.sub(.l, .rToM, .ad(.a3), .d0))
    }
    
    func testSuba() throws {
        let data = Data([0x97, 0xcb])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.suba(.l, .ad(.a3), .a3))
    }

    func testSubiByte() throws {
        let data = Data([0x04, 0x38, 0x00, 0x12, 0x01, 0x0c])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.subi(.b, 0x12, .XXXw(0x10c)))
    }
    
    func testSubiWord() throws {
        let data = Data([0x04, 0x78, 0x04, 0x00, 0x01, 0x0c])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.subi(.w, 0x400, .XXXw(0x10c)))
    }
    
    func testSubiLong() throws {
        let data = Data([0x04, 0xb8, 0x00, 0x00, 0x04, 0x00, 0x01, 0x0c])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.subi(.l, 0x400, .XXXw(0x10c)))
    }
    
    func testSubq() throws {
        let data = Data([0x53, 0x8f])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.subq(.l, 1, .ad(.a7)))
    }
    
    func testCmpaWord() throws {
        let data = Data([0xb0, 0xc9])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.cmpa(.w, .ad(.a1), .a0))
    }
    
    func testCmpaLong() throws {
        let data = Data([0xb1, 0xc9])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.cmpa(.l, .ad(.a1), .a0))
    }
    
    func testCmpi() throws {
        let data = Data([0x0c, 0x80, 0x55, 0xaa, 0xaa, 0x55])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.cmpi(.l, 0x55aaaa55, .dd(.d0)))
    }
    
    func testJmp() throws {
        let data = Data([0x4e, 0xd0])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.jmp(.ind(.a0)))
    }
    
    func testJsr() throws {
        let data = Data([0x4e, 0xba, 0x16, 0x00])
        let op = d.disassemble(data, loadAddress: 0x436)[0].op
        
        XCTAssertEqual(op, Operation.jsr(.d16PC(0x438, 0x1600)))
    }
    
    func testMoveToSR() throws {
        let data = Data([0x46, 0xfc, 0x27, 0x00])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.moveToSR(.imm(.w(0x2700))))
    }
    
    func testMoveFromSR() throws {
        let data = Data([0x40, 0xc5])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.moveFromSR(.dd(.d5)))
    }
    
    func testTst() throws {
        let data = Data([0x4a, 0x1e])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.tst(.b, .postInc(.a6)))
    }
    
    func testOr() throws {
        let data = Data([0x84, 0x04])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.or(.b, .mToR, .dd(.d4), .d2))
    }
    
    func testOriToSR() throws {
        let data = Data([0x00, 0x7c, 0x03, 0x00])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.oriToSR(0x300))
    }
    
    func testArithmeticShiftImmediate() throws {
        var data = Data([0xe4, 0x42])
        var op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.asr(.w, .imm(2), .d2))
        
        data = Data([0xe0, 0x42])
        op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.asr(.w, .imm(8), .d2))
    }
    
    func testArithmeticShiftRegister() throws {
        let data = Data([0xe0, 0x62])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.asr(.w, .r(.d0), .d2))
    }
    
    func testArithmeticShiftLeft() throws {
        let data = Data([0xe1, 0x62])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.asl(.w, .r(.d0), .d2))
    }
    
    func testArithmeticShiftByte() throws {
        let data = Data([0xe1, 0x22])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.asl(.b, .r(.d0), .d2))
    }

    func testArithmeticShiftLong() throws {
        let data = Data([0xe1, 0xa2])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.asl(.l, .r(.d0), .d2))
    }
    
    func testArithmeticShiftRightMemory() throws {
        let data = Data([0xe0, 0xc2])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.asrm(.dd(.d2)))
    }
    
    func testArithmeticShiftLeftMemory() throws {
        let data = Data([0xe1, 0xc2])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.aslm(.dd(.d2)))
    }

    func testLogicalShiftImmediate() throws {
        var data = Data([0xe9, 0x0e])
        var op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.lsl(.b, .imm(4), .d6))
        
        data = Data([0xe1, 0x0e])
        op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.lsl(.b, .imm(8), .d6))
    }
    
    func testLogicalShiftRegister() throws {
        let data = Data([0xe9, 0x2e])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.lsl(.b, .r(.d4), .d6))
    }
    
    func testLogicalShiftRight() throws {
        let data = Data([0xe8, 0x2e])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.lsr(.b, .r(.d4), .d6))
    }
    
    func testLogicalShiftWord() throws {
        let data = Data([0xe8, 0x6e])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.lsr(.w, .r(.d4), .d6))
    }

    func testLogicalShiftLong() throws {
        let data = Data([0xe8, 0xae])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.lsr(.l, .r(.d4), .d6))
    }

    
    func testLogicalShiftRightMemory() throws {
        let data = Data([0xe2, 0xc9])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.lsrm(.ad(.a1)))
    }
    
    func testLogicalShiftLeftMemory() throws {
        let data = Data([0xe3, 0xc9])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.lslm(.ad(.a1)))
    }

    
    func testRotateImmediate() throws {
        var data = Data([0xe9, 0x98])
        var op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.rol(.l, .imm(4), .d0))
        
        data = Data([0xe1, 0x98])
        op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.rol(.l, .imm(8), .d0))
    }
    
    func testRotateRegister() throws {
        let data = Data([0xe3, 0xb8])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.rol(.l, .r(.d1), .d0))
    }
    
    func testRotateRight() throws {
        let data = Data([0xe2, 0xb8])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.ror(.l, .r(.d1), .d0))
    }
    
    func testRotateByte() throws {
        let data = Data([0xe3, 0x38])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.rol(.b, .r(.d1), .d0))
    }
    
    func testRotateWord() throws {
        let data = Data([0xe3, 0x78])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.rol(.w, .r(.d1), .d0))
    }
    
    func testRotateRightMemory() throws {
        let data = Data([0xe6, 0xc1])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.rorm(.dd(.d1)))
    }
    
    func testRotateLeftMemory() throws {
        let data = Data([0xe7, 0xc1])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.rolm(.dd(.d1)))
    }


    func testRotateExtendImmediate() throws {
        var data = Data([0xe3, 0x11])
        var op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.roxl(.b, .imm(1), .d1))
        
        data = Data([0xe1, 0x11])
        op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.roxl(.b, .imm(8), .d1))
    }
    
    func testRotateExtendRegister() throws {
        let data = Data([0xe1, 0x31])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.roxl(.b, .r(.d0), .d1))
    }

    func testRotateExtendRightRegister() throws {
        let data = Data([0xe0, 0x31])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.roxr(.b, .r(.d0), .d1))
    }
    
    func testRotateExtendWord() throws {
        let data = Data([0xe0, 0x71])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.roxr(.w, .r(.d0), .d1))
    }
    
    func testRotateExtendLong() throws {
        let data = Data([0xe0, 0xb1])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.roxr(.l, .r(.d0), .d1))
    }
    
    func testRotateExtendRightMemory() throws {
        let data = Data([0xe4, 0xc0])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.roxrm(.dd(.d0)))
    }
    
    func testRotateExtendLeftMemory() throws {
        let data = Data([0xe5, 0xc0])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.roxlm(.dd(.d0)))
    }

    func testClr() throws {
        let data = Data([0x42, 0x2d, 0x18, 0x00])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.clr(.b, .d16An(0x1800, .a5)))
    }
    
    func testBsetImmediate() throws {
        let data = Data([0x08, 0xd5, 0x00, 0x07])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bset(.imm(7), .ind(.a5)))
    }
    
    func testBsetRegister() throws {
        let data = Data([0x01, 0xd5])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bset(.r(.d0), .ind(.a5)))
    }
    
    func testBchgImmediateByte() throws {
        let data = Data([0x08, 0x51, 0x00, 0x07])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bchg(.b, .imm(7), .ind(.a1)))
    }
    
    func testBchgImmediateLong() throws {
        let data = Data([0x08, 0x40, 0x00, 0x07])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bchg(.l, .imm(7), .dd(.d0)))
    }
    
    func testBchgRegisterByte() throws {
        let data = Data([0x03, 0x48])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bchg(.b, .r(.d1), .ad(.a0)))
    }
    
    func testBchgRegisterLong() throws {
        let data = Data([0x03, 0x40])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bchg(.l, .r(.d1), .dd(.d0)))
    }
    
    func testBclrImmediate() throws {
        let data = Data([0x08, 0x91, 0x00, 0x10])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bclr(.imm(16), .ind(.a1)))
    }
    
    func testBclrRegister() throws {
        let data = Data([0x0f, 0x91])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.bclr(.r(.d7), .ind(.a1)))
    }
    
    func testBtstImmediate() throws {
        let data = Data([0x08, 0x15, 0x00, 0x07])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.btst(.imm(7), .ind(.a5)))
    }
    
    func testBtstRegister() throws {
        let data = Data([0x01, 0x15])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.btst(.r(.d0), .ind(.a5)))
    }
    
    func testSwap() throws {
        let data = Data([0x48, 0x40])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.swap(.d0))
    }
    
    func testPea() throws {
        let data = Data([0x48, 0x6a, 0xff, 0x94])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.pea(.d16An(-0x6c, .a2)))
    }
    
    func testRts() throws {
        let data = Data([0x4e, 0x75])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.rts)
    }
    
    func testNop() throws {
        let data = Data([0x4e, 0x71])
        let op = d.disassemble(data, loadAddress: 0)[0].op

        XCTAssertEqual(op, Operation.nop)
    }
}
