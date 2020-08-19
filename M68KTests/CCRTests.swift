//
//  CCRTests.swift
//  M68KTests
//
//  Created by David Albert on 8/18/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class CCRTests: XCTestCase {
    var cpu = CPU()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCCR() throws {
        cpu.sr = []
        
        XCTAssertEqual(cpu.ccr, [])
        
        cpu.ccr = [.n, .v, .z]
        
        XCTAssertEqual(cpu.sr, [.n, .v, .z])
        XCTAssertEqual(cpu.ccr, [.n, .v, .z])
        
        cpu.sr = .s
        cpu.ccr = .z
        
        XCTAssertEqual(cpu.sr, [.s, .z])
        XCTAssertEqual(cpu.ccr, .z)
    }
}
