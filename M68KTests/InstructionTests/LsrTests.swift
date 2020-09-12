//
//  LsrTests.swift
//  M68KTests
//
//  Created by David Albert on 9/10/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class LsrTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        LsrTests.m
    }
    
    func testLsrByteImm() throws {
        m.cpu.d0 = 0b1_1010_1010
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsr(.b, .imm(3), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1_0001_0101)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testLsrByteImmCarry() throws {
        m.cpu.d0 = 0b1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.b, .imm(2), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0010_1010)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLsrByteImmZero() throws {
        m.cpu.d0 = 0b1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.b, .imm(8), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, [.x, .c, .z])
    }
    
    func testLsrWordImm() throws {
        m.cpu.d0 = 0b1_1010_1010_1010_1010
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsr(.w, .imm(3), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1_0001_0101_0101_0101)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testLsrWordImmCarry() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.w, .imm(2), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0010_1010_1010_1010)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLsrWordImmZero() throws {
        m.cpu.d0 = 0b0000_0000_1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.w, .imm(8), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, [.x, .c, .z])
    }

    func testLsrLongImm() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010_1010_1010_1010_1010
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsr(.l, .imm(3), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0001_0101_0101_0101_0101_0101_0101_0101)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testLsrLongImmCarry() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010_1010_1010_1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.l, .imm(2), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0010_1010_1010_1010_1010_1010_1010_1010)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLsrLongImmZero() throws {
        m.cpu.d0 = 0b0000_0000_0000_0000_0000_0000_1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.l, .imm(8), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, [.x, .c, .z])
    }

    
    
    
    
    
    
    func testLsrByteReg() throws {
        m.cpu.d0 = 0b1_1010_1010
        m.cpu.d1 = 3
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsr(.b, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1_0001_0101)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testLsrByteRegCarry() throws {
        m.cpu.d0 = 0b1010_1010
        m.cpu.d1 = 2
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.b, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0010_1010)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLsrByteRegZero() throws {
        m.cpu.d0 = 0b1010_1010
        m.cpu.d1 = 8
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.b, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, [.x, .c, .z])
    }
    
    func testLsrByteRegShiftCountZero() throws {
        m.cpu.d0 = 0b0101_0101
        m.cpu.d1 = 0
        m.cpu.ccr = [.x, .c]
        
        m.cpu.execute(.lsr(.b, .r(.d1), .d0), length: 0)

        XCTAssertEqual(m.cpu.d0, 0b0101_0101)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
    
    func testLsrWordReg() throws {
        m.cpu.d0 = 0b1_1010_1010_1010_1010
        m.cpu.d1 = 3
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsr(.w, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1_0001_0101_0101_0101)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testLsrWordRegCarry() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010
        m.cpu.d1 = 2
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.w, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0010_1010_1010_1010)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLsrWordRegZero() throws {
        m.cpu.d0 = 0b0000_0000_1010_1010
        m.cpu.d1 = 8
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.w, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, [.x, .c, .z])
    }
    
    func testLsrWordRegShiftCountZero() throws {
        m.cpu.d0 = 0b0110_1100_0101_0101
        m.cpu.d1 = 0
        m.cpu.ccr = [.x, .c]
        
        m.cpu.execute(.lsr(.w, .r(.d1), .d0), length: 0)

        XCTAssertEqual(m.cpu.d0, 0b0110_1100_0101_0101)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }

    func testLsrLongReg() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010_1010_1010_1010_1010
        m.cpu.d1 = 3
        m.cpu.ccr = [.n, .z, .v, .x, .c]
        
        m.cpu.execute(.lsr(.l, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0001_0101_0101_0101_0101_0101_0101_0101)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testLsrLongRegCarry() throws {
        m.cpu.d0 = 0b1010_1010_1010_1010_1010_1010_1010_1010
        m.cpu.d1 = 2
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.l, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0010_1010_1010_1010_1010_1010_1010_1010)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testLsrLongRegZero() throws {
        m.cpu.d0 = 0b0000_0000_0000_0000_0000_0000_1010_1010
        m.cpu.d1 = 8
        m.cpu.ccr = []
        
        m.cpu.execute(.lsr(.l, .r(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, [.x, .c, .z])
    }
    
    func testLsrLongRegShiftCountZero() throws {
        m.cpu.d0 = 0b0110_1100_0101_0101_0110_1100_0101_0101
        m.cpu.d1 = 0
        m.cpu.ccr = [.x, .c]
        
        m.cpu.execute(.lsr(.l, .r(.d1), .d0), length: 0)

        XCTAssertEqual(m.cpu.d0, 0b0110_1100_0101_0101_0110_1100_0101_0101)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
}
