import Foundation

public protocol LoggerProtocol {
    func add(_ logger: ExtensionLoggerProtocol)
    func remove(_ logger: ExtensionLoggerProtocol)
    func log(_ entry: OwnID.CoreSDK.StandardMetricLogEntry)
}

public extension String {
    var logValue: String {
        if isEmpty {
            return self
        }
        var prefixCount = count - 3
        if prefixCount <= 3 {
            prefixCount = 2
        }
        return String(self.prefix(prefixCount))
    }
}

public protocol ExtensionLoggerProtocol {
    var identifier: UUID { get }
    
    func log(_ entry: OwnID.CoreSDK.StandardMetricLogEntry)
}

extension OwnID.CoreSDK {
    final class Logger: LoggerProtocol {
        static let shared = Logger()
        private init() {
#if DEBUG
            print("🪪🆔🪢 instanceID: \(LoggerValues.instanceID.uuidString)")
#endif
        }
        private var sessionRequestSequenceNumber = 0
        var logLevel: LogLevel = .information
        
        private var extendedLoggers = [ExtensionLoggerProtocol]()
        
        func add(_ logger: ExtensionLoggerProtocol) {
            extendedLoggers.append(logger)
        }
        
        func remove(_ logger: ExtensionLoggerProtocol) {
            if let index = extendedLoggers.firstIndex(where: { $0.identifier == logger.identifier }) {
                extendedLoggers.remove(at: index)
            }
        }
        
        func log(_ entry: StandardMetricLogEntry) {
            if let level = entry.level, logLevel.rawValue > level.rawValue {
                return
            }
            entry.metadata[LoggerValues.correlationIDKey] = LoggerValues.instanceID.uuidString
            entry.metadata["sessionRequestSequenceNumber"] = String(sessionRequestSequenceNumber)
            entry.version = UserAgentManager.shared.userFacingSDKVersion
            entry.userAgent = UserAgentManager.shared.SDKUserAgent
            sessionRequestSequenceNumber += 1
            extendedLoggers.forEach { logger in
                logger.log(entry)
            }
        }
    }
}
