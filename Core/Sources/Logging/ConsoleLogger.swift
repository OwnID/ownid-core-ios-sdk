
import Foundation

extension OwnID.CoreSDK {
    final class ConsoleLogger: ExtensionLoggerProtocol {
        var identifier = UUID()
        
        func log(_ entry: OwnID.CoreSDK.StandardMetricLogEntry) {
            dump(entry)
        }
    }
}
