import XCTest

import crestTests

var tests = [XCTestCaseEntry]()
tests += crestTests.__allTests()

XCTMain(tests)
