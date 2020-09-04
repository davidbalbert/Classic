//
//  MoveMTests.swift
//  M68KTests
//
//  Created by David Albert on 9/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class MoveMTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        MoveMTests.m
    }
    
    func testMovemRMWordControl() throws {
        m.cpu.write32(0, value: 0)
        m.cpu.write32(4, value: 0)
        
        m.cpu.d0 = 0xffff_aaaa
        m.cpu.d1 = 0xffff_bbbb
        m.cpu.a0 = 0xffff_cccc
        m.cpu.a1 = 0xffff_dddd
        
        m.cpu.a6 = 0
        
        m.cpu.execute(.movemRM(.w, [.d0, .d1, .a0, .a1], .c(.ind(.a6))), length: 0)
        
        XCTAssertEqual(m.ram, Data([0xaa, 0xaa, 0xbb, 0xbb, 0xcc, 0xcc, 0xdd, 0xdd]))
    }
    
    func testMovemRMWordPreDec() throws {
        m.cpu.write32(0, value: 0)
        m.cpu.write32(4, value: 0)

        m.cpu.d0 = 0xffff_aaaa
        m.cpu.d1 = 0xffff_bbbb
        m.cpu.a0 = 0xffff_cccc
        m.cpu.a1 = 0xffff_dddd

        m.cpu.a6 = 8
        
        m.cpu.execute(.movemRM(.w, [.d0, .d1, .a0, .a1], .preDec(.a6)), length: 0)
        
        XCTAssertEqual(m.ram, Data([0xaa, 0xaa, 0xbb, 0xbb, 0xcc, 0xcc, 0xdd, 0xdd]))
        XCTAssertEqual(m.cpu.a6, 0)
    }
    
    func testMoveRMWordPreDecStoreAddressRegister() throws {
        m.cpu.write32(0, value: 0)
        m.cpu.write32(4, value: 0)
        
        m.cpu.d0 = 0xffff_aaaa
        m.cpu.d1 = 0xffff_bbbb
        m.cpu.a0 = 0x0000_0008
        m.cpu.a1 = 0xffff_dddd
        
        m.cpu.execute(.movemRM(.w, [.d0, .d1, .a0, .a1], .preDec(.a0)), length: 0)
        
        XCTAssertEqual(m.ram, Data([0xaa, 0xaa, 0xbb, 0xbb, 0x00, 0x08, 0xdd, 0xdd]))
    }
    
    func testMovemRMLongControl() throws {
        m.cpu.write32(0, value: 0)
        m.cpu.write32(4, value: 0)
        
        m.cpu.d0 = 0xaaaa_bbbb
        m.cpu.a0 = 0xcccc_dddd
        
        m.cpu.a6 = 0
        
        m.cpu.execute(.movemRM(.l, [.d0, .a0], .c(.ind(.a6))), length: 0)
        
        XCTAssertEqual(m.ram, Data([0xaa, 0xaa, 0xbb, 0xbb, 0xcc, 0xcc, 0xdd, 0xdd]))
    }
    
    func testMovemRMLongPreDec() throws {
        m.cpu.write32(0, value: 0)
        m.cpu.write32(4, value: 0)

        m.cpu.d0 = 0xaaaa_bbbb
        m.cpu.a0 = 0xcccc_dddd

        m.cpu.a6 = 8
        
        m.cpu.execute(.movemRM(.l, [.d0, .a0], .preDec(.a6)), length: 0)
        
        XCTAssertEqual(m.ram, Data([0xaa, 0xaa, 0xbb, 0xbb, 0xcc, 0xcc, 0xdd, 0xdd]))
        XCTAssertEqual(m.cpu.a6, 0)
    }
    
    func testMoveRMLongPreDecStoreAddressRegister() throws {
        m.cpu.write32(0, value: 0)
        m.cpu.write32(4, value: 0)
        
        m.cpu.d0 = 0xaaaa_bbbb
        m.cpu.a0 = 0x0000_0008

        m.cpu.execute(.movemRM(.l, [.d0, .a0], .preDec(.a0)), length: 0)

        XCTAssertEqual(m.ram, Data([0xaa, 0xaa, 0xbb, 0xbb, 0x00, 0x00, 0x00, 0x08]))
    }

    
    // TODO: MoveA tests

}
