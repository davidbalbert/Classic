//
//  MoveQTests.swift
//  M68KTests
//
//  Created by David Albert on 9/6/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class MoveQTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        MoveQTests.m
    }
    
    func testMoveQ() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d0 = 0
        
        m.cpu.execute(.moveq(127, .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 127)
        XCTAssertEqual(m.cpu.ccr, .x)
    }
    
    func testMoveQNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0
        
        m.cpu.execute(.moveq(-128, .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0xffff_ff80)
        XCTAssertEqual(m.cpu.ccr, .n)
    }
    
    func testMoveQZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xffff_ffff
        
        m.cpu.execute(.moveq(0, .d0), length: 0)
        
        XCTAssertEqual(m.cpu.d0, 0)
        XCTAssertEqual(m.cpu.ccr, .z)
    }
}
