//
//  SubaTests.swift
//  M68KTests
//
//  Created by David Albert on 9/9/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class SubaTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        SubaTests.m
    }
    
    func testSubaWord() throws {
        m.cpu.a0 = 0xffff_ffff
        m.cpu.d0 = 0x0000_7afe
        
        m.cpu.execute(.suba(.w, .dd(.d0), .a0), length: 0)
        
        XCTAssertEqual(m.cpu.a0, 0xffff_8501)
    }
    
    func testSubaWordSignExtend() throws {
        m.cpu.a0 = 0xffff_ffff
        m.cpu.d0 = 0x0000_cafe
        
        m.cpu.execute(.suba(.w, .dd(.d0), .a0), length: 0)
        
        XCTAssertEqual(m.cpu.a0, 0x0000_3501)
    }
    
    func testSubaLong() throws {
        m.cpu.a0 = 0xffff_ffff
        m.cpu.d0 = 0x1234_5678
        
        m.cpu.execute(.suba(.l, .dd(.d0), .a0), length: 0)
        
        XCTAssertEqual(m.cpu.a0, 0xedcb_a987)
    }
}
