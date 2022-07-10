import Foundation
import OwnIDCoreSDK

extension OwnID.FlowsSDK {
    public class FlowLogEntry: OwnID.CoreSDK.StandardMetricLogEntry {
        internal init(context: String,
                      requestPath: String? = .none,
                      logLevel: OwnID.CoreSDK.LogLevel = .information,
                      message: String,
                      codeInitiator: String) {
            super.init(context: context,
                       requestPath: requestPath,
                       level: logLevel,
                       message: message,
                       codeInitiator: codeInitiator,
                       sdkName: OwnID.FlowsSDK.sdkName,
                       version: OwnID.FlowsSDK.version)
        }
    }
}

public extension OwnID.FlowsSDK.FlowLogEntry {
    static func entry<T>(function: String = #function, file: String = #file, context: String = "empty", message: String = "", _ : T.Type = T.self) -> OwnID.FlowsSDK.FlowLogEntry {
        OwnID.FlowsSDK.FlowLogEntry(context: context, message: "\(message) \(function) \(file)", codeInitiator: String(describing: T.self))
    }
    
    static func errorEntry<T>(function: String = #function, file: String = #file, context: String = "empty", message: String = "", _ : T.Type = T.self) -> OwnID.FlowsSDK.FlowLogEntry {
        OwnID.FlowsSDK.FlowLogEntry(context: context, logLevel: .error, message: "\(message) \(function) \(file)", codeInitiator: String(describing: T.self))
    }
}

extension LoggerProtocol {
    func logFlow(_ entry: OwnID.FlowsSDK.FlowLogEntry) {
        self.log(entry)
    }
}
