import Foundation
import KDNACore

// MARK: - Shared types for native KDNA applications

public struct KDNAAppConfig {
    public static let kdnaHome: URL = {
#if os(macOS)
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".kdna", isDirectory: true)
#else
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("KDNA", isDirectory: true)
#endif
    }()
    public static let packagesDir = kdnaHome.appendingPathComponent("packages")
    public static let domainsDir = kdnaHome.appendingPathComponent("domains")
}

public enum KDNAAppError: LocalizedError {
    case domainNotFound(String)
    case installFailed(String)
    case verifyFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .domainNotFound(let name): return "Domain not found: \(name)"
        case .installFailed(let reason): return "Install failed: \(reason)"
        case .verifyFailed(let reason): return "Verify failed: \(reason)"
        }
    }
}
