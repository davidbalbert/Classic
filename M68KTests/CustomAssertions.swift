//
//  CustomAssertions.wift.swift
//  M68KTests
//
//  Created by David Albert on 9/7/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

func assertCPUException(_ oldCpu: CPU, _ newCpu: CPU, vector: ExceptionVector, file: StaticString = #file, line: UInt = #line) {
    
    assertCPUException(oldCpu, newCpu, vector: vector.rawValue, file: file, line: line)
}

func assertCPUException(_ oldCpu: CPU, _ newCpu: CPU, vector: UInt8, file: StaticString = #file, line: UInt = #line) {

    XCTAssertFalse(newCpu.t0, "Expected t0 to be false", file: file, line: line)
    XCTAssertTrue(newCpu.s, "Expected s to be true", file: file, line: line)

    let vaddr = UInt32(vector) << 2
    
    let expectedPc = newCpu.read32(vaddr)
    
    XCTAssertEqual(newCpu.pc, expectedPc, "Expected pc to be \(String(expectedPc, radix: 16)), not \(String(newCpu.pc, radix: 16))", file: file, line: line)
    XCTAssertEqual(newCpu.isp, oldCpu.isp - 6, "Expected isp to be 6 lower the its original value (new isp: \(String(newCpu.isp, radix: 16))) (old isp: \(String(oldCpu.isp, radix: 16)))", file: file, line: line)
    
    XCTAssertEqual(newCpu.read32(newCpu.isp+2), oldCpu.pc, "Expected old PC to be on the stack")
    XCTAssertEqual(newCpu.read16(newCpu.isp), oldCpu.sr.rawValue, "Expected old SR to be on the stack")
}
