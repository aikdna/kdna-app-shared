import Foundation

public actor StreamingTaskController {
    private var currentTaskID: UUID?
    private var currentTask: Task<Void, Never>?
    
    public init() {}
    
    public func replace(taskID: UUID, task: Task<Void, Never>) {
        currentTask?.cancel()
        currentTaskID = taskID
        currentTask = task
    }
    
    public func cancelAndClear() {
        currentTask?.cancel()
        currentTaskID = nil
        currentTask = nil
    }
    
    public func clearIfCurrent(taskID: UUID) {
        guard currentTaskID == taskID else { return }
        currentTaskID = nil
        currentTask = nil
    }
}

