import Foundation

public protocol LoggerProtocol {
    func add(_ logger: ExtensionLoggerProtocol)
    func remove(_ logger: ExtensionLoggerProtocol)
    func log(_ entry: OwnID.CoreSDK.StandardMetricLogEntry)
    func sdkConfigured()
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
        private init() { }
        private var sessionRequestSequenceNumber = 0
        private var sdkNotConfiguredLogs = [OwnID.CoreSDK.StandardMetricLogEntry]()
        var logLevel: LogLevel = .error
        
        private var extendedLoggers = [ExtensionLoggerProtocol]()
        
        func add(_ logger: ExtensionLoggerProtocol) {
            extendedLoggers.append(logger)
        }
        
        func remove(_ logger: ExtensionLoggerProtocol) {
            if let index = extendedLoggers.firstIndex(where: { $0.identifier == logger.identifier }) {
                extendedLoggers.remove(at: index)
            }
        }
        
        func sdkConfigured() {
            sdkNotConfiguredLogs.filter{ $0.shouldLog(for: self.logLevel.priority) }.forEach { sendToLoggers($0) }
            sdkNotConfiguredLogs.removeAll()
        }
        
        func log(_ entry: StandardMetricLogEntry) {
            entry.metadata[LoggerValues.correlationIDKey] = LoggerValues.instanceID.uuidString
            entry.version = UserAgentManager.shared.userFacingSDKVersion
            entry.userAgent = UserAgentManager.shared.SDKUserAgent
            entry.metadata[LoggerValues.sequenceNumber] = String(sessionRequestSequenceNumber)
            sessionRequestSequenceNumber += 1
            
            if !entry.isMetric(), entry.shouldLog(for: logLevel.priority) {
                if !OwnID.CoreSDK.shared.isSDKConfigured {
                    sdkNotConfiguredLogs.append(entry)
                }
                return
            }
            
            sendToLoggers(entry)
        }
        
        private func sendToLoggers(_ entry: OwnID.CoreSDK.StandardMetricLogEntry) {
            extendedLoggers.forEach { logger in
                logger.log(entry)
            }
        }
    }
}
