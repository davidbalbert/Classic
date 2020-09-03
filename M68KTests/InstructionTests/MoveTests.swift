//
//  MoveTests.swift
//  M68KTests
//
//  Created by David Albert on 9/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class MoveTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        MoveTests.m
    }
    
    func testMoveByteDn() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d1 = 0xffff_ff7f
        m.cpu.d0 = 0xffff_ffab
        
        m.cpu.execute(.move(.b, .dd(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xffff_ff7f)
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testMoveByteDnNeg() throws {
        m.cpu.ccr = []
        m.cpu.d1 = 0xffff_ff80
        m.cpu.d0 = 0
        
        m.cpu.execute(.move(.b, .dd(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x80)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testMoveByteDnZero() throws {
        m.cpu.ccr = []
        m.cpu.d1 = 0xffff_ff00
        m.cpu.d0 = 0xaaaa_aaaa
        
        m.cpu.execute(.move(.b, .dd(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xaaaa_aa00)
        XCTAssertEqual(m.cpu.ccr, .z)
    }

    
    func testMoveByteEa() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d1 = 0xffff_ff7f
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 0xab)
        
        m.cpu.execute(.move(.b, .dd(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 0x7f)
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testMoveByteEaNeg() throws {
        m.cpu.ccr = []
        m.cpu.d1 = 0xffff_ff80
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 0)

        m.cpu.execute(.move(.b, .dd(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 0x80)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testMoveByteEaZero() throws {
        m.cpu.ccr = []
        m.cpu.d1 = 0xffff_ff00
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 0xaa)

        m.cpu.execute(.move(.b, .dd(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testMoveWordDn() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d1 = 0xffff_7afe
        m.cpu.d0 = 0xaaaa_bbbb
        
        m.cpu.execute(.move(.w, .dd(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xaaaa_7afe)
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testMoveWordDnNeg() throws {
        m.cpu.ccr = []
        m.cpu.d1 = 0xffff_cafe
        m.cpu.d0 = 0xaaaa_bbbb

        m.cpu.execute(.move(.w, .dd(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xaaaa_cafe)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testMoveWordDnZero() throws {
        m.cpu.ccr = []
        m.cpu.d1 = 0xffff_0000
        m.cpu.d0 = 0xaaaa_bbbb
        
        m.cpu.execute(.move(.w, .dd(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xaaaa_0000)
        XCTAssertEqual(m.cpu.ccr, .z)
    }

    
    func testMoveWordEa() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d1 = 0xffff_7afe
        m.cpu.a0 = 2
        m.cpu.write16(2, value: 0xaaaa)
        
        m.cpu.execute(.move(.w, .dd(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read16(2), 0x7afe)
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testMoveWordEaNeg() throws {
        m.cpu.ccr = []
        m.cpu.d1 = 0xffff_cafe
        m.cpu.a0 = 2
        m.cpu.write16(2, value: 0)

        m.cpu.execute(.move(.w, .dd(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read16(2), 0xcafe)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testMoveWordEaZero() throws {
        m.cpu.ccr = []
        m.cpu.d1 = 0xffff_0000
        m.cpu.a0 = 2
        m.cpu.write16(2, value: 0xaaaa)

        m.cpu.execute(.move(.w, .dd(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read16(2), 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }

}
