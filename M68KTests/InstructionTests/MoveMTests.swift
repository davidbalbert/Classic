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
        
        m.cpu.d0 = 0xaaaa
        m.cpu.d1 = 0xbbbb
        m.cpu.a0 = 0xcccc
        m.cpu.a1 = 0xdddd
        
        m.cpu.a6 = 0
        
        m.cpu.execute(.movemRM(.w, [.d0, .d1, .a0, .a1], .c(.ind(.a6))), length: 0)
        
        XCTAssertEqual(m.ram, Data([0xaa, 0xaa, 0xbb, 0xbb, 0xcc, 0xcc, 0xdd, 0xdd]))
    }
    
    func testMovemRMWordPreDec() throws {
        m.cpu.write32(0, value: 0)
        m.cpu.write32(4, value: 0)

        m.cpu.d0 = 0xaaaa
        m.cpu.d1 = 0xbbbb
        m.cpu.a0 = 0xcccc
        m.cpu.a1 = 0xdddd
        
        m.cpu.a6 = 8
        
        m.cpu.execute(.movemRM(.w, [.d0, .d1, .a0, .a1], .preDec(.a6)), length: 0)
        
        XCTAssertEqual(m.ram, Data([0xaa, 0xaa, 0xbb, 0xbb, 0xcc, 0xcc, 0xdd, 0xdd]))
        XCTAssertEqual(m.cpu.a6, 0)
    }
}
