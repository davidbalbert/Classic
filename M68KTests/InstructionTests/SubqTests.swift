//
//  SubqTests.swift
//  M68KTests
//
//  Created by David Albert on 9/9/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class SubqTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        SubqTests.m
    }
    
    func testSubqByteDataDirect() throws {
        m.cpu.d0 = 0x7f
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        
        m.cpu.execute(.subqB(5, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x7a)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testSubqByteDataDirectNegative() throws {
        m.cpu.d0 = 0xff
        m.cpu.ccr = []
        
        m.cpu.execute(.subqB(5, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xfa)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testSubqByteDataDirectZero() throws {
        m.cpu.d0 = 0x05
        m.cpu.ccr = []
        
        m.cpu.execute(.subqB(5, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testSubqByteDataDirectOverflow() throws {
        m.cpu.d0 = 0x80
        m.cpu.ccr = []
        
        m.cpu.execute(.subqB(1, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x7f)
        XCTAssertEqual(m.cpu.ccr, .v)
    }
    
    func testSubqByteDataDirectBorrow() throws {
        m.cpu.d0 = 0x04
        m.cpu.ccr = []
        
        m.cpu.execute(.subqB(5, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xff)
        XCTAssertEqual(m.cpu.ccr, [.c, .x, .n])
    }
}
