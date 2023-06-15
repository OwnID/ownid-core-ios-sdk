import Foundation

public extension OwnID.CoreSDK {
    class LogItem: LogMetricProtocol {
        public var context: String
        public var component = LoggerConstants.component
        var requestPath = ""
        let level: LogLevel
        let codeInitiator: String?
        var message: String
        let exception: String?
        public var metadata: Metadata?
        public var userAgent = UserAgentManager.shared.SDKUserAgent
        public var version = UserAgentManager.shared.userFacingSDKVersion
        public var sourceTimestamp = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
        
        init(context: String = LoggerConstants.noContext,
             level: LogLevel,
             codeInitiator: String? = nil,
             message: String,
             exception: String? = nil,
             metadata: Metadata? = nil) {
            self.context = context
            self.level = level
            self.codeInitiator = codeInitiator
            self.message = message
            self.exception = exception
            self.metadata = metadata
        }
        
        func shouldLog(for logLevel: LogLevel) -> Bool {
            return level.shouldLog(for: logLevel.priority)
        }
        
        public static func entry<T>(context: String? = LoggerConstants.noContext,
                             level: LogLevel,
                             function: String = #function,
                             file: String = #file,
                             message: String = "",
                             exception: String? = nil,
                             _: T.Type = T.self) -> LogItem {
            LogItem(context: context ?? LoggerConstants.noContext,
                    level: level,
                    codeInitiator: String(describing: T.self),
                    message: "\(message) \(function) \(file)",
                    exception: exception)
        }
        
        public static func errorEntry<T>(context: String? = LoggerConstants.noContext,
                                         function: String = #function,
                                         file: String = #file,
                                         message: String = "",
                                         exception: String? = nil,
                                         _: T.Type = T.self) -> LogItem {
            LogItem(context: context ?? LoggerConstants.noContext,
                    level: .error,
                    codeInitiator: String(describing: T.self),
                    message: "\(message) \(function) \((file as NSString).lastPathComponent)",
                    exception: exception)
        }
    }
}

extension OwnID.CoreSDK.LogItem: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        context: \(context)
        message: \(message)
        level: \(level.priority)
        codeInitiator: \(codeInitiator ?? "")
        userAgent: \(userAgent)
        version: \(version)
        metadata: \(metadata?.debugDescription ?? "")
    """
    }
}
