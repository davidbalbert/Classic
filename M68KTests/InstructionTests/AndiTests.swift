//
//  AndiTests.swift
//  M68KTests
//
//  Created by David Albert on 8/30/20.
//  Copyright © 2020 David Albert. All rights reserved.
//

import XCTest
@testable import M68K

class AndiTests: XCTestCase {
    static var m = TestMachine([0, 0, 0, 0, 0, 0, 0, 0])
    
    override func setUp() {
        m.cpu.bus = m
    }
    
    var m: TestMachine {
        AndTests.m
    }

    func testAndiDdByte() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xffff_ffaa

        m.cpu.execute(.andi(.b, 0xff0f, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0xffff_ff0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }

    func testAndiDdByteNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaa

        m.cpu.execute(.andi(.b, 0xf0, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0xa0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }

    func testAndiDdByteZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaa

        m.cpu.execute(.andi(.b, 0x00, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0x00)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }

    func testAndiDdByteOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d0 = 0xaa

        m.cpu.execute(.andi(.b, 0x0f, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0x0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }


    func testAndiDdWord() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa

        m.cpu.execute(.andi(.w, 0x0f0f, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0x0a0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }

    func testAndiDdWordNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa

        m.cpu.execute(.andi(.w, 0xf0f0, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0xa0a0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }

    func testAndiDdWordZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa

        m.cpu.execute(.andi(.w, 0x0, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0x0)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }

    func testAndiDdWordOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d0 = 0xaaaa

        m.cpu.execute(.andi(.w, 0x0f0f, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0x0a0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }

    func testAndiDdLong() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa_aaaa

        m.cpu.execute(.andi(.l, 0x0f0f_0f0f, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0x0a0a_0a0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }

    func testAndiDdLongNegative() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa_aaaa

        m.cpu.execute(.andi(.l, Int32(bitPattern: 0xf0f0_f0f0), .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0xa0a0_a0a0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }

    func testAndiDdLongZero() throws {
        m.cpu.ccr = []
        m.cpu.d0 = 0xaaaa_aaaa

        m.cpu.execute(.andi(.l, 0x0, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0x0)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }

    func testAndiDdLongOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]
        m.cpu.d0 = 0xaaaa_aaaa

        m.cpu.execute(.andi(.l, 0x0f0f_0f0f, .dd(.d0)), length: 0)

        XCTAssertEqual(m.cpu.d0, 0x0a0a_0a0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
    
    func testAndiMemByte() throws {
        m.cpu.ccr = []
        
        m.cpu.a0 = 0x2
        m.cpu.write8(0x2, value: 0xaa)
                
        m.cpu.execute(.andi(.b, 0x0f, .m(.ind(.a0))), length: 0)
        
        XCTAssertEqual(m.cpu.read8(0x2), 0x0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }
    
    func testAndiMemByteNegative() throws {
        m.cpu.ccr = []

        m.cpu.a0 = 0x2
        m.cpu.write8(0x2, value: 0xaa)

        m.cpu.execute(.andi(.b, 0xf0, .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read8(0x2), 0xa0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }

    func testAndiMemByteZero() throws {
        m.cpu.ccr = []

        m.cpu.a0 = 0x2
        m.cpu.write8(0x2, value: 0xaa)

        m.cpu.execute(.andi(.b, 0x00, .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read8(0x2), 0x00)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }

    func testAndiMemByteOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]

        m.cpu.a0 = 0x2
        m.cpu.write8(0x2, value: 0xaa)

        m.cpu.execute(.andi(.b, 0x0f, .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read8(0x2), 0x0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }


    func testAndiMemWord() throws {
        m.cpu.ccr = []

        m.cpu.a0 = 0x2
        m.cpu.write16(0x2, value: 0xaaaa)

        m.cpu.execute(.andi(.w, 0x0f0f, .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read16(0x2), 0x0a0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }

    func testAndiMemWordNegative() throws {
        m.cpu.ccr = []

        m.cpu.a0 = 0x2
        m.cpu.write16(0x2, value: 0xaaaa)

        m.cpu.execute(.andi(.w, 0xf0f0, .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read16(0x2), 0xa0a0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }

    func testAndiMemWordZero() throws {
        m.cpu.ccr = []

        m.cpu.a0 = 0x2
        m.cpu.write16(0x2, value: 0xaaaa)

        m.cpu.execute(.andi(.w, 0x0000, .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read16(0x2), 0x0000)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }

    func testAndiMemWordOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]

        m.cpu.a0 = 0x2
        m.cpu.write16(0x2, value: 0xaaaa)

        m.cpu.execute(.andi(.w, 0x0f0f, .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read16(0x2), 0x0a0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }

    func testAndiMemLong() throws {
        m.cpu.ccr = []

        m.cpu.a0 = 0x2
        m.cpu.write32(0x2, value: 0xaaaa_aaaa)

        m.cpu.execute(.andi(.l, 0x0f0f_0f0f, .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read32(0x2), 0x0a0a_0a0a)
        XCTAssertEqual(m.cpu.ccr, [])
    }

    func testAndiMemLongNegative() throws {
        m.cpu.ccr = []

        m.cpu.a0 = 0x2
        m.cpu.write32(0x2, value: 0xaaaa_aaaa)

        m.cpu.execute(.andi(.l, Int32(bitPattern: 0xf0f0_f0f0), .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read32(0x2), 0xa0a0_a0a0)
        XCTAssertEqual(m.cpu.ccr, [.n])
    }

    func testAndiMemLongZero() throws {
        m.cpu.ccr = []

        m.cpu.a0 = 0x2
        m.cpu.write32(0x2, value: 0xaaaa_aaaa)

        m.cpu.execute(.andi(.l, 0x0000_0000, .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read32(0x2), 0x0000_0000)
        XCTAssertEqual(m.cpu.ccr, [.z])
    }

    func testAndiMemLongOtherFlags() throws {
        m.cpu.ccr = [.x, .v, .c]

        m.cpu.a0 = 0x2
        m.cpu.write32(0x2, value: 0xaaaa_aaaa)

        m.cpu.execute(.andi(.l, 0x0f0f_0f0f, .m(.ind(.a0))), length: 0)

        XCTAssertEqual(m.cpu.read32(0x2), 0x0a0a_0a0a)
        XCTAssertEqual(m.cpu.ccr, [.x])
    }
}
