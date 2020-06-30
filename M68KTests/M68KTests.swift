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

    func testBra() throws {
        var data = Data([0x60, 0x02])
        var d = Disassembler(data, loadAddress: 0)
        var op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.bra(.b, 0, 0x2))
        
        data = Data([0x60, 0x00, 0x00, 0x16])
        d = Disassembler(data, loadAddress: 0)
        op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.bra(.w, 0, 0x16))
    }
    
    func testBne() throws {
        var data = Data([0x66, 0x00, 0x00, 0xfc])
        var d = Disassembler(data, loadAddress: 0)
        var op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.bcc(.w, .ne, 0, 0xfc))
        
        data = Data([0x66, 0xee])
        d = Disassembler(data, loadAddress: 0)
        op = d.disassemble()[0].op

        XCTAssertEqual(op, Operation.bcc(.b, .ne, 0, 0xee))
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
    
    func testLea() throws {
        let data = Data([0x4d, 0xfa, 0x00, 0x06])
        var d = Disassembler(data, loadAddress: 0)
        let op = d.disassemble()[0].op
        
        XCTAssertEqual(op, Operation.lea(.d16PC(2, 0x6), .a6))
    }
}
