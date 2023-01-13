import Foundation

extension OwnID.FlowsSDK {
    final class ErrorLogSender {
        static func sendLog(error: OwnID.CoreSDK.CoreErrorLogWrapper) {
            error.entry.message = "\(error.error.localizedDescription) \(error.error.debugDescription) \(error.entry.message)"
            OwnID.CoreSDK.logger.log(error.entry)
        }
    }
}
