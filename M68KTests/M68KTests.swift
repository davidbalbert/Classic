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
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAnd() throws {
        let data = Data([0xc0, 0x47])
        var d = Disassembler(data, loadAddress: 0)
        let op = d.disassemble()[0].op

        XCTAssertEqual(op, Operation.and(.w, .mToR, .dd(.d7), .d0))
    }

    func testBra() throws {
        var data = Data([0x60, 0x02])
        var d = Disassembler(data, loadAddress: 0)
        var op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.bra(.b, 2, 0x2))
        
        data = Data([0x60, 0x00, 0x00, 0x16])
        d = Disassembler(data, loadAddress: 0)
        op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.bra(.w, 2, 0x16))
        
        data = Data([0x60, 0xee])
        d = Disassembler(data, loadAddress: 0)
        op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.bra(.b, 2, -18))
    }
    
    func testBne() throws {
        var data = Data([0x66, 0x00, 0x00, 0xfc])
        var d = Disassembler(data, loadAddress: 0)
        var op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.bcc(.w, .ne, 2, 0xfc))
        
        data = Data([0x66, 0xee])
        d = Disassembler(data, loadAddress: 0x40)
        op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.bcc(.b, .ne, 0x42, -18))
    }

    
    func testMove() throws {
        var data = Data([0x10, 0x80])
        var d = Disassembler(data, loadAddress: 0)
        var op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.move(.b, .dd(.d0), .ind(.a0)))
        
        data = Data([0x20, 0x0f])
        d = Disassembler(data, loadAddress: 0)
        op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.move(.l, .ad(.a7), .dd(.d0)))
    }
    
    func testMoveQ() throws {
        let data = Data([0x7e, 0x01])
        var d = Disassembler(data, loadAddress: 0)
        let op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.moveq(1, .d7))

    }
    
    func testMoveM() throws {
        let data = Data([0x4c, 0xf9, 0x01, 0x01, 0x00, 0xf8, 0x00, 0x00])
        var d = Disassembler(data, loadAddress: 0)
        let op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.movem(.l, .mToR, .XXXl(0xf80000), [.d0, .a0]))
    }
    
    func testLea() throws {
        let data = Data([0x4d, 0xfa, 0x00, 0x06])
        var d = Disassembler(data, loadAddress: 0)
        let op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.lea(.d16PC(2, 0x6), .a6))
    }
    
    func testSubq() throws {
        let data = Data([0x53, 0x8f])
        var d = Disassembler(data, loadAddress: 0)
        let op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.subq(.l, 1, .ad(.a7)))
    }
    
    func testCmpi() throws {
        let data = Data([0x0c, 0x80, 0x55, 0xaa, 0xaa, 0x55])
        var d = Disassembler(data, loadAddress: 0)
        let op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.cmpi(.l, 0x55aaaa55, .dd(.d0)))
    }
    
    func testJmp() throws {
        let data = Data([0x4e, 0xd0])
        var d = Disassembler(data, loadAddress: 0)
        let op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.jmp(.ind(.a0)))
    }
    
    func testMoveToSR() throws {
        let data = Data([0x46, 0xfc, 0x27, 0x00])
        var d = Disassembler(data, loadAddress: 0)
        let op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.moveToSR(.imm(.w(0x2700))))
    }
    
    func testTst() throws {
        let data = Data([0x4a, 0x1e])
        var d = Disassembler(data, loadAddress: 0)
        let op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.tst(.b, .postInc(.a6)))
    }
}
