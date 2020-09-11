//
//  TstTests.swift
//  M68KTests
//
//  Created by David Albert on 9/10/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class TstTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        TstTests.m
    }
    
    func testTstByte() throws {
        m.cpu.d0 = 0xffff_ff7f
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        
        m.cpu.execute(.tst(.b, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testTstByteZero() throws {
        m.cpu.d0 = 0xffff_ff00
        m.cpu.ccr = []
        
        m.cpu.execute(.tst(.b, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testTstByteNegative() throws {
        m.cpu.d0 = 0xffff_ff80
        m.cpu.ccr = []
        
        m.cpu.execute(.tst(.b, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    
    func testTstWord() throws {
        m.cpu.d0 = 0xffff_7fff
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        
        m.cpu.execute(.tst(.w, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testTstWordZero() throws {
        m.cpu.d0 = 0xffff_0000
        m.cpu.ccr = []
        
        m.cpu.execute(.tst(.w, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testTstWordNegative() throws {
        m.cpu.d0 = 0xffff_8000
        m.cpu.ccr = []
        
        m.cpu.execute(.tst(.w, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testTstLong() throws {
        m.cpu.d0 = 0x7fff_ffff
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        
        m.cpu.execute(.tst(.l, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testTstLongZero() throws {
        m.cpu.d0 = 0x0000_0000
        m.cpu.ccr = []
        
        m.cpu.execute(.tst(.l, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testTstLongNegative() throws {
        m.cpu.d0 = 0x8000_0000
        m.cpu.ccr = []
        
        m.cpu.execute(.tst(.l, .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .n)
    }
}
