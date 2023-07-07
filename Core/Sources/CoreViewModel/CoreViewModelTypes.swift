import Combine

extension OwnID.CoreSDK.CoreViewModel {
    
    typealias EventPublisher = AnyPublisher<Event, OwnID.CoreSDK.CoreErrorLogWrapper>
    
    enum Event {
        case loading
        case success(OwnID.CoreSDK.Payload)
        case cancelled(flow: OwnID.CoreSDK.FlowType)
    }
}
