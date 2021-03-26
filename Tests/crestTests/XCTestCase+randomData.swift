//
//  XCTestCase+randomeData.swift
//  
//
//  Created by Steven W. Klassen on 2021-03-21.
//

import Foundation
import XCTest

// TODO: Move this into KSSCore


/**
 Random Test Data Generation

 This extention adds methods for creating `Data` objects filled with random data. Note
 that these are not cryptographically secure random procedures. They are intended for
 generating random test data.
  */
public extension XCTestCase {
    /**
     Construct a set of random bytes.
     */
    func randomData(ofLength count: Int) -> Data {
        var d = Data(capacity: count)
        for _ in 0 ..< count {
            d.append(UInt8.random(in: 0..<255))
        }
        return d
    }

    /**
     Construct a random string.

     This is based on an example found at
     https://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
     */
    func randomString(ofLength count: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< count).map{ _ in letters.randomElement()! })
    }
}
