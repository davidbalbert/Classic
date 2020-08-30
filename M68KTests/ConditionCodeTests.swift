//
//  ConditionCodeTests.swift
//  M68KTests
//
//  Created by David Albert on 8/9/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class ConditionCodeTests: XCTestCase {
    static let m = TestMachine([])
    
    override class func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        ConditionCodeTests.m
    }

    func testEq() throws {
        m.cpu.d0 = 5
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.eq))
    }
    
    func testNe() throws {
        m.cpu.d0 = 5
        let op = Operation.cmpi(.b, 6, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.ne))
    }
    
    func testMi() throws {
        m.cpu.d0 = 5
        let op = Operation.cmpi(.b, 6, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.mi))
        XCTAssert(!m.cpu.conditionIsSatisfied(.pl))
    }

    func testPl() throws {
        m.cpu.d0 = 6
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.pl))
        XCTAssert(!m.cpu.conditionIsSatisfied(.mi))
    }
    
    func testGt() throws {
        m.cpu.d0 = 6
        var op = Operation.cmpi(.b, 5, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.gt))
        XCTAssert(!m.cpu.conditionIsSatisfied(.le))
        
        m.cpu.d0 = UInt32(bitPattern: -5)
        op = Operation.cmpi(.b, -6, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.gt))
        XCTAssert(!m.cpu.conditionIsSatisfied(.le))
    }
    
    func testLt() throws {
        m.cpu.d0 = 4
        var op = Operation.cmpi(.b, 5, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.lt))
        XCTAssert(!m.cpu.conditionIsSatisfied(.ge))
        
        m.cpu.d0 = UInt32(bitPattern: -6)
        op = Operation.cmpi(.b, -5, .dd(.d0))
        m.cpu.execute(op, length: 0)

        XCTAssert(m.cpu.conditionIsSatisfied(.lt))
        XCTAssert(!m.cpu.conditionIsSatisfied(.ge))
    }
    
    func testGe() throws {
        m.cpu.d0 = UInt32(bitPattern: -4)
        let op = Operation.cmpi(.b, -5, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.ge))
        
        m.cpu.d0 = UInt32(bitPattern: -5)
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.ge))
    }
    
    func testLe() throws {
        m.cpu.d0 = UInt32(bitPattern: -5)
        let op = Operation.cmpi(.b, -4, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.le))
        
        m.cpu.d0 = UInt32(bitPattern: -5)
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.le))
    }
    
    func testHi() throws {
        m.cpu.d0 = 5
        
        let op = Operation.cmpi(.b, 4, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.hi))
        XCTAssert(!m.cpu.conditionIsSatisfied(.ls))
    }
    
    func testLs() throws {
        m.cpu.d0 = 4
        
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.ls))
        XCTAssert(!m.cpu.conditionIsSatisfied(.hi))
        
        m.cpu.d0 = 5
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.ls))
        XCTAssert(!m.cpu.conditionIsSatisfied(.hi))
    }
    
    func testCs() throws {
        m.cpu.d0 = 4
        
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        m.cpu.execute(op, length: 0)

        XCTAssert(m.cpu.conditionIsSatisfied(.cs))
        XCTAssert(!m.cpu.conditionIsSatisfied(.cc))
    }
    
    func testCc() throws {
        m.cpu.d0 = 5
        
        let op = Operation.cmpi(.b, 4, .dd(.d0))
        m.cpu.execute(op, length: 0)

        XCTAssert(m.cpu.conditionIsSatisfied(.cc))
        XCTAssert(!m.cpu.conditionIsSatisfied(.cs))
    }
    
    func testVs() throws {
        m.cpu.d0 = 127
        
        let op = Operation.cmpi(.b, -1, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.vs))
        XCTAssert(!m.cpu.conditionIsSatisfied(.vc))
    }
    
    func testVc() throws {
        m.cpu.d0 = 0
        
        let op = Operation.cmpi(.b, -1, .dd(.d0))
        m.cpu.execute(op, length: 0)
        
        XCTAssert(m.cpu.conditionIsSatisfied(.vc))
        XCTAssert(!m.cpu.conditionIsSatisfied(.vs))
    }
    
    func testTf() throws {
        m.cpu.d0 = UInt32.random(in: 0...UInt32.max)
        
        let op = Operation.cmpi(.b, Int32.random(in: Int32.min...Int32.max), .dd(.d0))
        m.cpu.execute(op, length: 0)

        XCTAssert(m.cpu.conditionIsSatisfied(.t))
        XCTAssert(!m.cpu.conditionIsSatisfied(.f))
    }
}
