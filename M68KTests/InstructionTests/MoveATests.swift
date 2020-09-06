//
//  MoveATests.swift
//  M68KTests
//
//  Created by David Albert on 9/6/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class MoveATests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        MoveATests.m
    }
    
    func testMoveAWord() throws {
        m.cpu.d0 = 0xaaaa_7afe
        m.cpu.a0 = 0
        
        m.cpu.execute(.movea(.w, .dd(.d0), .a0), length: 0)
        
        XCTAssertEqual(m.cpu.a0, 0x0000_7afe)
    }
    
    func testMoveAWordSignExtend() throws {
        m.cpu.d0 = 0xaaaa_cafe
        m.cpu.a0 = 0
        
        m.cpu.execute(.movea(.w, .dd(.d0), .a0), length: 0)
        
        XCTAssertEqual(m.cpu.a0, 0xffff_cafe)
    }
    
    func testMoveALong() throws {
        m.cpu.d0 = 0xaaaa_7afe
        m.cpu.a0 = 0
        
        m.cpu.execute(.movea(.l, .dd(.d0), .a0), length: 0)
        
        XCTAssertEqual(m.cpu.a0, 0xaaaa_7afe)
    }
}
