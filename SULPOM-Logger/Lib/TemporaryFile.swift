//
//  Copyright © 2022 Protonex LLC dba PNI Sensor. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as
//  published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program.
//  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

/// Class that encapsulates creating and writing to a text file stored in a temporary location on disc.
class TemporaryFile {
    public let url: URL;
    private let encoding: String.Encoding;
    private var hasWritten: Bool = false;
    
    struct WriteError {
        public enum ErrorType {
            case URL_NOT_FOUND;
            case TEXT_ENCODING_FAILED;
            case OTHER;
        }
        
        public var type: ErrorType;
    }
    
    /// Create a new temporary file.
    /// - Parameters:
    ///   - encoding: Text encoding to be used.
    ///   - name: Optional file name.
    init(encoding: String.Encoding, name: String? = nil) {
        let tmpDirectoryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true);
        
        let filename: String = name ?? ProcessInfo().globallyUniqueString;
        url = tmpDirectoryUrl.appendingPathComponent(filename);
        self.encoding = encoding;
    }
    
    deinit {
        // Cleanup the temporary file.
        if (hasWritten) {
            do {
                try FileManager.default.removeItem(at: url);
            } catch let error {
                print("⚠️ TemporaryFile -> Deinit Error.", error, error.localizedDescription);
            }
        }
    }
    
    /// Write a line of text to the file.
    /// - Parameters:
    ///   - text: Text to be written.
    /// - Returns: An error if one occured or nil on success.
    func write(text: String) -> WriteError? {
        // If we haven't written to the file, then overwrite anything on it.
        if (!hasWritten) {
            do {
                try text.write(to: url, atomically: true, encoding: encoding);
            } catch let innerError {
                print("⚠️ TemporaryFile -> Write Error.", innerError, innerError.localizedDescription);
                return WriteError(type: .URL_NOT_FOUND);
            }
            hasWritten = true;
            return nil;
        }
        
        // Use a handle to write at the end of the file.
        let handle: FileHandle;
        do {
            handle = try FileHandle(forWritingTo: url);
        } catch let error {
            print("⚠️ TemporaryFile -> Write Error.", error, error.localizedDescription);
            return WriteError(type: .URL_NOT_FOUND);
        }
        
        guard let data: Data = text.data(using: encoding) else {
            return WriteError(type: .TEXT_ENCODING_FAILED);
        }
        
        handle.seekToEndOfFile();
        handle.write(data);
        handle.closeFile();

        return nil; // Success!
    }
    
    /// Write a line of text to the file.
    /// - Parameters:
    ///   - data: Text data to be written.
    /// - Returns: An error if one occured or nil on success.
    func write(data: Data) -> WriteError? {
        // If we haven't written to the file, then overwrite anything on it.
        if (!hasWritten) {
            do {
                try data.write(to: url);
            } catch let innerError {
                print("⚠️ TemporaryFile -> Write Error.", innerError, innerError.localizedDescription);
                return WriteError(type: .URL_NOT_FOUND);
            }
            hasWritten = true;
            return nil;
        }
        
        // Use a handle to write at the end of the file.
        let handle: FileHandle;
        do {
            handle = try FileHandle(forWritingTo: url);
        } catch let error {
            print("⚠️ TemporaryFile -> Write Error.", error, error.localizedDescription);
            return WriteError(type: .URL_NOT_FOUND);
        }
        
        handle.seekToEndOfFile();
        handle.write(data);
        handle.closeFile();

        return nil; // Success!
    }
}
