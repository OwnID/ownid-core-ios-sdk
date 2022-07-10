import OwnIDCoreSDK
import Combine

public extension OwnID.UISDK {
    enum ButtonState {
        case disabled
        case enabled
        case activated
    }
    
    typealias EventPubliser = AnyPublisher<Void, Never>
}
