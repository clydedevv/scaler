import XCTest
import Combine
@testable import Scaler

final class IntegrationTests: XCTestCase {
    var pitchGateModel: PitchGateModel!
    var shakeSprintController: ShakeSprintController!
    var usageTimer: UsageTimer!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        pitchGateModel = PitchGateModel()
        shakeSprintController = ShakeSprintController()
        usageTimer = UsageTimer()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        pitchGateModel = nil
        shakeSprintController = nil
        usageTimer = nil
        cancellables = nil
    }
    
    func testDirectShakeSprintTrigger() {
        let workflowExpectation = XCTestExpectation(description: "Direct sprint trigger and completion")
        
        // Monitor sprint completion
        shakeSprintController.$sprintProgress
            .sink { progress in
                if progress >= 1.0 {
                    workflowExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        print("🚀 Starting direct sprint test...")
        
        // Directly trigger the shake sprint (simulating timer completion)
        usageTimer.triggerShakeSprintNow()
        
        // Wait for sprint to start, then simulate rapid shaking
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🤝 Simulating rapid shaking...")
            // Simulate rapid shaking to complete the sprint
            for i in 0..<60 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    self.shakeSprintController.mockShake()
                    if self.shakeSprintController.sprintProgress >= 1.0 {
                        print("✅ Sprint completed successfully!")
                    }
                }
            }
        }
        
        wait(for: [workflowExpectation], timeout: 10.0)
        
        // Verify final state
        XCTAssertFalse(shakeSprintController.isSprinting)
        XCTAssertEqual(shakeSprintController.sprintProgress, 1.0, accuracy: 0.01)
    }
    
    func testQuickShakeSprintOnly() {
        let sprintExpectation = XCTestExpectation(description: "Quick shake sprint test")
        
        // Start sprint immediately
        shakeSprintController.startShakeSprint()
        
        // Monitor completion
        shakeSprintController.$sprintProgress
            .sink { progress in
                if progress >= 1.0 {
                    sprintExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate very rapid shaking (more than 3/sec)
        for i in 0..<100 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                self.shakeSprintController.mockShake()
            }
        }
        
        wait(for: [sprintExpectation], timeout: 8.0)
        XCTAssertEqual(shakeSprintController.sprintProgress, 1.0, accuracy: 0.01)
    }
    
    func testUsageTimerFunctionality() {
        let timerExpectation = XCTestExpectation(description: "Usage timer should accumulate time")
        
        var timeAccumulated = false
        
        usageTimer.$totalUsageTime
            .sink { time in
                if time > 0 && !timeAccumulated {
                    timeAccumulated = true
                    timerExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start timer directly (simulating level device)
        usageTimer.startTimer()
        
        wait(for: [timerExpectation], timeout: 3.0)
        XCTAssertTrue(usageTimer.isTimerActive)
        XCTAssertGreaterThan(usageTimer.totalUsageTime, 0)
    }
    
    func testShakeSprintProgress() {
        let progressExpectation = XCTestExpectation(description: "Sprint progress should increase with sufficient shakes")
        
        shakeSprintController.startShakeSprint()
        
        var progressIncreased = false
        
        shakeSprintController.$sprintProgress
            .sink { progress in
                if progress > 0.1 && !progressIncreased {
                    progressIncreased = true
                    progressExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate consistent rapid shaking (4 shakes/second)
        for i in 0..<20 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) {
                self.shakeSprintController.mockShake()
            }
        }
        
        wait(for: [progressExpectation], timeout: 8.0)
        XCTAssertGreaterThan(shakeSprintController.sprintProgress, 0.1)
    }
    
    func testTimerReset() {
        // Start timer and accumulate some time
        usageTimer.startTimer()
        
        let resetExpectation = XCTestExpectation(description: "Timer should reset")
        
        usageTimer.$totalUsageTime
            .sink { time in
                if time > 1.0 {
                    self.usageTimer.reset()
                    resetExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [resetExpectation], timeout: 3.0)
        
        XCTAssertEqual(usageTimer.totalUsageTime, 0.0)
        XCTAssertFalse(usageTimer.isTimerActive)
    }
} 