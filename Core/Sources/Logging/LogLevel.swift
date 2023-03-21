import Foundation

public extension OwnID.CoreSDK {
    enum LogLevel: String, Codable {
        /// Logs that are used for interactive investigation during development.  These logs should primarily contain
        /// information useful for debugging and have no long-term value.
        case debug = "Debug"
        
        /// Logs that track the general flow of the application. These logs should have long-term value.
        case information = "Information"
        
        /// Logs that highlight an abnormal or unexpected event in the application flow, but do not otherwise cause the
        /// application execution to stop.
        case warning = "Warning"
        
        /// Logs that highlight when the current flow of execution is stopped due to a failure. These should indicate a
        /// failure in the current activity, not an application-wide failure.
        case error = "Error"
        
        var priority: Int {
            switch self {
            case .debug:
                return 0
            case .information:
                return 1
            case .warning:
                return 2
            case .error:
                return 3
            }
        }
        
        func shouldLog(for priority: Int) -> Bool {
            priority < self.priority
        }
    }
}
