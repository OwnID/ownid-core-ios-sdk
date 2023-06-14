import Foundation

public extension OwnID.CoreSDK {
    enum WidgetPositionType: String, Encodable {
        case start = "start"
        case end = "end"
    }
    
    enum WidgetType: String, Encodable {
        case fingerprint = "button-fingerprint"
        case faceid = "button-faceid"
        case client = "client-button"
        case auth = "ownid-auth-button"
    }
    
    struct Metadata: Encodable {
        var correlationId: String?
        var stackTrace: String?
        var sessionRequestSequenceNumber: String?
        var widgetPosition: WidgetPositionType?
        var widgetTypeMetric: WidgetType?
        var authType: String?
        var hasLoginId: Bool?
        
        static func metadata(authType: String? = nil,
                             actionType: AnalyticActionType,
                             hasLoginId: Bool? = nil) -> Metadata {
            var metadata = Metadata()
            if let hasLoginId {
                metadata.hasLoginId = hasLoginId
            }
            if let authType {
                metadata.authType = authType
            }
            if actionType.isPositionAndTypeAdding {
                let current = OwnID.CoreSDK.shared.currentMetricInformation
                metadata.widgetPosition = current.widgetPositionType
                metadata.widgetTypeMetric = current.widgetType
            }
            return metadata
        }
    }
}

extension OwnID.CoreSDK.Metadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        correlationId: \(correlationId ?? "")
        """
    }
}
