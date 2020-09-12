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

}
