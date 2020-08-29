//
//  ConditionCodeTests.swift
//  M68KTests
//
//  Created by David Albert on 8/9/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class CPUWrapper {
    var cpu = CPU()
}

class ConditionCodeTests: XCTestCase {
    static let machine = TestMachine([])
    static let w = CPUWrapper()
    
    override class func setUp() {
        w.cpu.bus = machine
    }
    
    var w: CPUWrapper {
        ConditionCodeTests.w
    }

    func testEq() throws {
        w.cpu.d0 = 5
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.eq))
    }
    
    func testNe() throws {
        w.cpu.d0 = 5
        let op = Operation.cmpi(.b, 6, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.ne))
    }
    
    func testMi() throws {
        w.cpu.d0 = 5
        let op = Operation.cmpi(.b, 6, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.mi))
        XCTAssert(!w.cpu.conditionIsSatisfied(.pl))
    }

    func testPl() throws {
        w.cpu.d0 = 6
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.pl))
        XCTAssert(!w.cpu.conditionIsSatisfied(.mi))
    }
    
    func testGt() throws {
        w.cpu.d0 = 6
        var op = Operation.cmpi(.b, 5, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.gt))
        XCTAssert(!w.cpu.conditionIsSatisfied(.le))
        
        w.cpu.d0 = UInt32(bitPattern: -5)
        op = Operation.cmpi(.b, -6, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.gt))
        XCTAssert(!w.cpu.conditionIsSatisfied(.le))
    }
    
    func testLt() throws {
        w.cpu.d0 = 4
        var op = Operation.cmpi(.b, 5, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.lt))
        XCTAssert(!w.cpu.conditionIsSatisfied(.ge))
        
        w.cpu.d0 = UInt32(bitPattern: -6)
        op = Operation.cmpi(.b, -5, .dd(.d0))
        w.cpu.execute(op, length: 0)

        XCTAssert(w.cpu.conditionIsSatisfied(.lt))
        XCTAssert(!w.cpu.conditionIsSatisfied(.ge))
    }
    
    func testGe() throws {
        w.cpu.d0 = UInt32(bitPattern: -4)
        let op = Operation.cmpi(.b, -5, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.ge))
        
        w.cpu.d0 = UInt32(bitPattern: -5)
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.ge))
    }
    
    func testLe() throws {
        w.cpu.d0 = UInt32(bitPattern: -5)
        let op = Operation.cmpi(.b, -4, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.le))
        
        w.cpu.d0 = UInt32(bitPattern: -5)
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.le))
    }
    
    func testHi() throws {
        w.cpu.d0 = 5
        
        let op = Operation.cmpi(.b, 4, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.hi))
        XCTAssert(!w.cpu.conditionIsSatisfied(.ls))
    }
    
    func testLs() throws {
        w.cpu.d0 = 4
        
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.ls))
        XCTAssert(!w.cpu.conditionIsSatisfied(.hi))
        
        w.cpu.d0 = 5
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.ls))
        XCTAssert(!w.cpu.conditionIsSatisfied(.hi))
    }
    
    func testCs() throws {
        w.cpu.d0 = 4
        
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        w.cpu.execute(op, length: 0)

        XCTAssert(w.cpu.conditionIsSatisfied(.cs))
        XCTAssert(!w.cpu.conditionIsSatisfied(.cc))
    }
    
    func testCc() throws {
        w.cpu.d0 = 5
        
        let op = Operation.cmpi(.b, 4, .dd(.d0))
        w.cpu.execute(op, length: 0)

        XCTAssert(w.cpu.conditionIsSatisfied(.cc))
        XCTAssert(!w.cpu.conditionIsSatisfied(.cs))
    }
    
    func testVs() throws {
        w.cpu.d0 = 127
        
        let op = Operation.cmpi(.b, -1, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.vs))
        XCTAssert(!w.cpu.conditionIsSatisfied(.vc))
    }
    
    func testVc() throws {
        w.cpu.d0 = 0
        
        let op = Operation.cmpi(.b, -1, .dd(.d0))
        w.cpu.execute(op, length: 0)
        
        XCTAssert(w.cpu.conditionIsSatisfied(.vc))
        XCTAssert(!w.cpu.conditionIsSatisfied(.vs))
    }
    
    func testTf() throws {
        w.cpu.d0 = UInt32.random(in: 0...UInt32.max)
        
        let op = Operation.cmpi(.b, Int32.random(in: Int32.min...Int32.max), .dd(.d0))
        w.cpu.execute(op, length: 0)

        XCTAssert(w.cpu.conditionIsSatisfied(.t))
        XCTAssert(!w.cpu.conditionIsSatisfied(.f))
    }
}
