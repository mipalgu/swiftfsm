import XCTest

import demoTests

var tests = [XCTestCaseEntry]()
tests += demoTests.allTests()
XCTMain(tests)
