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
    
    func testSuba() throws {
        let data = Data([0x97, 0xcb])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.suba(.l, .ad(.a3), .a3))
    }

    
    func testSubq() throws {
        let data = Data([0x53, 0x8f])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.subq(.l, 1, .ad(.a7)))
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
    
    func testMoveToSR() throws {
        let data = Data([0x46, 0xfc, 0x27, 0x00])
        let op = d.disassemble(data, loadAddress: 0)[0].op
        
        XCTAssertEqual(op, Operation.moveToSR(.imm(.w(0x2700))))
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
}
