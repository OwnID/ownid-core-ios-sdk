import Foundation

public protocol LogMetricProtocol: Encodable {
    var context: String { get set }
    var component: String { get set }
    var metadata: OwnID.CoreSDK.Metadata? { get set }
    var userAgent: String { get set }
    var version: String { get set }
    var sourceTimestamp: String { get set }
}
