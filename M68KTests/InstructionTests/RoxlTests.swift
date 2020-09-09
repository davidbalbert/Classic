//
//  RoxlTests.swift
//  M68KTests
//
//  Created by David Albert on 9/8/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class RoxlTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        RoxlTests.m
    }
    
    func testRoxlByteImmediate() throws {
        m.cpu.d0 = 0b1010_1010
        m.cpu.ccr = .v
        
        m.cpu.execute(.roxl(.b, .imm(1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0101_0100)
        XCTAssertEqual(m.cpu.ccr, [.x, .c])
    }
    
    func testRoxlByteImmediateNegative() throws {
        m.cpu.d0 = 0b1010_1010
        m.cpu.ccr = []
        
        m.cpu.execute(.roxl(.b, .imm(2), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1010_1001)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testRoxlByteImmediateZero() {
        m.cpu.d0 = 0b0100_0000
        m.cpu.ccr = []
        
        m.cpu.execute(.roxl(.b, .imm(2), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, [.z, .x, .c])
    }
    
    func testRoxlByteImmediateCountZero() {
        m.cpu.d0 = 0b0110_1001
        m.cpu.ccr = .c
        
        m.cpu.execute(.roxl(.b, .imm(0), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0110_1001)
        XCTAssertEqual(m.cpu.ccr, [])
    }
}
