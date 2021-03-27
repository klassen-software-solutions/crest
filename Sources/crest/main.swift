import ArgumentParser
import AsyncHTTPClient
import Foundation
import NIOHTTP1

import CrestLib

struct Crest: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for communicating with REST-ish services.",
        version: CrestLib.VERSION
    )

    @Option(name: .shortAndLong, help: "The HTTP method (defaults to GET).")
    var method: HTTPMethod = .GET

    @Flag(help: "Turn off the auto-population of headers.")
    var noAutoHeaders = false

    @Argument(help: "The URL of the service to contact.")
    var url: String

    mutating func run() throws {
        Configuration.setup(withFilename: ".crestconfig.json",
                            andCommandLineOverloads: commandLineOverrides())
        let url = try parseURL()
        let op = Operation(url: url, method: method)
        try op.perform()
    }

    func parseURL() throws -> URL {
        guard let url = URL(string: self.url) else {
            throw ParameterError.invalidURL(self.url)
        }
        guard url.scheme == nil || url.scheme == "http" || url.scheme == "https" else {
            throw ParameterError.unsupportedScheme(url.scheme!)
        }
        return url
    }

    func commandLineOverrides() -> [String: Any?] {
        var overrides = [String: Any?]()
        if noAutoHeaders {
            overrides["AutoPopulateRequestHeaders"] = false
            overrides["AutoRecognizeRequestContent"] = false
        }
        return overrides
    }
}

Crest.main()



private enum ParameterError: Error, LocalizedError {
    case invalidURL(String)
    case unsupportedScheme(String)

    var errorDescription: String? { "\(String(describing: type(of: self))).\(self): \(desc)" }

    var desc: String {
        switch self {
        case .invalidURL(let url):
            return "'\(url)' is not a parsable URL"
        case .unsupportedScheme(let scheme):
            return "\(scheme)' is not a supported scheme"
        }
    }
}


extension HTTPMethod: ExpressibleByArgument {}
