//
//  Configuration.swift
//  
//
//  Created by Steven W. Klassen on 2021-03-25.
//

import Configuration
import Foundation


public struct Configuration {
    var autoPopulateRequestHeaders: Bool? = nil
    var autoRecognizeRequestContent: Bool? = nil
    var isPrivate: Bool? = nil
    var urlPrefix: String? = nil

    static var shared = Configuration()

    public static func setup(withFilename filename: String, andCommandLineOverloads overloads: Any) {
        let manager = ConfigurationManager()
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        manager.load(file: filename, relativeFrom: .customPath(homeDirectory))
            .load(file: filename, relativeFrom: .pwd)
            .load(overloads)
        shared.autoPopulateRequestHeaders = manager["AutoPopulateRequestHeaders"] as? Bool
        shared.autoRecognizeRequestContent = manager["AutoRecognizeRequestContent"] as? Bool
        shared.isPrivate = manager["Private"] as? Bool
        shared.urlPrefix = manager["URLPrefix"] as? String

        print("!! config: \(shared)")
    }
}
