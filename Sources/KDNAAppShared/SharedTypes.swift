import Foundation
import KDNACore

// MARK: - Shared types between KDNaStudio and KDNAChat

public struct KDNAAppConfig {
    public static let kdnaHome = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".kdna")
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
