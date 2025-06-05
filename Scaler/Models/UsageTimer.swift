import SwiftUI
import Combine

enum UsageMode: String, CaseIterable {
    case levelOnly = "Level Mode"
    case shakeOnly = "Shake Mode" 
    case fitnessMode = "Fitness Mode"
    case both = "Both Mode"
    
    var description: String {
        switch self {
        case .levelOnly:
            return "Locked out unless phone is level"
        case .shakeOnly:
            return "Use at any angle, shake after time limit"
        case .fitnessMode:
            return "Use at any angle, do exercises after time limit"
        case .both:
            return "Use when level, shake when out of level too long"
        }
    }
    
    var emoji: String {
        switch self {
        case .levelOnly: return "📐"
        case .shakeOnly: return "📳"
        case .fitnessMode: return "🏋️"
        case .both: return "🔄"
        }
    }
}

class UsageTimer: ObservableObject {
    @Published var totalUsageTime: TimeInterval = 0.0
    @Published var isTimerActive: Bool = false
    @Published var outOfLevelTime: TimeInterval = 0.0
    @Published var isOutOfLevel: Bool = false
    @Published var isDebugMode: Bool = true
    @Published var currentMode: UsageMode = .both
    @Published var nonLevelUsageTime: TimeInterval = 0.0 // For shake mode
    @Published var isNonLevelUsageActive: Bool = false
    
    // Configurable thresholds
    @Published var outOfLevelThresholdDebug: TimeInterval = 3.0
    @Published var outOfLevelThresholdRelease: TimeInterval = 10.0
    @Published var nonLevelUsageThresholdDebug: TimeInterval = 6.0 // Changed to 6 seconds for testing
    @Published var nonLevelUsageThresholdRelease: TimeInterval = 60.0
    
    private var outOfLevelThreshold: TimeInterval {
        return isDebugMode ? outOfLevelThresholdDebug : outOfLevelThresholdRelease
    }
    
    private var nonLevelUsageThreshold: TimeInterval {
        return isDebugMode ? nonLevelUsageThresholdDebug : nonLevelUsageThresholdRelease
    }
    
    private var targetUsageTime: TimeInterval {
        return isDebugMode ? 30.0 : (30 * 60) // 30 seconds in debug, 30 minutes in release
    }
    
