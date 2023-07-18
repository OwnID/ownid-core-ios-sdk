import Foundation
import os.log

extension OwnID.CoreSDK {
    final class OSLogger: LoggerProtocol {
        func log(priority: Int, codeInitiator: String, message: String, exception: String?) {
            os_log("Log 🪵 \n%{public}@", log: OSLog.OSLogging, type: osLogType(priority: priority), message)
        }
        
        func osLogType(priority: Int) -> OSLogType {
            switch priority {
            case 0:
                return .debug
            case 1, 2:
                return .info
            case 3:
                return .error
            default:
                return .debug
            }
        }
    }
}

extension OSLog {
    private static var subsystem = "OwnID.\(String(describing: OwnID.CoreSDK.self))"
    static let OSLogging = OSLog(subsystem: subsystem, category: "OSLogger")
}
