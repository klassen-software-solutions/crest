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


struct Operation {
    let url: URL
    let method: HTTPMethod

    func perform() throws {
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        defer {
            try? httpClient.syncShutdown()
        }

        let delegate = ResponseDelegate()
        let request = try HTTPClient.Request(url: url.absoluteString, method: method)
        try httpClient.execute(request: request, delegate: delegate).futureResult.wait()
        if let error = delegate.error {
            throw error
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
