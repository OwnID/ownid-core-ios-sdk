import Foundation
import os.log

extension OwnID.CoreSDK {
    final class OSLogger: ExtensionLoggerProtocol {
        var identifier = UUID()
        
        private let level: LogLevel
        
        init(level: LogLevel) {
            self.level = level
        }
        
        func log(_ entry: LogItem, level: LogLevel?) {
            if entry.shouldLog(for: self.level) {
                os_log("Log 🪵 \n%{public}@", log: OSLog.OSLogging, type: entry.level.osLogType, entry.debugDescription)
            }
        }
    }
}

extension OwnID.CoreSDK.LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
            
        case .information:
            return .info
            
        case .warning:
            return .info
            
        case .error:
            return .error
        }
    }
}

extension OSLog {
    private static var subsystem = "OwnID.\(String(describing: OwnID.CoreSDK.self))"
    static let OSLogging = OSLog(subsystem: subsystem, category: "OSLogger")
}
