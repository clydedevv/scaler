import SwiftUI
import UIKit
import Combine

class ShakeSprintController: ObservableObject {
    @Published var sprintProgress: Double = 0.0
    @Published var isSprinting: Bool = false
    @Published var shakesPerSecond: Double = 0.0
    
    private var shakeCount: Int = 0
    private var sprintStartTime: Date?
    private let requiredShakesPerSecond: Double = 3.0
    private let sprintDuration: TimeInterval = 60.0 // 60 seconds
    private var sprintTimer: Timer?
    private var shakeTimer: Timer?
    private var recentShakes: [Date] = []
    
    init() {
        setupShakeDetection()
    }
    
    deinit {
        stopSprint()
    }
    
    private func setupShakeDetection() {
        // We'll use a notification-based approach since we can't directly override motionEnded in SwiftUI
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceShaken),
            name: UIDevice.deviceDidShakeNotification,
            object: nil
        )
    }
    
    func startShakeSprint() {
        guard !isSprinting else { return }
        
        print("Starting shake sprint - need \(requiredShakesPerSecond) shakes/sec for \(sprintDuration) seconds")
        
        isSprinting = true
        sprintProgress = 0.0
        shakeCount = 0
        sprintStartTime = Date()
        recentShakes.removeAll()
        
        // Timer to update progress and check completion
        sprintTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateSprintProgress()
        }
        
        // Timer to calculate shakes per second
        shakeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateShakesPerSecond()
        }
    }
    
    private func stopSprint() {
        isSprinting = false
        sprintTimer?.invalidate()
        shakeTimer?.invalidate()
        sprintTimer = nil
        shakeTimer = nil
        recentShakes.removeAll()
        
        if sprintProgress >= 1.0 {
            print("Sprint completed successfully!")
        } else {
            print("Sprint stopped incomplete - Progress: \(sprintProgress)")
        }
    }
    
    @objc private func deviceShaken() {
        guard isSprinting else { return }
        
        let now = Date()
        recentShakes.append(now)
        shakeCount += 1
        
        print("Shake detected! Total: \(shakeCount)")
    }
    
    private func updateSprintProgress() {
        guard let startTime = sprintStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / sprintDuration, 1.0)
        
        // Check if we're maintaining the required shake rate
        let currentRate = shakesPerSecond
        if currentRate < requiredShakesPerSecond {
            // Reset progress if not meeting shake requirements
            if elapsed > 2.0 { // Give 2 seconds grace period at start
                print("Insufficient shake rate: \(currentRate)/sec, need \(requiredShakesPerSecond)/sec")
                sprintProgress = max(0, sprintProgress - 0.02) // Decrease progress
            }
        } else {
            sprintProgress = progress
        }
        
        // Check for completion
        if sprintProgress >= 1.0 {
            stopSprint()
        }
        
        // Auto-stop if taking too long without progress
        if elapsed > sprintDuration * 2 {
            stopSprint()
        }
    }
    
    private func updateShakesPerSecond() {
        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1.0)
        
        // Keep only shakes from the last second
        recentShakes = recentShakes.filter { $0 > oneSecondAgo }
        shakesPerSecond = Double(recentShakes.count)
    }
    
    // For testing purposes
    func mockShake() {
        deviceShaken()
    }
    
    func reset() {
        stopSprint()
        sprintProgress = 0.0
        shakeCount = 0
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("deviceDidShakeNotification")
}

// Custom UIWindow to detect shake gestures
class ShakeDetectingWindow: UIWindow {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
} 