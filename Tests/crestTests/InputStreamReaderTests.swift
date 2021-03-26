//
//  InputStreamReaderTests.swift
//  
//
//  Created by Steven W. Klassen on 2021-03-20.
//

import Foundation
import KSSTest
import XCTest

@testable import CrestLib

final class InputStreamReaderTests: XCTestCase {
    func testEmptyDataStream() throws {
        let data = Data()
        let inputStream = InputStream(data: data)
        var reader = try! InputStreamReader(inputStream)
        defer { reader.close() }
        assertTrue { reader.empty }
        assertFalse { reader.largeStream }
        assertNil { try! reader.nextDataBlock() }
    }

    func testSmallInputStream() throws {
        let data = "This is a small amount of data".data(using: .utf8)!
        let inputStream = InputStream(data: data)
        var reader = try! InputStreamReader(inputStream)
        defer { reader.close() }
        assertFalse { reader.empty }
        assertFalse { reader.largeStream }
        assertEqual(to: data) { try! reader.nextDataBlock() }
        assertNil { return try! reader.nextDataBlock() }
        assertNil { return try! reader.nextDataBlock() }
        assertNil { return try! reader.nextDataBlock() }
    }

    func testLargeInputStream() throws {
        let inputStream = InputStream(data: randomData(ofLength: 500))
        var reader = try! InputStreamReader(inputStream, withBufferSize: 200)
        defer { reader.close() }
        assertFalse { reader.empty }
        assertTrue { reader.largeStream }
        assertEqual(to: 200) {
            let b = try! reader.nextDataBlock()
            return b!.count
        }
        assertEqual(to: 200) {
            let b = try! reader.nextDataBlock()
            return b!.count
        }
        assertEqual(to: 100) {
            let b = try! reader.nextDataBlock()
            return b!.count
        }
        assertNil { return try! reader.nextDataBlock() }
    }
}
