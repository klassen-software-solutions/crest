//
//  InputStreamReader.swift
//  
//
//  Created by Steven W. Klassen on 2021-03-20.
//

import Foundation

// TODO: move this into KSSCore?


public struct InputStreamReader {

    let inputStream: InputStream?
    let buffer: UnsafeMutablePointer<UInt8>?
    let bufferSize: Int
    var bufferCount = 0

    /**
     True if the input stream has no data.
     */
    public let empty: Bool

    /**
     True if the input stream contains at least one buffer of data.
     */
    public let largeStream: Bool

    /**
     Construct a reader for the input stream. Note that the stream will be opened. You
     will need to call close at some point.
     */
    public init(_ inputStream: InputStream, withBufferSize bufferSize: Int = 2048) throws {
        inputStream.open()
        self.empty = !inputStream.hasBytesAvailable
        self.bufferSize = bufferSize
        if self.empty {
            inputStream.close()
            self.inputStream = nil
            self.buffer = nil
        } else {
            self.inputStream = inputStream
            self.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            self.bufferCount = try readNextBuffer(inputStream, self.buffer!, bufferSize)
        }
        self.largeStream = self.bufferCount >= bufferSize
    }

    /**
     Close the input stream.
     */
    public func close() {
        self.inputStream?.close()
        self.buffer?.deallocate()
    }

    /**
     Returns the next block of data. Returns nil if there is no more.

     - note: For efficiency the data should be considered immutable and should be used
        before nextBlock is called again.
     - note: If `largeStream` is false, then you may assume that the first call to
        to `nextDataBlock` will have read the data in its entirity.
     */
    public mutating func nextDataBlock() throws -> Data? {
        guard let inputStream = inputStream else {
            return nil
        }
        guard self.bufferCount >= 0 else {
            return nil
        }
        precondition(self.buffer != nil)

        if self.bufferCount == 0 {
            self.bufferCount = try readNextBuffer(inputStream, self.buffer!, bufferSize)
        }
        if self.bufferCount == 0 {
            self.bufferCount = -1
            return nil
        }
        let count = self.bufferCount
        self.bufferCount = 0
        return Data(bytesNoCopy: self.buffer!, count: count, deallocator: .none)
    }
}


fileprivate func readNextBuffer(_ inputStream: InputStream,
                                _ buffer: UnsafeMutablePointer<UInt8>,
                                _ bufferSize: Int) throws -> Int
{
    let read = inputStream.read(buffer, maxLength: bufferSize)
    if read < 0 {
        throw inputStream.streamError!
    }
    return read
}
