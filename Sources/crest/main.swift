import ArgumentParser
import AsyncHTTPClient
import Foundation
import NIOHTTP1

import CrestLib

struct Crest: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for communicating with REST-ish services.",
        discussion: """
            For a detailed discussion on how to configure this utility, both globally,
            and in a local project directory, see the README portion of
            https://github.com/klassen-software-solutions/crest.
            """,
        version: CrestLib.VERSION
    )

    @Option(name: .shortAndLong, help: "The HTTP method.")
    var method: HTTPMethod = .GET

    @Option(name: [.customShort("H"), .customLong("header")], help: "Additional request headers of the form name:value")
    var headers = [String]()

    @Option(help: "Show or hide the response headers (true|false)")
    var showResponseHeaders: Bool?

    @Option(help: "Turn the pretty printing on or off (true|false)")
    var prettyPrint: Bool?

    @Flag(help: "Turn off the auto-population of headers.")
    var noAutoHeaders = false

    @Argument(help: "The URL of the service to contact.")
    var url: String

    mutating func run() throws {
        Configuration.setup(withFilename: ".crestconfig.json",
                            andCommandLineOverloads: try commandLineOverrides())
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

    func commandLineOverrides() throws -> [String: Any?] {
        var overrides = [String: Any?]()
        if noAutoHeaders {
            overrides["AutoPopulateRequestHeaders"] = false
            overrides["AutoRecognizeRequestContent"] = false
            overrides["_BlankRequestHeaders"] = true
        }
        if let headers = try requestHeaders() {
            overrides["_RequestHeaders"] = headers
        }
        if let showResponseHeaders = self.showResponseHeaders {
            overrides["ShowResponseHeaders"] = showResponseHeaders
        }
        if let prettyPrint = self.prettyPrint {
            overrides["PrettyPrint"] = prettyPrint
        }
        return overrides
    }

    func requestHeaders() throws -> [String: String]? {
        guard headers.count > 0 else {
            return nil
        }
        var headerDictionary = [String: String]()
        for h in self.headers {
            let ar = h.components(separatedBy: ":")
            guard ar.count == 2 else {
                throw ParameterError.invalidHeader(h)
            }
            headerDictionary[ar[0]] = ar[1]
        }
        return headerDictionary
    }
}

Crest.main()



private enum ParameterError: Error, LocalizedError {
    case invalidURL(String)
    case invalidHeader(String)
    case unsupportedScheme(String)

    var errorDescription: String? { "\(String(describing: type(of: self))).\(self): \(desc)" }

    var desc: String {
        switch self {
        case .invalidURL(let url):
            return "'\(url)' is not a parsable URL"
        case .invalidHeader(let header):
            return "'\(header)' is not of the form key:value"
        case .unsupportedScheme(let scheme):
            return "\(scheme)' is not a supported scheme"
        }
    }
}


extension HTTPMethod: ExpressibleByArgument {}
