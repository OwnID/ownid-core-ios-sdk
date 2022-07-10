import Foundation

extension Thread {
    static var information: String {
        "is main thread? \(isMainThread) \(Thread.current) \(OperationQueue.current?.underlyingQueue?.label ?? "None")"
    }
}
