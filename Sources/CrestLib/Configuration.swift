//
//  Configuration.swift
//  
//
//  Created by Steven W. Klassen on 2021-03-25.
//

import Configuration
import Foundation


public struct Configuration {
    var autoPopulateRequestHeaders = true
    var autoRecognizeRequestContent = true
    var inputStreamBufferSize = 2048
    var isPrivate = false
    var prettyPrint = true
    var requestHeaders = [String: String]()
    var showResponseHeaders = false
    var urlPrefix: String? = nil

    static var shared = Configuration()

    public static func setup(withFilename filename: String, andCommandLineOverloads overloads: Any) {
        let manager = ConfigurationManager()
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        manager.load(file: filename, relativeFrom: .customPath(homeDirectory))
            .load(file: filename, relativeFrom: .pwd)
            .load(overloads)

        if let value = manager["AutoPopulateRequestHeaders"] as? Bool {
            shared.autoPopulateRequestHeaders = value
        }
        if let value = manager["AutoRecognizeRequestContent"] as? Bool {
            shared.autoRecognizeRequestContent = value
        }
        if let value = manager["InputStreamBufferSize"] as? Int {
            shared.inputStreamBufferSize = value
        }
        if let value = manager["PrettyPrint"] as? Bool {
            shared.prettyPrint = value
        }
        if let value = manager["Private"] as? Bool {
            shared.isPrivate = value
        }
        if let value = manager["ShowResponseHeaders"] as? Bool {
            shared.showResponseHeaders = value
        }
        shared.urlPrefix = manager["URLPrefix"] as? String

        // Loading maps adds to the map rather than overridding it. Hence to
        // implement --no-auto-headers, we had to use an "extra" manager key
        // to force them to be ignored.
        let blankRequestHeaders = manager["_BlankRequestHeaders"] as? Bool ?? false
        if !blankRequestHeaders {
            if let value = manager["RequestHeaders"] as? [String: String] {
                shared.requestHeaders = value
            }
        }
        if let commandLineHeaders = manager["_RequestHeaders"] as? [String: String] {
            for header in commandLineHeaders {
                shared.requestHeaders[caseInsensitive: header.key] = header.value
            }
        }
    }
}

// TODO: should this be in KSSUtil?
// Note: This is based on code found at
// https://stackoverflow.com/questions/33182260/case-insensitive-dictionary-in-swift
extension Dictionary where Key == String {
    subscript(caseInsensitive key: Key) -> Value? {
        get {
            if let k = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                return self[k]
            }
            return nil
        }
        set {
            if let k = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                self[k] = newValue
            } else {
                self[key] = newValue
            }
        }
    }
}
