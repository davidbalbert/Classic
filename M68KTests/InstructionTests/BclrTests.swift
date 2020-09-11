//
//  BclrTests.swift
//  M68KTests
//
//  Created by David Albert on 9/10/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class BclrTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        BclrTests.m
    }
    
    func testBclrByteImmMem() throws {
        m.cpu.ccr = []
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 1<<3)
        
        m.cpu.execute(.bclr(.imm(8+3), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 0)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testBclrByteImmMemZero() throws {
        m.cpu.ccr = []
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 1<<0)
        
        m.cpu.execute(.bclr(.imm(8+3), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 1<<0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testBclrByteRegMem() throws {
        m.cpu.ccr = []
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 1<<3)
        m.cpu.d1 = 8+3
        
        m.cpu.execute(.bclr(.r(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 0)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testBclrByteRegMemZero() throws {
        m.cpu.ccr = []
        m.cpu.a0 = 2
        m.cpu.write8(2, value: 1<<0)
        m.cpu.d1 = 8+3
        
        m.cpu.execute(.bclr(.r(.d1), .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(2), 1<<0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testBclrLongImmDd() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 1 << 27
        m.cpu.execute(.bclr(.imm(32+27), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testBclrLongImmDdZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 1 << 0
        m.cpu.execute(.bclr(.imm(32+27), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 1<<0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testBclrLongRegDd() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 1 << 27
        m.cpu.d1 = 32+27
        m.cpu.execute(.bclr(.r(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testBclrLongRegDdZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 1 << 0
        m.cpu.d1 = 32+27
        m.cpu.execute(.bclr(.r(.d1), .dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 1<<0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
}
