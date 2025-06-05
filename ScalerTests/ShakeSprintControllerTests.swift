import XCTest
import Combine
@testable import Scaler

final class ShakeSprintControllerTests: XCTestCase {
    var shakeController: ShakeSprintController!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        shakeController = ShakeSprintController()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        shakeController = nil
        cancellables = nil
    }
    
    func testInitialState() {
        XCTAssertFalse(shakeController.isSprinting)
        XCTAssertEqual(shakeController.sprintProgress, 0.0)
        XCTAssertEqual(shakeController.shakesPerSecond, 0.0)
    }
    
    func testStartShakeSprint() {
        let sprintExpectation = XCTestExpectation(description: "Sprint should start")
        
        shakeController.$isSprinting
            .dropFirst()
            .sink { isSprinting in
                if isSprinting {
                    sprintExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        shakeController.startShakeSprint()
        
        wait(for: [sprintExpectation], timeout: 1.0)
        XCTAssertTrue(shakeController.isSprinting)
        XCTAssertEqual(shakeController.sprintProgress, 0.0)
    }
    
    func testShakeDetection() {
        shakeController.startShakeSprint()
        
        let shakeExpectation = XCTestExpectation(description: "Shake should be detected")
        
        shakeController.$shakesPerSecond
            .dropFirst()
            .sink { rate in
                if rate > 0 {
                    shakeExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate multiple shakes quickly
        for _ in 0..<5 {
            shakeController.mockShake()
        }
        
        // Wait a bit for the shake rate to be calculated
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            // This will trigger the shake rate update
        }
        
        wait(for: [shakeExpectation], timeout: 2.0)
        XCTAssertGreaterThan(shakeController.shakesPerSecond, 0)
    }
    
    func testSprintProgressWithSufficientShakes() {
        shakeController.startShakeSprint()
        
        let progressExpectation = XCTestExpectation(description: "Progress should increase")
        
        shakeController.$sprintProgress
            .dropFirst()
            .sink { progress in
                if progress > 0.01 {
                    progressExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate rapid shakes (more than 3 per second)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            self.shakeController.mockShake()
            if timer.fireDate.timeIntervalSinceNow < -2.0 {
                timer.invalidate()
            }
        }
        
        wait(for: [progressExpectation], timeout: 3.0)
        XCTAssertGreaterThan(shakeController.sprintProgress, 0.0)
        
        timer.invalidate()
    }
    
    func testSprintReset() {
        shakeController.startShakeSprint()
        XCTAssertTrue(shakeController.isSprinting)
        
        // Add some progress
        for _ in 0..<10 {
            shakeController.mockShake()
        }
        
        shakeController.reset()
        
        XCTAssertFalse(shakeController.isSprinting)
        XCTAssertEqual(shakeController.sprintProgress, 0.0)
        XCTAssertEqual(shakeController.shakesPerSecond, 0.0)
    }
    
    func testDoubleStartPrevention() {
        shakeController.startShakeSprint()
        XCTAssertTrue(shakeController.isSprinting)
        
        // Try to start again
        shakeController.startShakeSprint()
        
        // Should still be sprinting, but only one instance
        XCTAssertTrue(shakeController.isSprinting)
    }
    
    func testProgressCalculation() {
        shakeController.startShakeSprint()
        
        // Progress should start at 0
        XCTAssertEqual(shakeController.sprintProgress, 0.0)
        
        // After some time and sufficient shakes, progress should increase
        let progressExpectation = XCTestExpectation(description: "Progress should increase over time")
        
        // Simulate consistent shaking at required rate
        let shakeTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            self.shakeController.mockShake()
        }
        
        // Check progress after some time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.shakeController.sprintProgress > 0.01 {
                progressExpectation.fulfill()
            }
            shakeTimer.invalidate()
        }
        
        wait(for: [progressExpectation], timeout: 3.0)
        XCTAssertGreaterThan(shakeController.sprintProgress, 0.0)
    }
} 