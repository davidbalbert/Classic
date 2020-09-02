//
//  BsetTests.swift
//  M68KTests
//
//  Created by David Albert on 8/30/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class BsetTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        BsetTests.m
    }
    
    func testBsetImmByte() throws {
        m.cpu.ccr = []
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 0)
        
        m.cpu.execute(.bset(.imm(0), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 1)
        XCTAssertEqual(m.cpu.ccr, .z)
        
        m.cpu.execute(.bset(.imm(0), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 1)
        XCTAssertEqual(m.cpu.ccr, [])
        
        m.cpu.execute(.bset(.imm(2), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 5)
        XCTAssertEqual(m.cpu.ccr, .z)
    
        m.cpu.write8(2, value: 0)
        m.cpu.execute(.bset(.imm(7), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 0x80)
        XCTAssertEqual(m.cpu.ccr, .z)
        
        m.cpu.write8(2, value: 0)
        m.cpu.execute(.bset(.imm(9), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 2)
        XCTAssertEqual(m.cpu.ccr, .z)
        
        
        m.cpu.write8(2, value: 0)
        m.cpu.ccr = [.v, .n, .x, .c]
        
        m.cpu.execute(.bset(.imm(1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 2)
        XCTAssertEqual(m.cpu.ccr, [.v, .n, .x, .c, .z])
    }
    
    func testBsetRegByte() throws {
        m.cpu.ccr = []
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 0)

        m.cpu.d1 = 0
        m.cpu.execute(.bset(.r(.d1), .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read8(2), 1)
        XCTAssertEqual(m.cpu.ccr, .z)

        m.cpu.execute(.bset(.r(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 1)
        XCTAssertEqual(m.cpu.ccr, [])


        m.cpu.d1 = 2
        m.cpu.execute(.bset(.r(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 5)
        XCTAssertEqual(m.cpu.ccr, .z)

        m.cpu.write8(2, value: 0)
        m.cpu.d1 = 7
        m.cpu.execute(.bset(.r(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 0x80)
        XCTAssertEqual(m.cpu.ccr, .z)
        
        m.cpu.write8(2, value: 0)
        m.cpu.d1 = 9
        m.cpu.execute(.bset(.r(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 2)
        XCTAssertEqual(m.cpu.ccr, .z)
        
        m.cpu.write8(2, value: 0)
        m.cpu.d1 = 1
        m.cpu.ccr = [.v, .n, .x, .c]
        
        m.cpu.execute(.bset(.r(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 2)
        XCTAssertEqual(m.cpu.ccr, [.v, .n, .x, .c, .z])
    }
    
    func testBsetImmLong() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0
        
        m.cpu.execute(.bset(.imm(0), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 1)
        XCTAssertEqual(m.cpu.ccr, .z)
        
        m.cpu.execute(.bset(.imm(0), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 1)
        XCTAssertEqual(m.cpu.ccr, [])
        
        m.cpu.execute(.bset(.imm(2), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 5)
        XCTAssertEqual(m.cpu.ccr, .z)
    
        m.cpu.d0 = 0
        m.cpu.execute(.bset(.imm(29), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x2000_0000)
        XCTAssertEqual(m.cpu.ccr, .z)
        
        m.cpu.d0 = 0
        m.cpu.execute(.bset(.imm(33), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 2)
        XCTAssertEqual(m.cpu.ccr, .z)
        
        m.cpu.d0 = 0
        m.cpu.ccr = [.v, .n, .x, .c]
        
        m.cpu.execute(.bset(.imm(1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 2)
        XCTAssertEqual(m.cpu.ccr, [.v, .n, .x, .c, .z])
    }
    
    func testBsetRegLong() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0
        
        m.cpu.d1 = 0
        m.cpu.execute(.bset(.r(.d1), .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 1)
        XCTAssertEqual(m.cpu.ccr, .z)

        m.cpu.execute(.bset(.r(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 1)
        XCTAssertEqual(m.cpu.ccr, [])


        m.cpu.d1 = 2
        m.cpu.execute(.bset(.r(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 5)
        XCTAssertEqual(m.cpu.ccr, .z)

        m.cpu.d0 = 0
        m.cpu.d1 = 29
        m.cpu.execute(.bset(.r(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x2000_0000)
        XCTAssertEqual(m.cpu.ccr, .z)
        
        m.cpu.d0 = 0
        m.cpu.d1 = 33
        m.cpu.execute(.bset(.r(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 2)
        XCTAssertEqual(m.cpu.ccr, .z)
        
        m.cpu.d0 = 0
        m.cpu.d1 = 1
        m.cpu.ccr = [.v, .n, .x, .c]
        
        m.cpu.execute(.bset(.r(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 2)
        XCTAssertEqual(m.cpu.ccr, [.v, .n, .x, .c, .z])
    }
}
