
import Foundation

extension URLSession {
    static var loggerSession: URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.networkServiceType = .background
        config.shouldUseExtendedBackgroundIdleMode = true
        config.httpMaximumConnectionsPerHost = 2
        let session = URLSession(configuration: config)
        return session
    }
}
