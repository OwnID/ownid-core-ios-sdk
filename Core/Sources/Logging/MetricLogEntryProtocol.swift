
import Foundation

public protocol MetricLogEntryProtocol: Encodable {
    var context: String { get set }
    
    var appURL: String? { get set }
    
    var component: String { get set }
    
    var requestPath: String? { get set }
    
    var message: String { get set }
    
    var codeInitiator: String { get set }
    
    var userAgent: String { get set }
    
    var version: String { get set }
    
    var sourceTimestamp: String { get set }
    
    var metadata: [String: String] { get set }
}

extension OwnID.CoreSDK {
    open class StandardMetricLogEntry: MetricLogEntryProtocol {
        public init(context: String,
                    requestPath: String? = nil,
                    level: OwnID.CoreSDK.LogLevel? = .none,
                    message: String,
                    codeInitiator: String,
                    sdkName: String,
                    version: String) {
            self.context = context
            self.requestPath = requestPath
            self.level = level
            self.message = message
            self.codeInitiator = codeInitiator + "\n" + sdkName + " " + version
        }
        
        public var appURL: String? = OwnID.CoreSDK.shared.serverURL(for: OwnID.CoreSDK.shared.configurationName).deletingLastPathComponent().host
        
        public var context: String
        
        public var component = LoggerValues.component
        
        public var requestPath: String?
        
        public var level: OwnID.CoreSDK.LogLevel?
        
        public var message: String
        
        public var codeInitiator: String
        
        public var userAgent = "userAgent"
        
        public var version = "version"
        
        public var sourceTimestamp = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
        
        public var metadata = [String : String]()
        
        public var type: EventType?
        
        public var action: String?
        
        public var category: EventCategory?
    }
}
