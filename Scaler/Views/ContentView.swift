import SwiftUI

struct ContentView: View {
    @StateObject private var pitchGateModel = PitchGateModel()
    @StateObject private var shakeSprintController = ShakeSprintController()
    @StateObject private var fitnessSprintController = FitnessSprintController()
    @StateObject private var usageTimer = UsageTimer()
    
    @State private var isAppInForeground = true
    @State private var showDebugControls = false
    
    // Computed properties for different mode behaviors
    private var shouldShowContent: Bool {
        switch usageTimer.currentMode {
        case .levelOnly:
            return pitchGateModel.isWithinThreshold
        case .shakeOnly, .fitnessMode:
            return true // Always show content in shake/fitness mode
        case .both:
            return pitchGateModel.isWithinThreshold
        }
    }
    
    private var shouldShowLevelWarning: Bool {
        switch usageTimer.currentMode {
        case .levelOnly:
            return !pitchGateModel.isWithinThreshold && !shakeSprintController.isSprinting && !fitnessSprintController.isSprinting
        case .shakeOnly, .fitnessMode:
            return false // Never show level warning in shake/fitness mode
        case .both:
            return !pitchGateModel.isWithinThreshold && !shakeSprintController.isSprinting && !fitnessSprintController.isSprinting
        }
    }

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 20) {
                Text("Hello, Scaler!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Current mode indicator
                VStack(spacing: 8) {
                    Text("\(usageTimer.currentMode.emoji) \(usageTimer.currentMode.rawValue)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text(usageTimer.currentMode.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Status based on current mode
                Group {
                    switch usageTimer.currentMode {
                    case .levelOnly:
                        levelModeStatus
                    case .shakeOnly:
                        shakeModeStatus
                    case .fitnessMode:
                        fitnessModeStatus
                    case .both:
                        bothModeStatus
                    }
                }
                
                // Enhanced Debug Controls
                if showDebugControls {
                    debugControlsSection
                }
                
                // Enhanced Debug info
                debugInfoSection
            }
            .padding()
            .opacity(shouldShowContent ? 1.0 : 0.0)
            
            // Level warning overlay
            if shouldShowLevelWarning {
                levelWarningOverlay
            }
            
            // Enhanced Sprint overlay
            if shakeSprintController.isSprinting || fitnessSprintController.isSprinting {
                sprintOverlay
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            isAppInForeground = true
            handleAppStateChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            isAppInForeground = false
            usageTimer.reset()
        }
        .onReceive(NotificationCenter.default.publisher(for: .shouldStartShakeSprint)) { _ in
            shakeSprintController.startShakeSprint()
        }
        .onReceive(NotificationCenter.default.publisher(for: .shouldStartFitnessSprint)) { _ in
            fitnessSprintController.startFitnessSprint()
        }
        .onChange(of: pitchGateModel.isWithinThreshold) { _ in
            handlePhoneOrientationChange()
        }
        .onChange(of: isAppInForeground) { _ in
            handleAppStateChange()
        }
        .onTapGesture {
            showDebugControls.toggle()
        }
    }
    
    // MARK: - Mode-specific status views
    
    @ViewBuilder
    private var levelModeStatus: some View {
        if pitchGateModel.isWithinThreshold {
            VStack(spacing: 10) {
                Text("📱 Phone is Level - Usage Active")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text("Usage Time: \(usageTimer.formattedTime(usageTimer.totalUsageTime))")
                    .font(.subheadline)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        } else {
            VStack(spacing: 10) {
                Text("🔒 Locked - Phone Must Be Level")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text("Hold phone level to access")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var shakeModeStatus: some View {
        VStack(spacing: 10) {
            Text("📳 Shake Mode - Any Angle OK")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Usage Time: \(usageTimer.formattedTime(usageTimer.totalUsageTime))")
                .font(.subheadline)
            
            if usageTimer.isNonLevelUsageActive {
                VStack(spacing: 8) {
                    Text("Time until shake sprint: \(usageTimer.formattedTime(usageTimer.nonLevelUsageThresholdDebug - usageTimer.nonLevelUsageTime))")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    ProgressView(value: usageTimer.nonLevelUsageProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .frame(width: 200)
                    
                    Text("Phone orientation ignored - continuous \(usageTimer.formattedTime(usageTimer.nonLevelUsageThresholdDebug)) cycles")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var fitnessModeStatus: some View {
        VStack(spacing: 10) {
            Text("🏋️ Fitness Mode - Any Angle OK")
                .font(.headline)
                .foregroundColor(.purple)
            
            Text("Usage Time: \(usageTimer.formattedTime(usageTimer.totalUsageTime))")
                .font(.subheadline)
            
            if usageTimer.isNonLevelUsageActive {
                VStack(spacing: 8) {
                    Text("Time until fitness sprint: \(usageTimer.formattedTime(usageTimer.nonLevelUsageThresholdDebug - usageTimer.nonLevelUsageTime))")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                    
                    ProgressView(value: usageTimer.nonLevelUsageProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                        .frame(width: 200)
                    
                    Text("Phone orientation ignored - continuous \(usageTimer.formattedTime(usageTimer.nonLevelUsageThresholdDebug)) cycles")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var bothModeStatus: some View {
        if pitchGateModel.isWithinThreshold {
            VStack(spacing: 10) {
                Text("📱 Phone is Level - Usage Active")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text("Usage Time: \(usageTimer.formattedTime(usageTimer.totalUsageTime))")
                    .font(.subheadline)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        } else {
            VStack(spacing: 10) {
                Text("📐 Phone Out of Level")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                if usageTimer.isOutOfLevel {
                    Text("Out of level: \(usageTimer.formattedTime(usageTimer.outOfLevelTime))")
                        .font(.subheadline)
                    
                    ProgressView(value: usageTimer.outOfLevelProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .frame(width: 200)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Debug Controls Section
    
    @ViewBuilder
    private var debugControlsSection: some View {
        VStack(spacing: 15) {
            Text("🐛 Debug Controls")
                .font(.headline)
                .foregroundColor(.orange)
            
            // Mode Selection
            VStack(spacing: 10) {
                Text("Mode Selection")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    ForEach(UsageMode.allCases, id: \.self) { mode in
                        Button("\(mode.emoji) \(mode.rawValue)") {
                            usageTimer.setMode(mode)
                        }
                        .debugButtonStyle(
                            usageTimer.currentMode == mode ? .blue : .gray,
                            size: .small
                        )
                    }
                }
            }
            
            // Main debug buttons
            HStack(spacing: 10) {
                Button("Start Sprint") {
                    if usageTimer.currentMode == .fitnessMode {
                        fitnessSprintController.startFitnessSprint()
                    } else {
                        usageTimer.triggerShakeSprintNow()
                    }
                }
                .debugButtonStyle(.red)
                
                if usageTimer.currentMode == .shakeOnly {
                    Button("Mock Shakes") {
                        for _ in 0..<10 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.5)) {
                                shakeSprintController.mockShake()
                            }
                        }
                    }
                    .debugButtonStyle(.purple)
                } else if usageTimer.currentMode == .fitnessMode {
                    Button("Mock Reps") {
                        for _ in 0..<5 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...1.0)) {
                                fitnessSprintController.mockRep()
                            }
                        }
                    }
                    .debugButtonStyle(.purple)
                }
                
                Button("Reset All") {
                    usageTimer.reset()
                    shakeSprintController.reset()
                    fitnessSprintController.reset()
                }
                .debugButtonStyle(.gray)
            }
            
            // Fitness threshold controls
            if usageTimer.currentMode == .fitnessMode {
                VStack(spacing: 8) {
                    Text("Fitness Thresholds")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        Text("Squat: \(fitnessSprintController.squatThreshold, specifier: "%.1f")")
                            .font(.caption)
                        
                        Button("-0.2") {
                            fitnessSprintController.adjustSquatThreshold(fitnessSprintController.squatThreshold - 0.2)
                        }
                        .debugButtonStyle(.purple, size: .small)
                        
                        Button("+0.2") {
                            fitnessSprintController.adjustSquatThreshold(fitnessSprintController.squatThreshold + 0.2)
                        }
                        .debugButtonStyle(.purple, size: .small)
                    }
                    
                    HStack(spacing: 8) {
                        Text("Step: \(fitnessSprintController.stepThreshold, specifier: "%.1f")")
                            .font(.caption)
                        
                        Button("-0.2") {
                            fitnessSprintController.adjustStepThreshold(fitnessSprintController.stepThreshold - 0.2)
                        }
                        .debugButtonStyle(.purple, size: .small)
                        
                        Button("+0.2") {
                            fitnessSprintController.adjustStepThreshold(fitnessSprintController.stepThreshold + 0.2)
                        }
                        .debugButtonStyle(.purple, size: .small)
                    }
                }
            }
            
            // Threshold controls
            VStack(spacing: 8) {
                Text("Threshold Controls")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Out of level threshold (for Both mode)
                HStack(spacing: 8) {
                    Text("Out-of-level: \(usageTimer.outOfLevelThresholdDebug, specifier: "%.0f")s")
                        .font(.caption)
                    
                    Button("-1s") {
                        usageTimer.adjustOutOfLevelThreshold(usageTimer.outOfLevelThresholdDebug - 1, isDebug: true)
                    }
                    .debugButtonStyle(.blue, size: .small)
                    
                    Button("+1s") {
                        usageTimer.adjustOutOfLevelThreshold(usageTimer.outOfLevelThresholdDebug + 1, isDebug: true)
                    }
                    .debugButtonStyle(.blue, size: .small)
                }
                
                // Non-level usage threshold (for Shake/Fitness mode)
                HStack(spacing: 8) {
                    Text("Non-level: \(usageTimer.nonLevelUsageThresholdDebug, specifier: "%.0f")s")
                        .font(.caption)
                    
                    Button("-5s") {
                        usageTimer.adjustNonLevelUsageThreshold(usageTimer.nonLevelUsageThresholdDebug - 5, isDebug: true)
                    }
                    .debugButtonStyle(.orange, size: .small)
                    
                    Button("+5s") {
                        usageTimer.adjustNonLevelUsageThreshold(usageTimer.nonLevelUsageThresholdDebug + 5, isDebug: true)
                    }
                    .debugButtonStyle(.orange, size: .small)
                }
                
                // Shake threshold
                if usageTimer.currentMode == .shakeOnly || usageTimer.currentMode == .both {
                    HStack(spacing: 8) {
                        Text("Shake: \(shakeSprintController.shakeThreshold, specifier: "%.1f")")
                            .font(.caption)
                        
                        Button("-0.5") {
                            shakeSprintController.adjustShakeThreshold(shakeSprintController.shakeThreshold - 0.5)
                        }
                        .debugButtonStyle(.purple, size: .small)
                        
                        Button("+0.5") {
                            shakeSprintController.adjustShakeThreshold(shakeSprintController.shakeThreshold + 0.5)
                        }
                        .debugButtonStyle(.purple, size: .small)
                    }
                }
                
                Button("Debug: \(usageTimer.isDebugMode ? "ON" : "OFF")") {
                    usageTimer.toggleDebugMode()
                }
                .debugButtonStyle(usageTimer.isDebugMode ? .green : .red, size: .small)
            }
            
            // Pitch testing
            VStack(spacing: 8) {
                Text("Manual Pitch Testing")
                    .font(.caption)
                
                HStack(spacing: 10) {
                    Button("Level (0°)") {
                        pitchGateModel.setMockPitch(0)
                    }
                    .debugButtonStyle(.green, size: .small)
                    
                    Button("Tilted (15°)") {
                        pitchGateModel.setMockPitch(15)
                    }
                    .debugButtonStyle(.orange, size: .small)
                    
                    Button("Real Motion") {
                        // Reset to real motion detection
                    }
                    .debugButtonStyle(.blue, size: .small)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Debug Info Section
    
    @ViewBuilder
    private var debugInfoSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("📊 Debug Info:")
                .font(.caption)
                .fontWeight(.bold)
            
            Text("Mode: \(usageTimer.currentMode.rawValue)")
            Text("Pitch: \(pitchGateModel.currentPitch, specifier: "%.1f")°")
            Text("Gate: \(pitchGateModel.isWithinThreshold ? "OPEN" : "CLOSED")")
            Text("Level Timer: \(usageTimer.isTimerActive ? "ACTIVE" : "INACTIVE")")
            
            if usageTimer.currentMode == .both {
                Text("Out of Level: \(usageTimer.isOutOfLevel ? "YES" : "NO")")
            }
            
            if usageTimer.currentMode == .shakeOnly || usageTimer.currentMode == .fitnessMode {
                Text("Non-level Usage: \(usageTimer.isNonLevelUsageActive ? "YES" : "NO")")
            }
            
            if shakeSprintController.isSprinting {
                Text("Shake Sprint: \(shakeSprintController.sprintProgress * 100, specifier: "%.0f")%")
                Text("Shake Rate: \(shakeSprintController.shakesPerSecond, specifier: "%.1f")/sec")
            }
            
            if fitnessSprintController.isSprinting {
                Text("Fitness Sprint: \(fitnessSprintController.currentExercise)")
                Text("Reps: \(fitnessSprintController.completedReps)/\(fitnessSprintController.requiredReps)")
                Text("Time: \(fitnessSprintController.sprintTimeRemaining, specifier: "%.0f")s")
            }
            
            if usageTimer.currentMode == .fitnessMode {
                Text("Fitness Accel: \(fitnessSprintController.accelerationMagnitude, specifier: "%.2f")g")
                Text("Last Movement: \(fitnessSprintController.lastMovementType)")
            } else {
                Text("Shake Accel: \(shakeSprintController.accelerationMagnitude, specifier: "%.2f")g")
            }
        }
        .font(.caption)
        .foregroundColor(.gray)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Overlay Views
    
    @ViewBuilder
    private var levelWarningOverlay: some View {
        Color.black.opacity(0.9)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 20) {
                    Image(systemName: "level")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Hold phone level")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Pitch: \(pitchGateModel.currentPitch, specifier: "%.1f")°")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            )
    }
    
    @ViewBuilder
    private var sprintOverlay: some View {
        Color.black.opacity(0.9)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 30) {
                    if shakeSprintController.isSprinting {
                        // Shake sprint UI
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .scaleEffect(1 + shakeSprintController.sprintProgress * 0.3)
                            .animation(.easeInOut(duration: 0.3), value: shakeSprintController.sprintProgress)
                        
                        Text("SHAKE TO CONTINUE!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Shake Rate: \(shakeSprintController.shakesPerSecond, specifier: "%.1f")/sec")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        ProgressView(value: shakeSprintController.sprintProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .red))
                            .frame(width: 300, height: 10)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                    } else if fitnessSprintController.isSprinting {
                        // Fitness sprint UI
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                            .scaleEffect(1 + fitnessSprintController.progress * 0.3)
                            .animation(.easeInOut(duration: 0.3), value: fitnessSprintController.progress)
                        
                        Text("DO \(fitnessSprintController.currentExercise.uppercased())!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(fitnessSprintController.completedReps)/\(fitnessSprintController.requiredReps) completed")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        if !fitnessSprintController.lastMovementType.isEmpty {
                            Text("✅ \(fitnessSprintController.lastMovementType)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        
                        ProgressView(value: fitnessSprintController.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                            .frame(width: 300, height: 10)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                        
                        Text("Time: \(fitnessSprintController.sprintTimeRemaining, specifier: "%.0f")s")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            )
    }
    
    // MARK: - Helper Methods
    
    private func handlePhoneOrientationChange() {
        usageTimer.handlePhoneOrientationChange(isLevel: pitchGateModel.isWithinThreshold)
    }
    
    private func handleAppStateChange() {
        if isAppInForeground {
            handlePhoneOrientationChange()
        } else {
            usageTimer.reset()
        }
    }
}

// MARK: - Button Styles

enum DebugButtonColor {
    case red, blue, green, orange, purple, gray
    
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .gray: return .gray
        }
    }
}

enum DebugButtonSize {
    case small, medium
    
    var padding: EdgeInsets {
        switch self {
        case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        case .medium: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        }
    }
    
    var font: Font {
        switch self {
        case .small: return .caption
        case .medium: return .subheadline
        }
    }
}

extension View {
    func debugButtonStyle(_ color: DebugButtonColor, size: DebugButtonSize = .medium) -> some View {
        self
            .font(size.font)
            .foregroundColor(.white)
            .padding(size.padding)
            .background(color.color)
            .cornerRadius(8)
    }
}

#Preview {
    ContentView()
        .environmentObject(PitchGateModel())
        .environmentObject(ShakeSprintController())
        .environmentObject(FitnessSprintController())
        .environmentObject(UsageTimer())
} 