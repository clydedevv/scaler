import SwiftUI

@main
struct ScalerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(PitchGateModel())
                .environmentObject(ShakeSprintController())
                .environmentObject(UsageTimer())
        }
    }
} 