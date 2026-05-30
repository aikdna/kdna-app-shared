import Foundation

/// Abstract logger protocol for use in shared API handler infrastructure.
/// Each app provides its own implementation (typically backed by OSLog).
public protocol KDNALogger: Sendable {
    func debug(_ message: String)
    func notice(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}

/// Default no-op logger used when no app-specific logger is configured.
public struct NoOpLogger: KDNALogger {
    public func debug(_ message: String) {}
    public func notice(_ message: String) {}
    public func warning(_ message: String) {}
    public func error(_ message: String) {}
    public init() {}
}
