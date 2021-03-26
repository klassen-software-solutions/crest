//
//  Platform.swift
//  
//
//  Created by Steven W. Klassen on 2021-03-20.
//

// TODO: Move this into KSSCore?

import Foundation


public struct Platform {
    public var operatingSystem: String {
        #if os(macOS)
            return "macOS"
        #elseif os(iOS)
            return "iOS"
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(tvOS)
            return "tvOS"
        #elseif os(Linux)
            return "Linux"
        #elseif os(Windows)
            return "Windows"
        #else
            return "Unknown OS"
        #endif
    }

    public var operatingSystemVersion: String {
        return ProcessInfo().operatingSystemVersionString
    }

    public var hardware: String {
        #if arch(i386)
            return "i386"
        #elseif arch(x86_64)
            return "x86_64"
        #elseif arch(arm)
            return "arm"
        #elseif arch(arm64)
            return "arm64"
        #else
            return "Unknown Hardware"
        #endif
    }
}
