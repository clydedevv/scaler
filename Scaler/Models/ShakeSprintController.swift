import SwiftUI
import UIKit
import Combine
import CoreMotion

class ShakeSprintController: ObservableObject {
    @Published var sprintProgress: Double = 0.0
    @Published var isSprinting: Bool = false
    @Published var shakesPerSecond: Double = 0.0
    @Published var isDebugMode: Bool = true
    @Published var accelerationMagnitude: Double = 0.0
    @Published var shakeThreshold: Double = 2.5
    
    private var shakeCount: Int = 0
    private var sprintStartTime: Date?
    private let requiredShakesPerSecond: Double = 3.0
    private let sprintDuration: TimeInterval = 10.0 // Reduced for testing
    private var sprintTimer: Timer?
    private var shakeTimer: Timer?
    private var recentShakes: [Date] = []
    
    // Accelerometer-based shake detection
    private let motionManager = CMMotionManager()
    private var lastAcceleration: CMAcceleration?
    private let shakeDetectionInterval: TimeInterval = 1.0 / 30.0 // 30 Hz
    
    init() {
        setupAccelerometerShakeDetection()
    }
    
    deinit {
        stopSprint()
        motionManager.stopAccelerometerUpdates()
    }
    
    private func setupAccelerometerShakeDetection() {
        guard motionManager.isAccelerometerAvailable else {
            print("❌ Accelerometer not available")
            return
        }
        
        motionManager.accelerometerUpdateInterval = shakeDetectionInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let acceleration = data?.acceleration else { return }
            
            // Calculate magnitude of acceleration
            let magnitude = sqrt(acceleration.x * acceleration.x + 
                               acceleration.y * acceleration.y + 
                               acceleration.z * acceleration.z)
            
            self.accelerationMagnitude = magnitude
            
            // Detect shakes based on sudden changes in acceleration
            if let lastAccel = self.lastAcceleration {
                let deltaX = abs(acceleration.x - lastAccel.x)
                let deltaY = abs(acceleration.y - lastAccel.y)
                let deltaZ = abs(acceleration.z - lastAccel.z)
                let totalDelta = deltaX + deltaY + deltaZ
                
                if totalDelta > self.shakeThreshold {
                    self.onShakeDetected()
                }
            }
            
            self.lastAcceleration = acceleration
        }
        
        print("✅ Accelerometer shake detection started")
    }
    
    private func onShakeDetected() {
        guard isSprinting else { 
            if isDebugMode {
                print("🔍 Shake detected but not sprinting (magnitude: \(accelerationMagnitude))")
            }
            return 
        }
        
        let now = Date()
        recentShakes.append(now)
        shakeCount += 1
        
        if isDebugMode {
            print("🎯 Valid shake detected! Total: \(shakeCount), Rate: \(shakesPerSecond)")
        }
    }
    
    func startShakeSprint() {
        guard !isSprinting else { return }
        
        print("🚀 Starting shake sprint - need \(requiredShakesPerSecond) shakes/sec for \(sprintDuration) seconds")
        
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
        shakeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
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
            print("✅ Sprint completed successfully!")
        } else {
            print("❌ Sprint stopped incomplete - Progress: \(sprintProgress)")
        }
    }
    
    private func updateSprintProgress() {
        guard let startTime = sprintStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let timeProgress = min(elapsed / sprintDuration, 1.0)
        
        // Check if we're maintaining the required shake rate
        let currentRate = shakesPerSecond
        if currentRate >= requiredShakesPerSecond {
            // Good shake rate - advance progress
            sprintProgress = timeProgress
        } else {
            // Insufficient shake rate - slow down progress
            if elapsed > 1.0 { // Give 1 second grace period at start
                sprintProgress = max(0, sprintProgress - 0.01) // Decrease progress slowly
                if isDebugMode {
                    print("⚠️ Insufficient shake rate: \(currentRate)/sec, need \(requiredShakesPerSecond)/sec")
                }
            }
        }
        
        // Check for completion
        if sprintProgress >= 1.0 {
            stopSprint()
        }
        
        // Auto-stop if taking too long without progress
        if elapsed > sprintDuration * 3 {
            print("⏰ Sprint timeout")
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
    
    // Debug functions
    func mockShake() {
        onShakeDetected()
    }
    
    func reset() {
        stopSprint()
        sprintProgress = 0.0
        shakeCount = 0
        shakesPerSecond = 0.0
    }
    
    func adjustShakeThreshold(_ newThreshold: Double) {
        shakeThreshold = newThreshold
        print("🔧 Shake threshold adjusted to: \(shakeThreshold)")
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