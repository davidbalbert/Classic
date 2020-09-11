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
    
    func testSubqByteMem() throws {
        m.cpu.write8(3, value: 0x7f)
        m.cpu.a0 = 3
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        
        m.cpu.execute(.subqB(5, .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(3), 0x7a)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testSubqByteMemNegative() throws {
        m.cpu.write8(3, value: 0xff)
        m.cpu.a0 = 3
        m.cpu.ccr = []
        
        m.cpu.execute(.subqB(5, .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(3), 0xfa)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testSubqByteMemZero() throws {
        m.cpu.write8(3, value: 0x05)
        m.cpu.a0 = 3
        m.cpu.ccr = []
        
        m.cpu.execute(.subqB(5, .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(3), 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testSubqByteMemOverflow() throws {
        m.cpu.write8(3, value: 0x80)
        m.cpu.a0 = 3
        m.cpu.ccr = []
        
        m.cpu.execute(.subqB(1, .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(3), 0x7f)
        XCTAssertEqual(m.cpu.ccr, .v)
    }
    
    func testSubqByteMemBorrow() throws {
        m.cpu.write8(3, value: 0x04)
        m.cpu.a0 = 3
        m.cpu.ccr = []
        
        m.cpu.execute(.subqB(5, .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(3), 0xff)
        XCTAssertEqual(m.cpu.ccr, [.c, .x, .n])
    }
    
    func testSubqWordDataDirect() throws {
        m.cpu.d0 = 0x7afe
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        
        m.cpu.execute(.subqWL(.w, 5, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x7af9)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testSubqWordDataDirectNegative() throws {
        m.cpu.d0 = 0xcafe
        m.cpu.ccr = []
        
        m.cpu.execute(.subqWL(.w, 5, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xcaf9)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testSubqWordDataDirectZero() throws {
        m.cpu.d0 = 0x0005
        m.cpu.ccr = []
        
        m.cpu.execute(.subqWL(.w, 5, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testSubqWordDataDirectOverflow() throws {
        m.cpu.d0 = 0x8000
        m.cpu.ccr = []
        
        m.cpu.execute(.subqWL(.w, 1, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x7fff)
        XCTAssertEqual(m.cpu.ccr, .v)
    }
    
    func testSubqWordDataDirectBorrow() throws {
        m.cpu.d0 = 0x0004
        m.cpu.ccr = []
        
        m.cpu.execute(.subqWL(.w, 5, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xffff)
        XCTAssertEqual(m.cpu.ccr, [.c, .x, .n])
    }

}
