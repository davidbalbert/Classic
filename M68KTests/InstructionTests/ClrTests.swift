//
//  ClrTests.swift
//  M68KTests
//
//  Created by David Albert on 9/13/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class ClrTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        ClrTests.m
    }
    
    func testClearByteDd() throws {
        m.cpu.ccr = [.x, .n, .v, .c]
        m.cpu.d0 = 0xffff
        
        m.cpu.execute(.clr(.b, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xff00)
        XCTAssertEqual(m.cpu.ccr, [.x, .z])
    }
    
    func testClearByteMem() throws {
        m.cpu.ccr = [.x, .n, .v, .c]
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 0xff)
        
        m.cpu.execute(.clr(.b, .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 0x00)
        XCTAssertEqual(m.cpu.ccr, [.x, .z])
    }
    
    func testClearWordDd() throws {
        m.cpu.ccr = [.x, .n, .v, .c]
        m.cpu.d0 = 0xffff_ffff
        
        m.cpu.execute(.clr(.w, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xffff_0000)
        XCTAssertEqual(m.cpu.ccr, [.x, .z])
    }
    
    func testClearWordMem() throws {
        m.cpu.ccr = [.x, .n, .v, .c]
        m.cpu.a0 = 2
        m.cpu.write16(2, value: 0xffff)
        
        m.cpu.execute(.clr(.w, .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read16(2), 0x0000)
        XCTAssertEqual(m.cpu.ccr, [.x, .z])
    }
    
    func testClearLongDd() throws {
        m.cpu.ccr = [.x, .n, .v, .c]
        m.cpu.d0 = 0xffff_ffff
        
        m.cpu.execute(.clr(.l, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0000_0000)
        XCTAssertEqual(m.cpu.ccr, [.x, .z])
    }
    
    func testClearlongMem() throws {
        m.cpu.ccr = [.x, .n, .v, .c]
        m.cpu.a0 = 2
        m.cpu.write32(2, value: 0xffff_ffff)
        
        m.cpu.execute(.clr(.l, .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read32(2), 0x0000_0000)
        XCTAssertEqual(m.cpu.ccr, [.x, .z])
    }
}
