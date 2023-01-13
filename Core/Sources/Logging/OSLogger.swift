import Foundation
import os.log

extension OwnID.CoreSDK {
    final class OSLogger: ExtensionLoggerProtocol {
        var identifier = UUID()
        
        func log(_ entry: OwnID.CoreSDK.StandardMetricLogEntry) {
            os_log("Log 🪵 %{public}@", log: OSLog.OSLogging, type: entry.level?.osLogType ?? .debug, entry.debugDescription)
        }
    }
}

extension OwnID.CoreSDK.LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .trace:
            return .debug
            
        case .debug:
            return .debug
            
        case .information:
            return .info
            
        case .warning:
            return .info
            
        case .error:
            return .error
            
        case .critical:
            return .fault
        }
    }
}

extension OSLog {
    private static var subsystem = String(describing: OwnID.CoreSDK.self)
    static let OSLogging = OSLog(subsystem: subsystem, category: "OSLogger")
}
