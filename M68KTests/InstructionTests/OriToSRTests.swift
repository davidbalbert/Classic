//
//  OriToSRTests.swift
//  M68KTests
//
//  Created by David Albert on 9/7/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class OriToSRTests: XCTestCase {
    private static var m = TestMachine(Array(repeating: 0, count: 2048))
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        OriToSRTests.m
    }
    
    func testSupervisorMode() throws {
        m.cpu.sr = [.s, .c, .v]
            
        let tmp: StatusRegister = [.t0, .n, .z]
        
        m.cpu.execute(.oriToSR(tmp.rawValue), length: 0)
        
        XCTAssertEqual(m.cpu.sr, [.s, .c, .v, .t0, .n, .z])
    }
    
    func testUserModeTraps() throws {
        m.cpu.sr = [.c, .v, .t0]
        
        m.cpu.d0 = UInt32(StatusRegister.all.rawValue)
        m.cpu.isp = 2048
        
        m.cpu.pc = 0x1000_0000
        m.write32(ExceptionVector.privilegeViolation.address, value: 0xcafe_beef)
        
        let tmp: StatusRegister = [.n, .z]

        let oldCpu = m.cpu
        m.cpu.execute(.oriToSR(tmp.rawValue), length: 0)
        
        assertCPUException(oldCpu, m.cpu, vector: .privilegeViolation)
    }
}
