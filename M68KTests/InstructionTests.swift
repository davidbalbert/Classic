//
//  InstructionTests.swift
//  M68KTests
//
//  Created by David Albert on 8/30/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class InstructionTests: XCTestCase {
    static var m = TestMachine([])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        InstructionTests.m
    }

    func testAddMRByte() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0xff05
        m.cpu.execute(.addMR(.b, .imm(4), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xff09)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testAddMRByteCarry() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0xff05
        m.cpu.execute(.addMR(.b, .imm(0xfb), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xff00)
        XCTAssertEqual(m.cpu.ccr, [.c, .z, .x])
    }
    
    func testAddMRByteOverflow() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0xff05
        m.cpu.execute(.addMR(.b, .imm(0x7e), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xff83)
        XCTAssertEqual(m.cpu.ccr, [.v, .n])
    }
    
    func testAddMRWord() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0xffff0005
        m.cpu.execute(.addMR(.w, .imm(4), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xffff0009)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testAddMRWordCarry() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0xffff0005
        m.cpu.execute(.addMR(.w, .imm(0xfffb), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xffff0000)
        XCTAssertEqual(m.cpu.ccr, [.c, .z, .x])
    }
    
    func testAddMRWordOverflow() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0xffff0005
        m.cpu.execute(.addMR(.w, .imm(0x7ffe), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xffff8003)
        XCTAssertEqual(m.cpu.ccr, [.v, .n])
    }
    
    func testAddMRLong() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0x0000_0005
        m.cpu.execute(.addMR(.l, .imm(0x1000_0004), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x1000_0009)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testAddMRLongCarry() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0x0000_0005
        m.cpu.execute(.addMR(.l, .imm(Int32(bitPattern: 0xffff_fffb)), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0000_0000)
        XCTAssertEqual(m.cpu.ccr, [.c, .z, .x])
    }
    
    func testAddMRLongOverflow() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0x7afe_0005
        m.cpu.execute(.addMR(.l, .imm(0x1000_0004), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x8afe_0009)
        XCTAssertEqual(m.cpu.ccr, [.v, .n])
    }
}
