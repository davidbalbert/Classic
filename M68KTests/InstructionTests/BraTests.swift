//
//  BraTests.swift
//  M68KTests
//
//  Created by David Albert on 8/30/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class BraTests: XCTestCase {
    static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        BraTests.m
    }
    
    func testBra() throws {
        m.cpu.pc = 10
        
        m.cpu.execute(.bra(.b, m.cpu.pc+2, 2), length: 0)
        
        XCTAssertEqual(m.cpu.pc, 14)
    }
}
