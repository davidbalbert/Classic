//
//  LeaTests.swift
//  M68KTests
//
//  Created by David Albert on 9/3/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class LeaTests: XCTestCase {
    private static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        LeaTests.m
    }
    
    func testLea() throws {
        m.cpu.a0 = 0
        m.cpu.a1 = 0x80
        
        m.cpu.execute(.lea(.d16An(0x20, .a1), .a0), length: 0)
        
        XCTAssertEqual(m.cpu.a0, 0xa0)
    }
}
