import Combine
import Foundation

public extension OwnID.CoreSDK {
    final class MetricsLogger: ExtensionLoggerProtocol {
        public let identifier = UUID()
        private let provider: APIProvider
        private let sessionService: SessionService
        private var bag = Set<AnyCancellable>()
        
        private lazy var logQueue: OperationQueue = {
            var queue = OperationQueue()
            queue.qualityOfService = .utility
            queue.name = "\(MetricsLogger.self) \(OperationQueue.self)"
            queue.maxConcurrentOperationCount = 1
            return queue
        }()
        
        init(provider: APIProvider = URLSession.loggerSession) {
            self.provider = provider
            self.sessionService = SessionService(provider: provider)
        }
        
        public func log(_ entry: StandardMetricLogEntry) {
            sendEvent(for: entry)
        }
    }
}

private extension OwnID.CoreSDK.MetricsLogger {
    func sendEvent(for entry: OwnID.CoreSDK.StandardMetricLogEntry) {
        logQueue.addBarrierBlock {
            if let url = OwnID.CoreSDK.shared.metricsURL {
                self.sessionService.perform(url: url,
                                            method: .put,
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
