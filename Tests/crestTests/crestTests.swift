import KSSTest
import XCTest
import class Foundation.Bundle

@testable import CrestLib


final class crestTests: XCTestCase {
    func testTheApplicationRuns() throws {
        let version = "\(CrestLib.VERSION)\n"
        assertEqual(to: version) {
            let fooBinary = productsDirectory.appendingPathComponent("crest")

            let process = Process()
            process.arguments = ["--version"]
            process.executableURL = fooBinary

            let pipe = Pipe()
            process.standardOutput = pipe

            try! process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)!
        }
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }
}
