//
//  JmpTests.swift
//  M68KTests
//
//  Created by David Albert on 9/2/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class JmpTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        JmpTests.m
    }
    
    func testJmp() throws {
        m.cpu.pc = 10
        m.cpu.execute(.jmp(.XXXl(0xca_fe10)), length: 0)
        
        XCTAssertEqual(m.cpu.pc, 0xca_fe10)
    }
}
