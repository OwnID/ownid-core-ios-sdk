import Combine

public extension OwnID.UISDK {
    enum ButtonState {
        case disabled
        case enabled
        case activated
    }
    
    typealias EventPubliser = AnyPublisher<Void, Never>
}

extension OwnID.UISDK.ButtonState {
    var isEnabled: Bool {
        switch self {
        case .disabled:
            return false
            
        case .enabled:
            return true
            
        case .activated:
            return true
        }
    }
    
    var isTooltipShown: Bool {
        switch self {
        case .disabled:
            return false
            
        case .enabled:
            return true
            
        case .activated:
            return false
        }
    }
}
