//
//  WrapperTests.swift
//  
//
//  Created by Steven W. Klassen on 2021-05-08.
//

import Foundation
import KSSTest
import XCTest

@testable import CrestLib


final class WrapperTests: XCTestCase {
    func testWrapper() throws {
        assertEqual(to: 10) {
            let wrapper = Wrapper<MyStruct>()
            tryWrapper(wrapper)
            return wrapper.object!.value
        }
    }

    func tryWrapper(_ wrapper: Wrapper<MyStruct>) {
        wrapper.object = MyStruct(value: 10)
    }
}

struct MyStruct {
    var value: Int
}
