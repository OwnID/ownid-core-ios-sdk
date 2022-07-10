import Foundation

public extension OwnID.CoreSDK.StandardMetricLogEntry {
    enum EventType: String, Encodable {
        case click
        case track
        case error
    }
    
    enum EventCategory: String, Encodable {
        case registration
        case login
    }
}

public extension OwnID.CoreSDK {
    final class MetricLogEntry: StandardMetricLogEntry {
        public init(action: String,
                    type: EventType,
                    category: EventCategory,
                    context: String) {
            super.init(context: context, level: .information, message: "", codeInitiator: "\(Self.self)", sdkName: OwnID.CoreSDK.sdkName, version: OwnID.CoreSDK.UserAgentManager.shared.userFacingSDKVersion)
            self.type = type
            self.action = action
            self.category = category
        }
    }
}

public extension OwnID.CoreSDK.MetricLogEntry {
    static func registerTrackMetric(action: String, context: String? = "empty") -> OwnID.CoreSDK.MetricLogEntry {
        let metric = OwnID.CoreSDK.MetricLogEntry.init(action: action, type: .track, category: .registration, context: context ?? "empty")
        return metric
    }
    
    static func registerClickMetric(action: String, context: String? = "empty") -> OwnID.CoreSDK.MetricLogEntry {
        let metric = OwnID.CoreSDK.MetricLogEntry.init(action: action, type: .click, category: .registration, context: context ?? "empty")
        return metric
    }
    
    static func loginTrackMetric(action: String, context: String? = "empty") -> OwnID.CoreSDK.MetricLogEntry {
        let metric = OwnID.CoreSDK.MetricLogEntry.init(action: action, type: .track, category: .login, context: context ?? "empty")
        return metric
    }
    
    static func loginClickMetric(action: String, context: String? = "empty") -> OwnID.CoreSDK.MetricLogEntry {
        let metric = OwnID.CoreSDK.MetricLogEntry.init(action: action, type: .click, category: .login, context: context ?? "empty")
        return metric
    }
}

extension LoggerProtocol {
    public func logAnalytic(_ entry: OwnID.CoreSDK.MetricLogEntry) {
        self.log(entry)
    }
}
