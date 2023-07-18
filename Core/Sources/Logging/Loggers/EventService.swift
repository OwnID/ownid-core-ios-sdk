import Combine
import Foundation

public extension OwnID.CoreSDK {
    final class EventService {
        private let provider: APIProvider
        private let sessionService: SessionService
        private var bag = Set<AnyCancellable>()

        private lazy var logQueue: OperationQueue = {
            var queue = OperationQueue()
            queue.qualityOfService = .utility
            queue.name = "\(EventService.self) \(OperationQueue.self)"
            queue.maxConcurrentOperationCount = 1
            return queue
        }()
        
        static let shared = EventService()
        
        init(provider: APIProvider = URLSession.loggerSession) {
            self.provider = provider
            self.sessionService = SessionService(provider: provider)
        }
        
        public func log(_ entry: LogItem) {
            sendEvent(for: entry)
        }
        
        public func sendMetric(_ metric: Metric) {
            sendEvent(for: metric)
        }
    }
}

private extension OwnID.CoreSDK.EventService {
    func sendEvent(for entry: Encodable) {
        logQueue.addBarrierBlock {
            if let url = OwnID.CoreSDK.shared.metricsURL {
                self.sessionService.perform(url: url,
                                            method: .post,
                                            body: entry,
                                            headers: ["Content-Type": "application/json"],
                                            queue: self.logQueue)
                .ignoreOutput()
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                .store(in: &self.bag)
            }
        }
    }
}
