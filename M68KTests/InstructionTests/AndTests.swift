//
//  AndTests.swift
//  M68KTests
//
//  Created by David Albert on 8/30/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class AndTests: XCTestCase {
    static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        AndTests.m
    }
    
    func testAndMRByte() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0b1010_1010
        
        m.cpu.execute(.andMR(.b, .imm(0x0f), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b0000_1010)
        XCTAssertEqual(m.cpu.ccr, [])
    }

    func testAndMRByteNegative() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0b1010_1010
        
        m.cpu.execute(.andMR(.b, .imm(0xf0), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0b1010_0000)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }
    
    func testAndMRByteZero() throws {
        m.cpu.ccr = StatusRegister()
        m.cpu.d0 = 0b1010_1010
        
        m.cpu.execute(.andMR(.b, .imm(0x00), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }
    
    func testAndMRByteOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d0 = 0b1010_1010
        
        m.cpu.execute(.andMR(.b, .imm(0x0f), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
    
    func testAndMRWord() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa
        
        m.cpu.execute(.andMR(.w, .imm(0x0f0f), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0a0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }

    func testAndMRWordNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa
        
        m.cpu.execute(.andMR(.w, .imm(0xf0f0), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xa0a0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }
    
    func testAndMRWordZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa
        
        m.cpu.execute(.andMR(.w, .imm(0x0), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }
    
    func testAndMRWordOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d0 = 0xaaaa
        
        m.cpu.execute(.andMR(.w, .imm(0x0f0f), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0a0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
    

    func testAndMRLong() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa_aaaa
        
        m.cpu.execute(.andMR(.l, .imm(0x0f0f_0f0f), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0a0a_0a0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }

    func testAndMRLongNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa_aaaa
        
        m.cpu.execute(.andMR(.l, .imm(Int32(bitPattern: 0xf0f0_f0f0)), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xa0a0_a0a0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }
    
    func testAndMRLongZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa_aaaa
        
        m.cpu.execute(.andMR(.l, .imm(0x0), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }
    
    func testAndMRLongOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d0 = 0xaaaa_aaaa
        
        m.cpu.execute(.andMR(.l, .imm(0x0f0f_0f0f), .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0a0a_0a0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
    
    func testAndRMByte() throws {
        m.cpu.ccr = []
        
        m.cpu.a0 = 0x2
        m.cpu.write8(0x2, value: 0xaa)
        
        m.cpu.d0 = 0xff0f
        
        m.cpu.execute(.andRM(.b, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read8(0x2), 0x0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testAndRMByteNegative() throws {
        m.cpu.ccr = []
        
        m.cpu.a0 = 0x2
        m.cpu.write8(0x2, value: 0xaa)
        
        m.cpu.d0 = 0xfff0
        
        m.cpu.execute(.andRM(.b, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read8(0x2), 0xa0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }
    
    func testAndRMByteZero() throws {
        m.cpu.ccr = []
        
        m.cpu.a0 = 0x2
        m.cpu.write8(0x2, value: 0xaa)
        
        m.cpu.d0 = 0xff00
        
        m.cpu.execute(.andRM(.b, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read8(0x2), 0x00)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }

    func testAndRMByteOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]
        
        m.cpu.a0 = 0x2
        m.cpu.write8(0x2, value: 0xaa)
        
        m.cpu.d0 = 0xff0f
        
        m.cpu.execute(.andRM(.b, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read8(0x2), 0x0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
    
    
    func testAndRMWord() throws {
        m.cpu.ccr = []
        
        m.cpu.a0 = 0x2
        m.cpu.write16(0x2, value: 0xaaaa)
        
        m.cpu.d0 = 0xffff_0f0f
        
        m.cpu.execute(.andRM(.w, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read16(0x2), 0x0a0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testAndRMWordNegative() throws {
        m.cpu.ccr = []
        
        m.cpu.a0 = 0x2
        m.cpu.write16(0x2, value: 0xaaaa)
        
        m.cpu.d0 = 0xffff_f0f0
        
        m.cpu.execute(.andRM(.w, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read16(0x2), 0xa0a0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }
    
    func testAndRMWordZero() throws {
        m.cpu.ccr = []
        
        m.cpu.a0 = 0x2
        m.cpu.write16(0x2, value: 0xaaaa)
        
        m.cpu.d0 = 0xffff_0000
        
        m.cpu.execute(.andRM(.w, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read16(0x2), 0x0000)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }

    func testAndRMWordOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]
        
        m.cpu.a0 = 0x2
        m.cpu.write16(0x2, value: 0xaaaa)
        
        m.cpu.d0 = 0xffff_0f0f
        
        m.cpu.execute(.andRM(.w, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read16(0x2), 0x0a0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
    
    func testAndRMLong() throws {
        m.cpu.ccr = []
        
        m.cpu.a0 = 0x2
        m.cpu.write32(0x2, value: 0xaaaa_aaaa)
        
        m.cpu.d0 = 0x0f0f_0f0f
        
        m.cpu.execute(.andRM(.l, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read32(0x2), 0x0a0a_0a0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testAndRMLongNegative() throws {
        m.cpu.ccr = []
        
        m.cpu.a0 = 0x2
        m.cpu.write32(0x2, value: 0xaaaa_aaaa)
        
        m.cpu.d0 = 0xf0f0_f0f0
        
        m.cpu.execute(.andRM(.l, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read32(0x2), 0xa0a0_a0a0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }
    
    func testAndRMLongZero() throws {
        m.cpu.ccr = []
        
        m.cpu.a0 = 0x2
        m.cpu.write32(0x2, value: 0xaaaa_aaaa)
        
        m.cpu.d0 = 0x0000_0000
        
        m.cpu.execute(.andRM(.l, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read32(0x2), 0x0000_0000)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }

    func testAndRMLongOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]
        
        m.cpu.a0 = 0x2
        m.cpu.write32(0x2, value: 0xaaaa_aaaa)
        
        m.cpu.d0 = 0x0f0f_0f0f
        
        m.cpu.execute(.andRM(.l, .d0, .ind(.a0)), length: 0)
        
        XCTAssertEqual(m.cpu.read32(0x2), 0x0a0a_0a0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
}
