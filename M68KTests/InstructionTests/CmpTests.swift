//
//  CmpTests.swift
//  M68KTests
//
//  Created by David Albert on 9/13/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class CmpTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        CmpTests.m
    }
    
    func testCmpByte() throws {
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        m.cpu.d0 = 0xff05
        m.cpu.d1 = 0xce01
        
        m.cpu.execute(.cmp(.b, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testCmpByteZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x05
        m.cpu.d1 = 0x05
        
        m.cpu.execute(.cmp(.b, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testCmpByteNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xff
        m.cpu.d1 = 0x01
        
        m.cpu.execute(.cmp(.b, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .n)
    }

    func testCmpByteOverflow() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x80
        m.cpu.d1 = 0x1

        m.cpu.execute(.cmp(.b, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .v)
    }
    
    func testCmpByteBorrow() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x04
        m.cpu.d1 = 0x05
        
        m.cpu.execute(.cmp(.b, .dd(.d1), .d0), length: 0)

        XCTAssertEqual(m.cpu.ccr, [.c, .n])
    }
    
    func testCmpWord() throws {
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        m.cpu.d0 = 0xffff_1005
        m.cpu.d1 = 0x7afe_1001
        
        m.cpu.execute(.cmp(.w, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testCmpWordZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xcafe
        m.cpu.d1 = 0xcafe
        
        m.cpu.execute(.cmp(.w, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testCmpWordNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xffff
        m.cpu.d1 = 0x0001
        
        m.cpu.execute(.cmp(.w, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .n)
    }

    func testCmpWordOverflow() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x8000
        m.cpu.d1 = 0x0001

        m.cpu.execute(.cmp(.w, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .v)
    }
    
    func testCmpWordBorrow() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x7afd
        m.cpu.d1 = 0x7afe
        
        m.cpu.execute(.cmp(.w, .dd(.d1), .d0), length: 0)

        XCTAssertEqual(m.cpu.ccr, [.c, .n])
    }
    
    func testCmpLong() throws {
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        m.cpu.d0 = 0xcafe_beef
        m.cpu.d1 = 0xcafe_beee
        
        m.cpu.execute(.cmp(.l, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testCmpLongZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xcafe_beef
        m.cpu.d1 = 0xcafe_beef
        
        m.cpu.execute(.cmp(.l, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testCmpLongNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xffff_ffff
        m.cpu.d1 = 0x0000_0001
        
        m.cpu.execute(.cmp(.l, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .n)
    }

    func testCmpLongOverflow() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x8000_0000
        m.cpu.d1 = 0x0000_0001

        m.cpu.execute(.cmp(.l, .dd(.d1), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.ccr, .v)
    }
    
    func testCmpLongBorrow() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x5000_0000
        m.cpu.d1 = 0x5000_0001
        
        m.cpu.execute(.cmp(.l, .dd(.d1), .d0), length: 0)

        XCTAssertEqual(m.cpu.ccr, [.c, .n])
    }
}
