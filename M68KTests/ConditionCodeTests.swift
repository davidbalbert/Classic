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
    let machine = TestMachine([])
    var cpu = CPU()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        cpu.bus = machine
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEq() throws {
        cpu.d0 = 5
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.eq))
    }
    
    func testNe() throws {
        cpu.d0 = 5
        let op = Operation.cmpi(.b, 6, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.ne))
    }
    
    func testMi() throws {
        cpu.d0 = 5
        let op = Operation.cmpi(.b, 6, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.mi))
        XCTAssert(!cpu.conditionIsSatisfied(.pl))
    }

    func testPl() throws {
        cpu.d0 = 6
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.pl))
        XCTAssert(!cpu.conditionIsSatisfied(.mi))
    }
    
    func testGt() throws {
        cpu.d0 = 6
        var op = Operation.cmpi(.b, 5, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.gt))
        XCTAssert(!cpu.conditionIsSatisfied(.le))
        
        cpu.d0 = UInt32(bitPattern: -5)
        op = Operation.cmpi(.b, -6, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.gt))
        XCTAssert(!cpu.conditionIsSatisfied(.le))
    }
    
    func testLt() throws {
        cpu.d0 = 4
        var op = Operation.cmpi(.b, 5, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.lt))
        XCTAssert(!cpu.conditionIsSatisfied(.ge))
        
        cpu.d0 = UInt32(bitPattern: -6)
        op = Operation.cmpi(.b, -5, .dd(.d0))
        cpu.execute(op, length: 0)

        XCTAssert(cpu.conditionIsSatisfied(.lt))
        XCTAssert(!cpu.conditionIsSatisfied(.ge))
    }
    
    func testGe() throws {
        cpu.d0 = UInt32(bitPattern: -4)
        let op = Operation.cmpi(.b, -5, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.ge))
        
        cpu.d0 = UInt32(bitPattern: -5)
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.ge))
    }
    
    func testLe() throws {
        cpu.d0 = UInt32(bitPattern: -5)
        let op = Operation.cmpi(.b, -4, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.le))
        
        cpu.d0 = UInt32(bitPattern: -5)
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.le))
    }
    
    func testHi() throws {
        cpu.d0 = 5
        
        let op = Operation.cmpi(.b, 4, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.hi))
        XCTAssert(!cpu.conditionIsSatisfied(.ls))
    }
    
    func testLs() throws {
        cpu.d0 = 4
        
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.ls))
        XCTAssert(!cpu.conditionIsSatisfied(.hi))
        
        cpu.d0 = 5
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.ls))
        XCTAssert(!cpu.conditionIsSatisfied(.hi))
    }
    
    func testCs() throws {
        cpu.d0 = 4
        
        let op = Operation.cmpi(.b, 5, .dd(.d0))
        cpu.execute(op, length: 0)

        XCTAssert(cpu.conditionIsSatisfied(.cs))
        XCTAssert(!cpu.conditionIsSatisfied(.cc))
    }
    
    func testCc() throws {
        cpu.d0 = 5
        
        let op = Operation.cmpi(.b, 4, .dd(.d0))
        cpu.execute(op, length: 0)

        XCTAssert(cpu.conditionIsSatisfied(.cc))
        XCTAssert(!cpu.conditionIsSatisfied(.cs))
    }
    
    func testVs() throws {
        cpu.d0 = 127
        
        let op = Operation.cmpi(.b, -1, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.vs))
        XCTAssert(!cpu.conditionIsSatisfied(.vc))
    }
    
    func testVc() throws {
        cpu.d0 = 0
        
        let op = Operation.cmpi(.b, -1, .dd(.d0))
        cpu.execute(op, length: 0)
        
        XCTAssert(cpu.conditionIsSatisfied(.vc))
        XCTAssert(!cpu.conditionIsSatisfied(.vs))
    }
    
    func testTf() throws {
        cpu.d0 = UInt32.random(in: 0...UInt32.max)
        
        let op = Operation.cmpi(.b, Int32.random(in: Int32.min...Int32.max), .dd(.d0))
        cpu.execute(op, length: 0)

        XCTAssert(cpu.conditionIsSatisfied(.t))
        XCTAssert(!cpu.conditionIsSatisfied(.f))
    }
}
