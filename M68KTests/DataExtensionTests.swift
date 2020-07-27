//
//  DataExtensionTests.swift
//  M68KTests
//
//  Created by David Albert on 7/26/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class DataExtensionTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRead8() throws {
        let data = Data([0x10, 0x20, 0x30, 0x40])
        
        XCTAssertEqual(0x10, data.read8(0))
        XCTAssertEqual(0x20, data.read8(1))
        XCTAssertEqual(0x30, data.read8(2))
        XCTAssertEqual(0x40, data.read8(3))
    }
    
    func testRead16() throws {
        let data = Data([0x10, 0x20, 0x30, 0x40])
        
        XCTAssertEqual(0x1020, data.read16(0))
        XCTAssertEqual(0x2030, data.read16(1))
        XCTAssertEqual(0x3040, data.read16(2))
    }
    
    func testRead32() throws {
        let data = Data([0x10, 0x20, 0x30, 0x40, 0x50, 0x60, 0x70, 0x80])
        
        XCTAssertEqual(0x10203040, data.read32(0))
        XCTAssertEqual(0x20304050, data.read32(1))
        XCTAssertEqual(0x30405060, data.read32(2))
    }

    func testWrite8() throws {
        var data = Data([0x10, 0x20, 0x30, 0x40])
        
        data.write8(0, value: 0xff)
        XCTAssertEqual(Data([0xff, 0x20, 0x30, 0x40]), data)
        
        data.write8(1, value: 0xff)
        XCTAssertEqual(Data([0xff, 0xff, 0x30, 0x40]), data)
        
        data.write8(2, value: 0xff)
        XCTAssertEqual(Data([0xff, 0xff, 0xff, 0x40]), data)

        data.write8(3, value: 0xff)
        XCTAssertEqual(Data([0xff, 0xff, 0xff, 0xff]), data)
    }
    
    func testWrite16() throws {
        var data = Data([0x10, 0x20, 0x30, 0x40])

        data.write16(1, value: 0xcafe)
        XCTAssertEqual(Data([0x10, 0xca, 0xfe, 0x40]), data)
    }
    
    func testWrite32() throws {
        var data = Data([0x00, 0x10, 0x20, 0x30, 0x40, 0xff])

        data.write32(1, value: 0xdeadbeef)
        XCTAssertEqual(Data([0x00, 0xde, 0xad, 0xbe, 0xef, 0xff]), data)
    }
}
