import Foundation

extension OwnID.FlowsSDK {
    final class ErrorLogSender {
        static func sendLog(error: OwnID.CoreSDK.CoreErrorLogWrapper) {
            error.entry.message = error.debugDescription
            OwnID.CoreSDK.logger.log(error.entry)
        }
    }
}
