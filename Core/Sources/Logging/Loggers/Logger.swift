import Foundation

public protocol LoggerProtocol {
    func add(_ logger: ExtensionLoggerProtocol)
    func remove(_ logger: ExtensionLoggerProtocol)
    func log(_ entry: OwnID.CoreSDK.LogItem)
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
    
    func log(_ entry: OwnID.CoreSDK.LogItem, level: OwnID.CoreSDK.LogLevel?)
}

extension OwnID.CoreSDK {
    final class Logger: LoggerProtocol {
        static let shared = Logger()
        private init() { }
        private var sessionRequestSequenceNumber: UInt = 0
        private var sdkNotConfiguredLogs = [LogItem]()
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
            sdkNotConfiguredLogs.forEach { sendToLoggers($0) }
            sdkNotConfiguredLogs.removeAll()
        }
        
        func forceLog(_ entry: LogItem) {
            let entry = setupLog(entry)
        
            sendToLoggers(entry)
        }
        
        func log(_ entry: LogItem) {
            let entry = setupLog(entry)
            
            if !OwnID.CoreSDK.shared.isSDKConfigured {
                sdkNotConfiguredLogs.append(entry)
            } else {
                sendToLoggers(entry)
            }
        }
        
        private func setupLog(_ entry: LogItem) -> LogItem {
            let entry = entry
            entry.metadata = Metadata(correlationId: LoggerConstants.instanceID.uuidString,
                                      stackTrace: nil,
                                      sessionRequestSequenceNumber: String(sessionRequestSequenceNumber),
                                      widgetPosition: nil,
                                      widgetTypeMetric: nil,
                                      authType: nil,
                                      hasLoginId: nil)
            
            sessionRequestSequenceNumber += 1
            
            return entry
        }

        private func sendToLoggers(_ entry: LogItem) {
            extendedLoggers.forEach { logger in
                logger.log(entry, level: logLevel)
            }
        }
    }
}
