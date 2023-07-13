import Foundation

public extension OwnID.CoreSDK {
    struct CoreErrorLogWrapper: Swift.Error {
        public init(entry: OwnID.CoreSDK.LogItem, error: OwnID.CoreSDK.Error, isOnUI: Bool = false, flowFinished: Bool = true) {
            self.entry = entry
            self.error = error
            self.isOnUI = isOnUI
            self.flowFinished = flowFinished
        }
        
        public let entry: OwnID.CoreSDK.LogItem
        public let error: OwnID.CoreSDK.Error
        public let isOnUI: Bool
        public let flowFinished: Bool
    }
}

public extension OwnID.CoreSDK.CoreErrorLogWrapper {
    static func coreLog(entry: OwnID.CoreSDK.LogItem,
                        error: OwnID.CoreSDK.Error,
                        isOnUI: Bool = false,
                        flowFinished: Bool = true) -> OwnID.CoreSDK.CoreErrorLogWrapper {
        OwnID.CoreSDK.CoreErrorLogWrapper(entry: entry, error: error, isOnUI: isOnUI, flowFinished: flowFinished)
    }
}

extension OwnID.CoreSDK.CoreErrorLogWrapper: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(error.localizedDescription) \(error.debugDescription) \(entry.message)"
    }
}
