//
//  DbccTests.swift
//  M68KTests
//
//  Created by David Albert on 9/2/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class DbccTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        DbccTests.m
    }
    
    func testDbccTerminationCondition() throws {
        m.cpu.pc = 10
        m.cpu.ccr = .c
        m.cpu.d0 = 5
        
        m.cpu.execute(.dbcc(.cs, .d0, m.cpu.pc+2, -10), length: 2)
        
        XCTAssertEqual(m.cpu.pc, 12)
        XCTAssertEqual(m.cpu.d0, 5)
    }
    
    func testDbccNonZero() throws {
        m.cpu.pc = 10
        m.cpu.ccr = []
        m.cpu.d0 = 5
        
        m.cpu.execute(.dbcc(.cs, .d0, m.cpu.pc+2, -10), length: 2)
        
        XCTAssertEqual(m.cpu.pc, 2)
        XCTAssertEqual(m.cpu.d0, 4)
    }
    
    func testDbccCountNegative() throws {
        m.cpu.pc = 10
        m.cpu.ccr = []
        m.cpu.d0 = 0
        
        m.cpu.execute(.dbcc(.cs, .d0, m.cpu.pc+2, -10), length: 2)
        
        XCTAssertEqual(m.cpu.pc, 12)
        XCTAssertEqual(m.cpu.d0, 0x0000_ffff)
    }
    
    func testDbccOnlyUsesWord() throws {
        m.cpu.pc = 10
        m.cpu.ccr = []
        m.cpu.d0 = 0xcafe_0000
        
        m.cpu.execute(.dbcc(.cs, .d0, m.cpu.pc+2, -10), length: 2)
        
        XCTAssertEqual(m.cpu.pc, 12)
        XCTAssertEqual(m.cpu.d0, 0xcafe_ffff)
    }
}
