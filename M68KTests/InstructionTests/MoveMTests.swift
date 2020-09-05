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
    
    func testMovemMRWordControl() throws {
        m.cpu.write16(0, value: 0x1111)
        m.cpu.write16(2, value: 0xaaaa)
        m.cpu.write16(4, value: 0x2222)
        m.cpu.write16(6, value: 0xbbbb)
        
        m.cpu.d0 = 0xffff_ffff
        m.cpu.d1 = 0x0000_ffff
        m.cpu.a0 = 0xffff_ffff
        m.cpu.a1 = 0x0000_ffff

        m.cpu.a6 = 0
        
        m.cpu.execute(.movemMR(.w, .c(.ind(.a6)), [.d0, .d1, .a0, .a1]), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xffff_1111)
        XCTAssertEqual(m.cpu.d1, 0x0000_aaaa)
        XCTAssertEqual(m.cpu.a0, 0x0000_2222)
        XCTAssertEqual(m.cpu.a1, 0xffff_bbbb)
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
