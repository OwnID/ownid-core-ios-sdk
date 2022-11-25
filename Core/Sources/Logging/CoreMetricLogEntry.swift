import Foundation

extension OwnID.CoreSDK {
    public final class CoreMetricLogEntry: StandardMetricLogEntry {
        internal init(context: String,
                      requestPath: String? = .none,
                      logLevel: LogLevel = LogLevel.information,
                      message: String,
                      codeInitiator: String) {
            super.init(context: context,
                       requestPath: requestPath,
                       level: logLevel,
                       message: message,
                       codeInitiator: codeInitiator,
                       sdkName: OwnID.CoreSDK.sdkName,
                       version: OwnID.CoreSDK.version)
        }
    }
}

public extension OwnID.CoreSDK.CoreMetricLogEntry {
    static func entry<T>(function: String = #function, file: String = #file, context: String = "no_context", message: String = "", _ : T.Type = T.self) -> OwnID.CoreSDK.CoreMetricLogEntry {
        OwnID.CoreSDK.CoreMetricLogEntry(context: context, message: "\(message) \(function) \(file)", codeInitiator: String(describing: T.self))
    }
    
    static func errorEntry<T>(function: String = #function, file: String = #file, context: String? = "no_context", message: String = "", _ : T.Type = T.self) -> OwnID.CoreSDK.CoreMetricLogEntry {
        OwnID.CoreSDK.CoreMetricLogEntry(context: context ?? "no_context", logLevel: .error, message: "\(message) \(function) \(file)", codeInitiator: String(describing: T.self))
    }
}

extension LoggerProtocol {
    func logCore(_ entry: OwnID.CoreSDK.CoreMetricLogEntry) {
        self.log(entry)
    }
}
