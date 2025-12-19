//
//  DebugLogger.swift
//  STUDIO
//
//  Debug logging for runtime instrumentation (DEBUG MODE)
//

import Foundation

/// Debug logger that writes NDJSON to debug.log file
enum DebugLogger {
    private static let logPath = "/Users/henryvantieghem/STUDIO/.cursor/debug.log"
    
    /// Write a log entry in NDJSON format
    static func log(
        location: String,
        message: String,
        data: [String: Any] = [:],
        hypothesisId: String? = nil,
        sessionId: String = "debug-session",
        runId: String = "run1"
    ) {
        let entry: [String: Any] = [
            "id": "log_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(8))",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "location": location,
            "message": message,
            "data": data,
            "sessionId": sessionId,
            "runId": runId,
            "hypothesisId": hypothesisId ?? NSNull()
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: entry),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        // Append to log file
        let logLine = jsonString + "\n"
        if let fileHandle = FileHandle(forWritingAtPath: logPath) {
            fileHandle.seekToEndOfFile()
            if let data = logLine.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            // Create file if it doesn't exist
            FileManager.default.createFile(atPath: logPath, contents: logLine.data(using: .utf8), attributes: nil)
        }
    }
}

