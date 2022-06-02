//
//  Operation.swift
//  
//
//  Created by Steven W. Klassen on 2021-03-07.
//

import AsyncHTTPClient
import Foundation
import KSSFoundation
import NIO
import NIOFoundationCompat
import NIOHTTP1

#if canImport(FoundationXML)
    import FoundationXML
#endif


public struct Operation {
    public let url: URL
    public let method: HTTPMethod

    public init(url: URL, method: HTTPMethod) {
        self.url = url
        self.method = method
    }

    public func perform() throws {
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        defer {
            try? httpClient.syncShutdown()
        }

        let delegate = ResponseDelegate()

        var request = try HTTPClient.Request(url: urlAsString(), method: method)
        try addContentToRequest(&request)
        addHeadersToRequest(&request)
        try httpClient.execute(request: request, delegate: delegate).futureResult.wait()
        if let error = delegate.error {
            throw error
        }
    }

    private func urlAsString() -> String {
        if url.scheme == nil {
            if let prefix = Configuration.shared.urlPrefix {
                return prefix + url.absoluteString
            }
        }
        return url.absoluteString
    }

    private func addHeadersToRequest(_ request: inout HTTPClient.Request) {
        request.headers.add(name: "host", value: "\(request.host):\(request.port)")
        if Configuration.shared.autoPopulateRequestHeaders {
            request.headers.add(name: "user-agent", value: getUserAgent())
            request.headers.add(name: "accept", value: "*/*")
        }
        for header in Configuration.shared.requestHeaders {
            request.headers.replaceOrAdd(name: header.key, value: header.value)
        }
    }

    private func getUserAgent() -> String {
        if Configuration.shared.isPrivate {
            return "Crest"
        }
        return "Crest/\(VERSION) (\(Platform.operatingSystem); \(Platform.operatingSystemVersion); \(Platform.hardware))"
    }

    // This "ugliness" is needed for the streaming requests since we need the stream
    // reader to outlive the `addContentToRequest` method.
    private let wrapper = Wrapper<InputStreamReader>()

    private func nextChunk(_ writer: HTTPClient.Body.StreamWriter) -> EventLoopFuture<Void> {
        if let data = try? wrapper.object?.nextDataBlock() {
            return writer.write(.byteBuffer(ByteBuffer(data: data))).flatMap {
                nextChunk(writer)
            }
        }
        wrapper.object?.close()
        wrapper.object = nil
        return writer.write(.byteBuffer(ByteBuffer()))
    }

    private func addContentToRequest(_ request: inout HTTPClient.Request) throws {
        if let inputStream = InputStream(fileAtPath: "/dev/stdin") {
            var reader = try InputStreamReader(inputStream,
                                               withBufferSize: Configuration.shared.inputStreamBufferSize)
            guard !reader.empty else { return }
            if reader.largeStream {
                wrapper.object = reader
                let body: HTTPClient.Body = .stream { writer in
                    nextChunk(writer)
                }
                request.body = body
            } else {
                defer { reader.close() }
                if let data = try reader.nextDataBlock() {
                    if let s = String.init(data: data, encoding: .utf8) {
                        var contentType = "text/plain"
                        if (try? JSONSerialization.jsonObject(with: data)) != nil {
                            contentType = "application/json"
                        } else if (try? XMLDocument(data: data)) != nil {
                            contentType = "application/xml"
                        }
                        if Configuration.shared.autoRecognizeRequestContent {
                            request.headers.add(name: "Content-Type", value: contentType)
                        }
                        request.body = .string(s)
                        return
                    }
                    request.body = .data(data)
                }
            }
        }
    }
}

final class ResponseDelegate: HTTPClientResponseDelegate {
    typealias Response = Void

    var error: Error? = nil
    var prettyPrintIsPossible: Bool = false
    var needNewline = false

    func didReceiveHead(task: HTTPClient.Task<Void>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        outputResponseHeaders(head)
        if head.status != .ok {
            error = OperationError.httpError(head.status)
        } else {
            if Configuration.shared.prettyPrint {
                let matches = head.headers["Content-Type"]
                if matches.count == 1 && canPrettyPrintHeaderType(matches[0]) {
                    prettyPrintIsPossible = true
                }
            }
        }
        return task.eventLoop.makeSucceededVoidFuture()
    }

    func didReceiveBodyPart(task: HTTPClient.Task<Void>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
        if let string = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes, encoding: .utf8) {
            if prettyPrintIsPossible {
                print(string.prettyPrint(), terminator: "")
            } else {
                print(string, terminator: "")
            }
            needNewline = true
        } else {
            print("...received binary data: \(buffer.readableBytes) bytes")
        }
        return task.eventLoop.makeSucceededVoidFuture()
    }

    func didFinishRequest(task: HTTPClient.Task<Void>) throws -> Void {
        // If pretty print is requested, then we want to add a newline even if pretty
        // printing isn't possible.
        if Configuration.shared.prettyPrint {
            if needNewline {
                print()
                needNewline = false
            }
        }
    }

    func didReceiveError(task: HTTPClient.Task<Void>, _ error: Error) {
        self.error = error
    }

    func canPrettyPrintHeaderType(_ contentType: String) -> Bool {
        return contentType.starts(with: "application/xml")
            || contentType.starts(with: "text/xml")
            || contentType.starts(with: "application/json")
    }

    func outputResponseHeaders(_ head: HTTPResponseHead) {
        if Configuration.shared.showResponseHeaders {
            print("Headers:")
            print("  \(head.version) \(head.status.code) \(head.status)".uppercased())
            var maxLen = 0
            for header in head.headers {
                let len = header.name.count
                if len > maxLen && len <= 25 {
                    maxLen = len
                }
            }
            if maxLen > 25 {
                maxLen = 25
            }
            for header in head.headers {
                var name = header.name + ":"
                if name.count < maxLen+1 {
                    name = name.padding(toLength: maxLen+1, withPad: " ", startingAt: 0)
                }
                print("  \(name) \(header.value)")
            }
            print("Content:")
        }
    }
}


private enum OperationError: Error, LocalizedError {
    case httpError(HTTPResponseStatus)
    case decodingError

    var errorDescription: String? { "\(String(describing: type(of: self))).\(self): \(desc)" }

    var desc: String {
        switch self {
        case .httpError(let status):
            return "Operation returned error code \(status.code) (\(status.reasonPhrase))"
        case .decodingError:
            return "Could not decode the response"
        }
    }
}
