import Foundation

public extension OwnID.CoreSDK {
    enum LoggerValues {
        static let correlationIDKey = "correlationId"
        static let component = "IosSdk"
        static let sequenceNumber = "sessionRequestSequenceNumber"
        public static let instanceID = UUID()
    }
}
