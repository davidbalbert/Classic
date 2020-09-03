//
//  CmpiTests.swift
//  M68KTests
//
//  Created by David Albert on 9/2/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class CmpiTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        CmpiTests.m
    }
    
    func testCmpiByte() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.b, 4, .imm(5)), length: 0)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testCmpiByteNegative() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.b, 1, .imm(-6)), length: 0)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testCmpiByteZero() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.b, 5, .imm(5)), length: 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testCmpiByteCarry() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.b, 251, .imm(250)), length: 0)
        XCTAssertEqual(m.cpu.ccr, [.c, .n])
    }
    
    func testCmpiByteOverflow() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.b, -1, .imm(127)), length: 0)
        XCTAssertEqual(m.cpu.ccr, [.n, .v, .c])
    }


    func testCmpiWord() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.w, 4, .imm(5)), length: 0)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testCmpiWordNegative() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.w, 1, .imm(-6)), length: 0)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testCmpiWordZero() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.w, 5, .imm(5)), length: 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testCmpiWordCarry() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.w, 251, .imm(250)), length: 0)
        XCTAssertEqual(m.cpu.ccr, [.c, .n])
    }
    
    func testCmpiWordOverflow() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.w, -1, .imm(0x7fff)), length: 0)
        XCTAssertEqual(m.cpu.ccr, [.n, .v, .c])
    }


    func testCmpiLong() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.l, 4, .imm(5)), length: 0)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testCmpiLongNegative() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.l, 1, .imm(-6)), length: 0)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testCmpiLongZero() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.l, 5, .imm(5)), length: 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testCmpiLongCarry() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.l, 251, .imm(250)), length: 0)
        XCTAssertEqual(m.cpu.ccr, [.c, .n])
    }
    
    func testCmpiLongOverflow() throws {
        m.cpu.ccr = []
        m.cpu.execute(.cmpi(.l, -1, .imm(0x7fff_ffff)), length: 0)
        XCTAssertEqual(m.cpu.ccr, [.n, .v, .c])
    }
}
