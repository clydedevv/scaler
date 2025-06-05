import SwiftUI
import CoreMotion
import Combine

class PitchGateModel: ObservableObject {
    @Published var isWithinThreshold: Bool = false
    @Published var currentPitch: Double = 0.0
    @Published var thresholdLow: Double = -10.0 // degrees
    @Published var thresholdHigh: Double = 10.0 // degrees
    
    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 1.0 / 30.0 // 30 Hz
    
    init() {
        startMotionUpdates()
    }
    
    deinit {
        stopMotionUpdates()
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }
            
            let pitch = motion.attitude.pitch * 180.0 / Double.pi // Convert to degrees
            self.currentPitch = pitch
            
            let wasWithinThreshold = self.isWithinThreshold
            self.isWithinThreshold = pitch >= self.thresholdLow && pitch <= self.thresholdHigh
            
            // Notify when threshold state changes
            if wasWithinThreshold != self.isWithinThreshold {
                print("Pitch gate: \(self.isWithinThreshold ? "OPEN" : "CLOSED") - Pitch: \(pitch)°")
            }
        }
    }
    
    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    // For testing purposes
    func setMockPitch(_ pitch: Double) {
        self.currentPitch = pitch
        self.isWithinThreshold = pitch >= thresholdLow && pitch <= thresholdHigh
    }
} 