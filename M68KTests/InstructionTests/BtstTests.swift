//
//  BtstTests.swift
//  M68KTests
//
//  Created by David Albert on 9/13/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class BtstTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        BtstTests.m
    }
    
    func testBtstByteImmDd() throws {
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        m.cpu.d0 = 1 << 27
        
        m.cpu.execute(.btst(.imm(32+27), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, [.x, .n, .v, .c])
    }
    
    func testBtstByteImmDdZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 1 << 5
        
        m.cpu.execute(.btst(.imm(32+27), .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testBtstByteImmImm() throws {
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        
        m.cpu.execute(.btst(.imm(32+3), .imm(1 << 3)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, [.x, .n, .v, .c])
    }
    
    func testBtstByteImmImmZero() throws {
        m.cpu.ccr = []
        
        m.cpu.execute(.btst(.imm(32+3), .imm(1 << 5)), length: 0)

        XCTAssertEqual(m.cpu.ccr, .z)
    }

    func testBtstByteImmMem() throws {
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 1 << 3)
        
        m.cpu.execute(.btst(.imm(32+3), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, [.x, .n, .v, .c])
    }
    
    func testBtstByteImmMemZero() throws {
        m.cpu.ccr = []
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 1 << 5)

        
        m.cpu.execute(.btst(.imm(32+3), .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.ccr, .z)
    }
}
