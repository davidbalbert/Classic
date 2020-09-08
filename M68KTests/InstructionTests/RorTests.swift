//
//  RorTests.swift
//  M68KTests
//
//  Created by David Albert on 9/7/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class RorTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        RorTests.m
    }
    
    func testRorByteImmediate() throws {
        m.cpu.ccr = [.v, .x]
        m.cpu.d0 = 0b1111_1100_1010
        
        m.cpu.execute(.ror(.b, .imm(2), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1111_1011_0010)
        XCTAssertEqual(m.cpu.ccr, [.x, .n, .c])
    }
    
    func testRorByteImmediatePositive() throws {
        m.cpu.ccr = .v
        m.cpu.d0 = 0b1100_1010
        
        m.cpu.execute(.ror(.b, .imm(1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0110_0101)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testRorByteImmediateZero() throws {
        m.cpu.ccr = .v
        m.cpu.d0 = 0
        
        m.cpu.execute(.ror(.b, .imm(5), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testRorByteImmediateCountZero() throws {
        m.cpu.ccr = .v
        m.cpu.d0 = 0b1100_1010

        m.cpu.execute(.ror(.b, .imm(0), .d0), length: 0)
        XCTAssertEqual(m.cpu.d0, 0b1100_1010)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testRorWordImmediate() throws {
        m.cpu.ccr = [.v, .x]
        m.cpu.d0 = 0b1100_1010_1100_1010
        
        m.cpu.execute(.ror(.w, .imm(2), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1011_0010_1011_0010)
        XCTAssertEqual(m.cpu.ccr, [.x, .n, .c])
    }
    
    func testRorWordImmediatePositive() throws {
        m.cpu.ccr = .v
        m.cpu.d0 = 0b1100_1010_1100_1010
        
        m.cpu.execute(.ror(.w, .imm(1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0110_0101_0110_0101)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testRorWordImmediateZero() throws {
        m.cpu.ccr = .v
        m.cpu.d0 = 0
        
        m.cpu.execute(.ror(.w, .imm(5), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testRorWordImmediateCountZero() throws {
        m.cpu.ccr = .v
        m.cpu.d0 = 0b1100_1010_1100_1010

        m.cpu.execute(.ror(.w, .imm(0), .d0), length: 0)
        XCTAssertEqual(m.cpu.d0, 0b1100_1010_1100_1010)
        XCTAssertEqual(m.cpu.ccr, .n)
    }

}
