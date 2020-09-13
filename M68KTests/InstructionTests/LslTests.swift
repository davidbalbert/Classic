//
//  LslTests.swift
//  M68KTests
//
//  Created by David Albert on 9/12/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class LslTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        LslTests.m
    }
    
    func testLslByteImm() throws {
        m.cpu.d0 = 0b1_1010_1010
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsl(.b, .imm(2), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1_1010_1000)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testLslByteImmCarry() throws {
        m.cpu.d0 = 0b1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.b, .imm(3), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0101_0000)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLslByteImmZero() throws {
        m.cpu.d0 = 0b1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.b, .imm(8), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testLslWordImm() throws {
        m.cpu.d0 = 0b1_1010_1010_1010_1010
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsl(.w, .imm(2), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1_1010_1010_1010_1000)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testLslWordImmCarry() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.w, .imm(3), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0101_0101_0101_0000)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLslWordImmZero() throws {
        m.cpu.d0 = 0b1010_1010_0000_0000
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.w, .imm(8), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }

    func testLslLongImm() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010_1010_1010_1010_1010
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsl(.l, .imm(2), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1010_1010_1010_1010_1010_1010_1010_1000)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testLslLongImmCarry() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010_1010_1010_1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.l, .imm(3), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0101_0101_0101_0101_0101_0101_0101_0000)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLslLongImmZero() throws {
        m.cpu.d0 = 0b1010_1010_0000_0000_0000_0000_0000_0000
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.l, .imm(8), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testLslByteReg() throws {
        m.cpu.d0 = 0b1_1010_1010
        m.cpu.d1 = 2
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsl(.b, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1_1010_1000)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testLslByteRegCarry() throws {
        m.cpu.d0 = 0b1010_1010
        m.cpu.d1 = 3
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.b, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0101_0000)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLslByteRegZero() throws {
        m.cpu.d0 = 0b1010_1010
        m.cpu.d1 = 8
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.b, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testLslByteRegShiftCountZero() throws {
        m.cpu.d0 = 0b0101_0101
        m.cpu.d1 = 0
        m.cpu.ccr = [.x, .c]
        
        m.cpu.execute(.lsl(.b, .r(.d1), .d0), length: 0)

        XCTAssertEqual(m.cpu.d0, 0b0101_0101)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
    
    func testLslWordReg() throws {
        m.cpu.d0 = 0b1_1010_1010_1010_1010
        m.cpu.d1 = 2
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsl(.w, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1_1010_1010_1010_1000)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testLslWordRegCarry() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010
        m.cpu.d1 = 3
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.w, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0101_0101_0101_0000)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLslWordRegZero() throws {
        m.cpu.d0 = 0b1010_1010_0000_0000
        m.cpu.d1 = 8
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.w, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testLslWordRegShiftCountZero() throws {
        m.cpu.d0 = 0b0110_1100_0101_0101
        m.cpu.d1 = 0
        m.cpu.ccr = [.x, .c]
        
        m.cpu.execute(.lsl(.w, .r(.d1), .d0), length: 0)

        XCTAssertEqual(m.cpu.d0, 0b0110_1100_0101_0101)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }

    
    
    
    
    
    
    func testLslLongReg() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010_1010_1010_1010_1010
        m.cpu.d1 = 2
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsl(.l, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1010_1010_1010_1010_1010_1010_1010_1000)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testLslLongRegCarry() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010_1010_1010_1010_1010
        m.cpu.d1 = 3
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.l, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0101_0101_0101_0101_0101_0101_0101_0000)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLslLongRegZero() throws {
        m.cpu.d0 = 0b1010_1010_0000_0000_0000_0000_0000_0000
        m.cpu.d1 = 8
        m.cpu.ccr = []
        
        m.cpu.execute(.lsl(.l, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testLslLongRegShiftCountZero() throws {
        m.cpu.d0 = 0b0110_1100_0101_0101_0110_1100_0101_0101
        m.cpu.d1 = 0
        m.cpu.ccr = [.x, .c]
        
        m.cpu.execute(.lsl(.l, .r(.d1), .d0), length: 0)

        XCTAssertEqual(m.cpu.d0, 0b0110_1100_0101_0101_0110_1100_0101_0101)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
}
