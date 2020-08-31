//
//  BccTests.swift
//  M68KTests
//
//  Created by David Albert on 8/30/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

// Most condition codes are tested in ConditionCodeTests
class BccTests: XCTestCase {
    static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        BccTests.m
    }
    
    func testBccTrue() throws {
        m.cpu.pc = 0
        m.cpu.ccr = .c
        
        m.cpu.execute(.bcc(.b, .cs, m.cpu.pc+2, 8), length: 2)
        
        XCTAssertEqual(m.cpu.pc, 10)
    }
    
    func testBccFalse() throws {
        m.cpu.pc = 0
        m.cpu.ccr = .c
        
        m.cpu.execute(.bcc(.b, .cc, m.cpu.pc+2, 8), length: 2)
        
        XCTAssertEqual(m.cpu.pc, 2)
    }
}
