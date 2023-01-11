import Foundation

extension OwnID.FlowsSDK {
    final class ErrorLogSender {
        static func sendLog(error: OwnID.CoreSDK.CoreErrorLogWrapper) {
            OwnID.CoreSDK.logger.log(error.entry)
        }
    }
}
