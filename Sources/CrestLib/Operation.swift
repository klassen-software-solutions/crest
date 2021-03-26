//
//  Operation.swift
//  
//
//  Created by Steven W. Klassen on 2021-03-07.
//

import AsyncHTTPClient
import Foundation
import NIO
import NIOHTTP1


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
        var request = try HTTPClient.Request(url: url.absoluteString, method: method)
        addHeadersToRequest(&request)
        try addContentToRequest(&request)
        try httpClient.execute(request: request, delegate: delegate).futureResult.wait()
        if let error = delegate.error {
            throw error
        }
    }

    private func addHeadersToRequest(_ request: inout HTTPClient.Request) {
        let platform = Platform()
        request.headers.add(name: "Host", value: "\(request.host):\(request.port)")
        request.headers.add(name: "User-Agent", value: "Crest/\(VERSION) (\(platform.operatingSystem); \(platform.operatingSystemVersion); \(platform.hardware))")
        request.headers.add(name: "Accept", value: "*/*")
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
            var reader = try InputStreamReader(inputStream)
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
                        request.headers.add(name: "Content-Type", value: contentType)
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

    func didReceiveHead(task: HTTPClient.Task<Void>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        if head.status != .ok {
            error = OperationError.httpError(head.status)
        } else {
            print("Headers:")
            for header in head.headers {
                print("   \(header.name): \(header.value)")
            }
            print("Content:")
        }
        return task.eventLoop.makeSucceededVoidFuture()
    }

    func didReceiveBodyPart(task: HTTPClient.Task<Void>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
        if let string = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes, encoding: .utf8) {
            print(string)
        }
        return task.eventLoop.makeSucceededVoidFuture()
    }

    func didFinishRequest(task: HTTPClient.Task<Void>) throws -> Void {
        // TODO: this is likely where the prettyprinter needs to happen
    }

    func didReceiveError(task: HTTPClient.Task<Void>, _ error: Error) {
        self.error = error
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
