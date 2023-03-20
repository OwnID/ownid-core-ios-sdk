import Foundation

public extension OwnID.CoreSDK.StandardMetricLogEntry {
    struct CurrentMetricInformation {
        public init(widgetTypeMetric: OwnID.CoreSDK.StandardMetricLogEntry.WidgetTypeMetric = WidgetTypeMetric.client,
                    widgetPositionTypeMetric: OwnID.CoreSDK.StandardMetricLogEntry.WidgetPositionTypeMetric = WidgetPositionTypeMetric.start) {
            self.widgetTypeMetric = widgetTypeMetric
            self.widgetPositionTypeMetric = widgetPositionTypeMetric
        }
        
        var widgetTypeMetric = WidgetTypeMetric.client
        var widgetPositionTypeMetric = WidgetPositionTypeMetric.start
    }
    
    enum WidgetTypeMetric: String {
        case fingerprint = "button-fingerprint"
        case faceid = "button-faceid"
        case client = "client-button"
        case auth = "ownid-auth-button"
    }
    
    enum WidgetPositionTypeMetric: String {
        case start = "start"
        case end = "end"
    }
}

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
    
    enum AnalyticActionType: String {
        case loggedIn = "User is Logged in"
        case registered = "User is Registered"
        case loaded = "OwnID Widget is Loaded"
        case click = "Clicked Skip Password"
        case undo = "Clicked Skip Password Undo"
        
        var isPositionAndTypeAdding: Bool {
            switch self {
            case .loggedIn:
                return false
                
            case .registered:
                return false
                
            case .loaded:
                return true
                
            case .click:
                return true
                
            case .undo:
                return false
            }
        }
    }
}

public extension OwnID.CoreSDK {
    final class MetricLogEntry: StandardMetricLogEntry {
        public init(action: String,
                    type: EventType,
                    category: EventCategory,
                    context: String,
                    metadata: [String : String] = [String : String]()) {
            super.init(context: context, message: "", codeInitiator: "\(Self.self)", sdkName: OwnID.CoreSDK.sdkName, version: OwnID.CoreSDK.UserAgentManager.shared.userFacingSDKVersion,
                       metadata: metadata)
            self.type = type
            self.action = action
            self.category = category
        }
        
        override func isMetric() -> Bool { true }
    }
}

public extension OwnID.CoreSDK.MetricLogEntry {
    private static func metadata(authType: String? = .none, actionType: AnalyticActionType, hasLoginId: Bool? = .none) -> [String: String] {
        var metadata = [String: String]()
        if let hasLoginId {
            metadata["hasLoginId"] = String(hasLoginId)
        }
        if let authType {
            metadata["authType"] = authType
        }
        if actionType.isPositionAndTypeAdding {
            let current = OwnID.CoreSDK.shared.currentMetricInformation
            metadata["widgetPosition"] = current.widgetPositionTypeMetric.rawValue
            metadata["widgetType"] = current.widgetTypeMetric.rawValue
        }
        return metadata
    }
    
    static func registerTrackMetric(action: AnalyticActionType,
                                    context: String? = "no_context",
                                    authType: String? = .none) -> OwnID.CoreSDK.MetricLogEntry {
        let metric = OwnID.CoreSDK.MetricLogEntry.init(action: action.rawValue,
                                                       type: .track,
                                                       category: .registration,
                                                       context: context ?? "no_context",
                                                       metadata: metadata(authType: authType, actionType: action))
        return metric
    }
    
    static func registerClickMetric(action: AnalyticActionType,
                                    context: String? = "no_context",
                                    hasLoginId: Bool? = .none) -> OwnID.CoreSDK.MetricLogEntry {
        let metric = OwnID.CoreSDK.MetricLogEntry.init(action: action.rawValue,
                                                       type: .click,
                                                       category: .registration,
                                                       context: context ?? "no_context",
                                                       metadata: metadata(actionType: action, hasLoginId: hasLoginId))
        return metric
    }
    
    static func loginTrackMetric(action: AnalyticActionType,
                                 context: String? = "no_context",
                                 authType: String? = .none) -> OwnID.CoreSDK.MetricLogEntry {
        let metric = OwnID.CoreSDK.MetricLogEntry.init(action: action.rawValue,
                                                       type: .track,
                                                       category: .login,
                                                       context: context ?? "no_context",
                                                       metadata: metadata(authType: authType, actionType: action))
        return metric
    }
    
    static func loginClickMetric(context: String? = "no_context", hasLoginId: Bool) -> OwnID.CoreSDK.MetricLogEntry {
        let action = AnalyticActionType.click
        let metric = OwnID.CoreSDK.MetricLogEntry.init(action: action.rawValue,
                                                       type: .click,
                                                       category: .login,
                                                       context: context ?? "no_context",
                                                       metadata: metadata(actionType: action, hasLoginId: hasLoginId))
        return metric
    }
}

extension LoggerProtocol {
    public func logAnalytic(_ entry: OwnID.CoreSDK.MetricLogEntry) {
        self.log(entry)
    }
}
