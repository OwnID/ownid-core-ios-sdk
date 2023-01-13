import Foundation

public extension OwnID.CoreSDK {
    struct CoreErrorLogWrapper: Swift.Error {
        public init(entry: OwnID.CoreSDK.StandardMetricLogEntry, error: OwnID.CoreSDK.Error) {
            self.entry = entry
            self.error = error
        }
        
        public let entry: StandardMetricLogEntry
        public let error: OwnID.CoreSDK.Error
    }
}

public extension OwnID.CoreSDK.CoreErrorLogWrapper {
    static func coreLog(entry: OwnID.CoreSDK.CoreMetricLogEntry, error: OwnID.CoreSDK.Error) -> OwnID.CoreSDK.CoreErrorLogWrapper {
        OwnID.CoreSDK.CoreErrorLogWrapper(entry: entry, error: error)
    }
}

extension OwnID.CoreSDK.CoreErrorLogWrapper: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(error.localizedDescription) \(error.debugDescription) \(entry.message)"
    }
}
