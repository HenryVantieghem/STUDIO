//
//  Logger.swift
//  STUDIO
//
//  Created by Claude on 12/17/25.
//

import Foundation
import OSLog

// MARK: - Log Category

/// Categories for organizing log messages
enum LogCategory: String, CaseIterable, Sendable {
    case auth = "Auth"
    case network = "Network"
    case storage = "Storage"
    case realtime = "Realtime"
    case ui = "UI"
    case navigation = "Navigation"
    case media = "Media"
    case party = "Party"
    case social = "Social"
    case error = "Error"
    case performance = "Performance"
    case lifecycle = "Lifecycle"
}

// MARK: - Log Level

/// Severity levels for log messages
enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }

    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }

    var label: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
}

// MARK: - App Logger

/// Centralized logging system with categories, levels, and crash reporting hooks
@MainActor
final class AppLogger {
    static let shared = AppLogger()

    private let subsystem = Bundle.main.bundleIdentifier ?? "com.studio.app"
    private var loggers: [LogCategory: Logger] = [:]
    private var breadcrumbs: [Breadcrumb] = []
    private let maxBreadcrumbs = 100

    /// Minimum log level to output (can be configured per environment)
    var minimumLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }()

    /// Enable/disable console output
    var consoleOutputEnabled = true

    /// Crash reporting handler (integrate with Sentry, Crashlytics, etc.)
    var crashReportingHandler: ((Error, [String: Any]?) -> Void)?

    /// Breadcrumb handler for crash reporting
    var breadcrumbHandler: ((String, LogCategory) -> Void)?

    private init() {
        // Pre-create loggers for all categories
        for category in LogCategory.allCases {
            loggers[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
    }

    // MARK: - Logging Methods

    /// Log a message with specified level and category
    func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level >= minimumLevel else { return }

        let logger = loggers[category] ?? Logger(subsystem: subsystem, category: category.rawValue)
        let filename = (file as NSString).lastPathComponent
        let formattedMessage = "[\(filename):\(line)] \(function) - \(message)"

        // Log to OSLog
        logger.log(level: level.osLogType, "\(formattedMessage)")

        // Console output in debug
        if consoleOutputEnabled {
            #if DEBUG
            print("\(level.emoji) [\(level.label)] [\(category.rawValue)] \(formattedMessage)")
            #endif
        }

        // Record breadcrumb for crash reporting
        recordBreadcrumb(message, category: category)
    }

    /// Log debug message
    func debug(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    /// Log info message
    func info(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    /// Log warning message
    func warning(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    /// Log error
    func error(
        _ error: Error,
        category: LogCategory,
        context: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let message = "Error: \(error.localizedDescription)"
        log(message, level: .error, category: category, file: file, function: function, line: line)

        // Capture for crash reporting
        captureException(error, context: context)
    }

    /// Log error message
    func error(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }

    /// Log critical error
    func critical(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }

    // MARK: - Crash Reporting Integration

    /// Record a breadcrumb for crash context
    func recordBreadcrumb(_ message: String, category: LogCategory) {
        let breadcrumb = Breadcrumb(
            timestamp: Date(),
            message: message,
            category: category
        )

        breadcrumbs.append(breadcrumb)

        // Keep breadcrumbs under limit
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst(breadcrumbs.count - maxBreadcrumbs)
        }

        // Forward to external crash reporting
        breadcrumbHandler?(message, category)
    }

    /// Capture exception for crash reporting
    func captureException(_ error: Error, context: [String: Any]? = nil) {
        var fullContext = context ?? [:]
        fullContext["breadcrumbs"] = breadcrumbs.suffix(20).map { $0.dictionary }

        crashReportingHandler?(error, fullContext)
    }

    /// Get recent breadcrumbs for debugging
    func recentBreadcrumbs(limit: Int = 20) -> [Breadcrumb] {
        Array(breadcrumbs.suffix(limit))
    }

    /// Clear all breadcrumbs
    func clearBreadcrumbs() {
        breadcrumbs.removeAll()
    }

    // MARK: - Performance Logging

    /// Log a performance event with timing
    func logPerformance(
        _ event: String,
        duration: TimeInterval,
        category: LogCategory = .performance,
        metadata: [String: Any]? = nil
    ) {
        let durationMs = Int(duration * 1000)
        var message = "\(event) completed in \(durationMs)ms"

        if let metadata = metadata {
            let metaString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            message += " [\(metaString)]"
        }

        log(message, level: .info, category: category)
    }

    /// Measure and log execution time of a block
    func measure<T>(
        _ label: String,
        category: LogCategory = .performance,
        block: () async throws -> T
    ) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        logPerformance(label, duration: duration, category: category)
        return result
    }

    /// Measure and log execution time of a synchronous block
    func measureSync<T>(
        _ label: String,
        category: LogCategory = .performance,
        block: () throws -> T
    ) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        logPerformance(label, duration: duration, category: category)
        return result
    }
}

// MARK: - Breadcrumb

/// A breadcrumb for crash reporting context
struct Breadcrumb: Sendable {
    let timestamp: Date
    let message: String
    let category: LogCategory

    var dictionary: [String: Any] {
        [
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "message": message,
            "category": category.rawValue
        ]
    }
}

// MARK: - Convenience Extensions

extension AppLogger {
    /// Log network request
    func logRequest(_ method: String, url: String, category: LogCategory = .network) {
        debug("\(method) \(url)", category: category)
    }

    /// Log network response
    func logResponse(_ method: String, url: String, statusCode: Int, duration: TimeInterval, category: LogCategory = .network) {
        let durationMs = Int(duration * 1000)
        info("\(method) \(url) → \(statusCode) (\(durationMs)ms)", category: category)
    }

    /// Log authentication event
    func logAuth(_ event: String) {
        info(event, category: .auth)
    }

    /// Log navigation event
    func logNavigation(from: String, to: String) {
        debug("Navigate: \(from) → \(to)", category: .navigation)
    }

    /// Log lifecycle event
    func logLifecycle(_ event: String) {
        debug(event, category: .lifecycle)
    }
}

// MARK: - Global Convenience

/// Global logger instance for quick access
let log = AppLogger.shared
