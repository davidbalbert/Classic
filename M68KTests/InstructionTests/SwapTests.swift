//
//  SwapTests.swift
//  M68KTests
//
//  Created by David Albert on 9/14/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class SwapTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        SwapTests.m
    }
    
    func testSwap() throws {
        m.cpu.ccr = [.x, .n, .z, .v, .c]
        m.cpu.d0 = 0x1000_2000
        
        m.cpu.execute(.swap(.d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x2000_1000)
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testSwapZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x0000_0000
        
        m.cpu.execute(.swap(.d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0x0000_0000)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
    
    func testSwapNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0x7afe_cafe
        
        m.cpu.execute(.swap(.d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xcafe_7afe)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
}
