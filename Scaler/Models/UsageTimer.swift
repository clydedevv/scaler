import SwiftUI
import Combine

class UsageTimer: ObservableObject {
    @Published var totalUsageTime: TimeInterval = 0.0
    @Published var isTimerActive: Bool = false
    
    private let targetUsageTime: TimeInterval = 30 * 60 // 30 minutes
    private var timer: Timer?
    private var startTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    func startTimer() {
        guard !isTimerActive else { return }
        
        isTimerActive = true
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            
            self.totalUsageTime += 1.0
            
            print("Usage time: \(Int(self.totalUsageTime))s / \(Int(self.targetUsageTime))s")
            
            // Check if we've reached the target
            if self.totalUsageTime >= self.targetUsageTime {
                self.stopTimer()
                self.triggerShakeSprint()
            }
        }
    }
    
    func stopTimer() {
        isTimerActive = false
        timer?.invalidate()
        timer = nil
        startTime = nil
    }
    
    private func triggerShakeSprint() {
        print("30 minutes of usage reached! Triggering shake sprint.")
        NotificationCenter.default.post(name: .shouldStartShakeSprint, object: nil)
    }
    
    func reset() {
        stopTimer()
        totalUsageTime = 0.0
    }
    
    var progress: Double {
        return min(totalUsageTime / targetUsageTime, 1.0)
    }
    
    var remainingTime: TimeInterval {
        return max(targetUsageTime - totalUsageTime, 0)
    }
    
    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension Notification.Name {
    static let shouldStartShakeSprint = Notification.Name("shouldStartShakeSprint")
} 