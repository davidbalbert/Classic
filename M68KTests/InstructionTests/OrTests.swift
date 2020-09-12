//
//  OrTests.swift
//  M68KTests
//
//  Created by David Albert on 9/12/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class OrTests: XCTestCase {
    private static var m = TestMachine(Array(repeating: 0, count: 2048))
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        OrTests.m
    }
    
    func testOrMRByte() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d0 = 0xaa00
        m.cpu.d1 = 0x1155
        
        m.cpu.execute(.orMR(.b, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xaa55)
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testOrMRByteNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x55
        m.cpu.d1 = 0xaa
        
        m.cpu.execute(.orMR(.b, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xff)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testOrMRByteZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x00
        m.cpu.d1 = 0x00
        
        m.cpu.execute(.orMR(.b, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x00)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testOrMRWord() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d0 = 0xaa_0000
        m.cpu.d1 = 0x11_5555
        
        m.cpu.execute(.orMR(.w, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xaa_5555)
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testOrMRWordNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x5555
        m.cpu.d1 = 0xaaaa
        
        m.cpu.execute(.orMR(.w, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xffff)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testOrMRWordZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x0000
        m.cpu.d1 = 0x0000
        
        m.cpu.execute(.orMR(.w, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0000)
        XCTAssertEqual(m.cpu.ccr, .z)
    }

    
    func testOrMRLong() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d0 = 0x0000_0000
        m.cpu.d1 = 0x5555_5555
        
        m.cpu.execute(.orMR(.l, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x5555_5555)
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testOrMRLongNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x5555_5555
        m.cpu.d1 = 0xaaaa_aaaa
        
        m.cpu.execute(.orMR(.l, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xffff_ffff)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testOrMRLongZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0
        m.cpu.d1 = 0
        
        m.cpu.execute(.orMR(.l, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
}
