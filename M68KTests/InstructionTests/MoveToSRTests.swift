//
//  MoveToSRTests.swift
//  M68KTests
//
//  Created by David Albert on 9/6/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class MoveToSRTests: XCTestCase {
    private static var m = TestMachine(Array(repeating: 0, count: 2048))
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        MoveToSRTests.m
    }
    
    func testSupervisorMode() throws {
        m.cpu.sr = []
        m.cpu.d0 = UInt32(StatusRegister.all.rawValue)
        
        m.cpu.execute(.moveToSR(.dd(.d0)), length: 0)
        
        XCTAssertEqual(m.cpu.sr, .all)
        XCTAssertEqual(m.cpu.ccr, StatusRegister.all.intersection(.ccr))
    }
    
    func testUserModeTraps() throws {
        m.cpu.sr = [.x, .c, .v, .t0]
        m.cpu.d0 = UInt32(StatusRegister.all.rawValue)
        
        // exception setup
        m.cpu.pc = 0
        m.cpu.isp = 2048
        m.write32(ExceptionVector.privilegeViolation.address, value: 0xcafe_beef)
        
        let oldCpu = m.cpu
        m.cpu.execute(.moveToSR(.dd(.d0)), length: 0)
        
        assertCPUException(oldCpu, m.cpu, vector: .privilegeViolation)
    }
}