    private var timer: Timer?
    private var outOfLevelTimer: Timer?
    private var nonLevelUsageTimer: Timer?
    private var startTime: Date?
    private var outOfLevelStartTime: Date?
    private var nonLevelUsageStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    // MARK: - Level Usage Timer (when phone is level)
    func startTimer() {
        guard !isTimerActive else { return }
        
        isTimerActive = true
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            
            self.totalUsageTime += 1.0
            
            if self.isDebugMode {
                let targetTime = Int(self.targetUsageTime)
                let currentTime = Int(self.totalUsageTime)
                print("📱 Level usage time: \(currentTime) / \(targetTime) seconds")
            }
        }
    }
    
    func stopTimer() {
        isTimerActive = false
        timer?.invalidate()
        timer = nil
        startTime = nil
    }
    
    // MARK: - Out of Level Timer (for Both mode)
    func startOutOfLevelTimer() {
        guard !isOutOfLevel && currentMode == .both else { return }
        
        isOutOfLevel = true
        outOfLevelStartTime = Date()
        outOfLevelTime = 0.0
        
        outOfLevelTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.outOfLevelTime += 1.0
            
            if self.isDebugMode {
                let threshold = Int(self.outOfLevelThreshold)
                let current = Int(self.outOfLevelTime)
                print("📐 Out of level time (\(self.currentMode.rawValue)): \(current) / \(threshold) seconds")
            }
            
            // Trigger shake sprint if out of level too long
            if self.outOfLevelTime >= self.outOfLevelThreshold {
                self.stopOutOfLevelTimer()
                self.triggerShakeSprint(reason: "out of level too long")
            }
        }
    }
    
    func stopOutOfLevelTimer() {
        isOutOfLevel = false
        outOfLevelTimer?.invalidate()
        outOfLevelTimer = nil
        outOfLevelStartTime = nil
        outOfLevelTime = 0.0
    }
    
    // MARK: - Non-Level Usage Timer (for Shake and Fitness modes)
    func startNonLevelUsageTimer() {
        guard !isNonLevelUsageActive && (currentMode == .shakeOnly || currentMode == .fitnessMode) else { return }
        
        isNonLevelUsageActive = true
        nonLevelUsageStartTime = Date()
        nonLevelUsageTime = 0.0
        
        nonLevelUsageTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.nonLevelUsageTime += 1.0
            
            if self.isDebugMode {
                let threshold = Int(self.nonLevelUsageThreshold)
                let current = Int(self.nonLevelUsageTime)
                let mode = self.currentMode == .shakeOnly ? "Shake" : (self.currentMode == .fitnessMode ? "Fitness" : "Unknown")
                print("📳 \(mode) mode timer: \(current) / \(threshold) seconds (ignoring phone orientation)")
            }
            
            // Trigger appropriate sprint after time limit
            if self.nonLevelUsageTime >= self.nonLevelUsageThreshold {
                self.resetNonLevelUsageTimer() // Reset timer for next cycle
                
                if self.currentMode == .shakeOnly {
                    self.triggerShakeSprint(reason: "shake mode interval reached")
                } else if self.currentMode == .fitnessMode {
                    self.triggerFitnessSprint(reason: "fitness mode interval reached")
                }
            }
        }
    }
    
    func stopNonLevelUsageTimer() {
        isNonLevelUsageActive = false
        nonLevelUsageTimer?.invalidate()
        nonLevelUsageTimer = nil
        nonLevelUsageStartTime = nil
        nonLevelUsageTime = 0.0
    }
    
    func resetNonLevelUsageTimer() {
        // Reset the timer without stopping it (for continuous cycles)
        nonLevelUsageTime = 0.0
        nonLevelUsageStartTime = Date()
        
        if isDebugMode {
            let mode = currentMode == .shakeOnly ? "Shake" : (currentMode == .fitnessMode ? "Fitness" : "Unknown")
            print("🔄 \(mode) mode timer reset - starting new \(Int(nonLevelUsageThreshold))s cycle")
        }
    }
    
    // MARK: - Mode Logic
    func handlePhoneOrientationChange(isLevel: Bool) {
        switch currentMode {
        case .levelOnly:
            // Level mode: only care about level usage
            if isLevel {
                startTimer()
                stopOutOfLevelTimer()
                stopNonLevelUsageTimer()
            } else {
                stopTimer()
                stopOutOfLevelTimer()
                stopNonLevelUsageTimer()
            }
            
        case .shakeOnly, .fitnessMode:
            // Shake/Fitness mode: COMPLETELY IGNORE PHONE ORIENTATION
            // Always allow usage, just run continuous timer for sprints
            startTimer() // Always active in shake/fitness mode
            stopOutOfLevelTimer() // Never use out-of-level timer
            startNonLevelUsageTimer() // Always run shake/fitness mode timer
            
        case .both:
            // Both mode: current behavior
            if isLevel {
                startTimer()
                stopOutOfLevelTimer()
                stopNonLevelUsageTimer()
            } else {
                stopTimer()
                startOutOfLevelTimer()
                stopNonLevelUsageTimer()
            }
        }
    }
    
    // MARK: - Sprint Triggers
    private func triggerShakeSprint(reason: String) {
        print("📳 Triggering shake sprint: \(reason)")
        NotificationCenter.default.post(name: .shouldStartShakeSprint, object: nil)
    }
    
    private func triggerFitnessSprint(reason: String) {
        print("🏋️ Triggering fitness sprint: \(reason)")
        NotificationCenter.default.post(name: .shouldStartFitnessSprint, object: nil)
    }
    
    // MARK: - Public Methods
    func setMode(_ mode: UsageMode) {
        currentMode = mode
        reset() // Reset all timers when changing modes
        
        // Immediately handle the current phone orientation with new mode
        // This will be called from ContentView when pitch changes
        print("📱 Mode changed to: \(mode.rawValue)")
    }
    
    func reset() {
        stopTimer()
        stopOutOfLevelTimer()
        stopNonLevelUsageTimer()
        totalUsageTime = 0.0
        outOfLevelTime = 0.0
        nonLevelUsageTime = 0.0
    }
    
    func triggerShakeSprintNow() {
        triggerShakeSprint(reason: "manual trigger")
    }
    
    func triggerFitnessSprintNow() {
        triggerFitnessSprint(reason: "manual trigger")
    }
    
    func toggleDebugMode() {
        isDebugMode.toggle()
        print("🐛 Debug mode: \(isDebugMode ? "ON" : "OFF")")
    }
    
    // MARK: - Threshold Adjustments
    func adjustOutOfLevelThreshold(_ newValue: TimeInterval, isDebug: Bool) {
        if isDebug {
            outOfLevelThresholdDebug = max(1.0, newValue)
        } else {
            outOfLevelThresholdRelease = max(5.0, newValue)
        }
        print("🔧 Out-of-level threshold (\(isDebug ? "debug" : "release")) adjusted to: \(newValue)")
    }
    
    func adjustNonLevelUsageThreshold(_ newValue: TimeInterval, isDebug: Bool) {
        if isDebug {
            nonLevelUsageThresholdDebug = max(1.0, newValue)
        } else {
            nonLevelUsageThresholdRelease = max(10.0, newValue)
        }
        print("🔧 Non-level usage threshold (\(isDebug ? "debug" : "release")) adjusted to: \(newValue)")
    }
    
    // MARK: - Computed Properties for UI
    var outOfLevelProgress: Double {
        guard outOfLevelThreshold > 0 else { return 0 }
        return min(outOfLevelTime / outOfLevelThreshold, 1.0)
    }
    
    var nonLevelUsageProgress: Double {
        guard nonLevelUsageThreshold > 0 else { return 0 }
        return min(nonLevelUsageTime / nonLevelUsageThreshold, 1.0)
    }
    
    // MARK: - Utility
    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let shouldStartShakeSprint = Notification.Name("shouldStartShakeSprint")
} 