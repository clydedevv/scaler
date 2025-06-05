import SwiftUI

struct ContentView: View {
    @EnvironmentObject var pitchGateModel: PitchGateModel
    @EnvironmentObject var shakeSprintController: ShakeSprintController
    @EnvironmentObject var usageTimer: UsageTimer
    @State private var isAppInForeground = true
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 20) {
                Text("Hello, Scaler!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if pitchGateModel.isWithinThreshold {
                    VStack(spacing: 10) {
                        Text("Usage Time: \(usageTimer.formattedTime(usageTimer.totalUsageTime))")
                            .font(.headline)
                        
                        Text("Remaining: \(usageTimer.formattedTime(usageTimer.remainingTime))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        ProgressView(value: usageTimer.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 200)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Debug info
                VStack(alignment: .leading, spacing: 5) {
                    Text("Pitch: \(pitchGateModel.currentPitch, specifier: "%.1f")°")
                    Text("Gate: \(pitchGateModel.isWithinThreshold ? "OPEN" : "CLOSED")")
                    Text("Timer: \(usageTimer.isTimerActive ? "ACTIVE" : "INACTIVE")")
                    if shakeSprintController.isSprinting {
                        Text("Shake Rate: \(shakeSprintController.shakesPerSecond, specifier: "%.1f")/sec")
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding()
            }
            .padding()
            
            // Gate closed overlay
            if !pitchGateModel.isWithinThreshold && !shakeSprintController.isSprinting {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 20) {
                            Image(systemName: "level")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Hold phone level")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Keep between \(pitchGateModel.thresholdLow, specifier: "%.0f")° and \(pitchGateModel.thresholdHigh, specifier: "%.0f")°")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            Text("Current: \(pitchGateModel.currentPitch, specifier: "%.1f")°")
                                .font(.headline)
                                .foregroundColor(pitchGateModel.isWithinThreshold ? .green : .red)
                        }
                    )
            }
            
            // Sprint overlay
            if shakeSprintController.isSprinting {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 30) {
                            Text("Shake Sprint!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                                    .frame(width: 200, height: 200)
                                
                                Circle()
                                    .trim(from: 0, to: shakeSprintController.sprintProgress)
                                    .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 200, height: 200)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.3), value: shakeSprintController.sprintProgress)
                                
                                VStack {
                                    Text("\(Int(shakeSprintController.sprintProgress * 100))%")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("\(shakeSprintController.shakesPerSecond, specifier: "%.1f") shakes/sec")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Need 3.0/sec")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            Text("Keep shaking!")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            isAppInForeground = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            isAppInForeground = false
            usageTimer.stopTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .shouldStartShakeSprint)) { _ in
            shakeSprintController.startShakeSprint()
        }
        .onChange(of: pitchGateModel.isWithinThreshold) { isWithin in
            if isWithin && isAppInForeground {
                usageTimer.startTimer()
            } else {
                usageTimer.stopTimer()
            }
        }
        .onChange(of: isAppInForeground) { inForeground in
            if inForeground && pitchGateModel.isWithinThreshold {
                usageTimer.startTimer()
            } else {
                usageTimer.stopTimer()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PitchGateModel())
        .environmentObject(ShakeSprintController())
        .environmentObject(UsageTimer())
} 