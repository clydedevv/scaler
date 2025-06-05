import SwiftUI
import Combine

class UsageTimer: ObservableObject {
    @Published var totalUsageTime: TimeInterval = 0.0
    @Published var isTimerActive: Bool = false
    
    // Debug mode: set to true for 5-second timer instead of 30 minutes
    private let isDebugMode: Bool = true
    
    private var targetUsageTime: TimeInterval {
        return isDebugMode ? 5.0 : (30 * 60) // 5 seconds in debug, 30 minutes in release
    }
    
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
            
            let timeUnit = self.isDebugMode ? "seconds" : "minutes"
            let targetTime = self.isDebugMode ? Int(self.targetUsageTime) : Int(self.targetUsageTime / 60)
            let currentTime = self.isDebugMode ? Int(self.totalUsageTime) : Int(self.totalUsageTime / 60)
            
            print("Usage time: \(currentTime) / \(targetTime) \(timeUnit)")
            
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
        let timeText = isDebugMode ? "5 seconds" : "30 minutes"
        print("\(timeText) of usage reached! Triggering shake sprint.")
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
        if isDebugMode {
            return String(format: "%.0fs", time)
        } else {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // For immediate testing
    func triggerShakeSprintNow() {
        print("Manually triggering shake sprint for testing")
        NotificationCenter.default.post(name: .shouldStartShakeSprint, object: nil)
    }
}

extension Notification.Name {
    static let shouldStartShakeSprint = Notification.Name("shouldStartShakeSprint")
} 