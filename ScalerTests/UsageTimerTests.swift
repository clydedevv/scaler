import XCTest
import Combine
@testable import Scaler

final class UsageTimerTests: XCTestCase {
    var usageTimer: UsageTimer!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        usageTimer = UsageTimer()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        usageTimer = nil
        cancellables = nil
    }
    
    func testInitialState() {
        XCTAssertEqual(usageTimer.totalUsageTime, 0.0)
        XCTAssertFalse(usageTimer.isTimerActive)
        XCTAssertEqual(usageTimer.progress, 0.0)
    }
    
    func testStartTimer() {
        let timerExpectation = XCTestExpectation(description: "Timer should start")
        
        usageTimer.$isTimerActive
            .dropFirst()
            .sink { isActive in
                if isActive {
                    timerExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        usageTimer.startTimer()
        
        wait(for: [timerExpectation], timeout: 1.0)
        XCTAssertTrue(usageTimer.isTimerActive)
    }
    
    func testStopTimer() {
        usageTimer.startTimer()
        XCTAssertTrue(usageTimer.isTimerActive)
        
        let stopExpectation = XCTestExpectation(description: "Timer should stop")
        
        usageTimer.$isTimerActive
            .dropFirst() // Skip the initial start
            .sink { isActive in
                if !isActive {
                    stopExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        usageTimer.stopTimer()
        
        wait(for: [stopExpectation], timeout: 1.0)
        XCTAssertFalse(usageTimer.isTimerActive)
    }
    
    func testTimeAccumulation() {
        let timeExpectation = XCTestExpectation(description: "Time should accumulate")
        
        usageTimer.$totalUsageTime
            .dropFirst()
            .sink { time in
                if time > 0 {
                    timeExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        usageTimer.startTimer()
        
        wait(for: [timeExpectation], timeout: 2.0)
        XCTAssertGreaterThan(usageTimer.totalUsageTime, 0.0)
    }
    
    func testProgressCalculation() {
        usageTimer.startTimer()
        
        let progressExpectation = XCTestExpectation(description: "Progress should increase")
        
        usageTimer.$totalUsageTime
            .dropFirst()
            .sink { _ in
                if self.usageTimer.progress > 0 {
                    progressExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [progressExpectation], timeout: 2.0)
        XCTAssertGreaterThan(usageTimer.progress, 0.0)
        XCTAssertLessThanOrEqual(usageTimer.progress, 1.0)
    }
    
    func testRemainingTime() {
        let initialRemaining = usageTimer.remainingTime
        XCTAssertEqual(initialRemaining, 30 * 60) // 30 minutes
        
        usageTimer.startTimer()
        
        let remainingExpectation = XCTestExpectation(description: "Remaining time should decrease")
        
        usageTimer.$totalUsageTime
            .dropFirst()
            .sink { _ in
                if self.usageTimer.remainingTime < initialRemaining {
                    remainingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [remainingExpectation], timeout: 2.0)
        XCTAssertLessThan(usageTimer.remainingTime, initialRemaining)
    }
    
    func testFormattedTime() {
        let formatted60 = usageTimer.formattedTime(60)
        XCTAssertEqual(formatted60, "1:00")
        
        let formatted90 = usageTimer.formattedTime(90)
        XCTAssertEqual(formatted90, "1:30")
        
        let formatted3661 = usageTimer.formattedTime(3661)
        XCTAssertEqual(formatted3661, "61:01")
    }
    
    func testReset() {
        usageTimer.startTimer()
        
        // Wait for some time accumulation
        let resetExpectation = XCTestExpectation(description: "Timer should reset")
        
        usageTimer.$totalUsageTime
            .dropFirst()
            .sink { time in
                if time > 0 {
                    self.usageTimer.reset()
                    resetExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [resetExpectation], timeout: 2.0)
        
        XCTAssertEqual(usageTimer.totalUsageTime, 0.0)
        XCTAssertFalse(usageTimer.isTimerActive)
    }
    
    func testDoubleStartPrevention() {
        usageTimer.startTimer()
        XCTAssertTrue(usageTimer.isTimerActive)
        
        // Try to start again
        usageTimer.startTimer()
        
        // Should still be active, but only one timer instance
        XCTAssertTrue(usageTimer.isTimerActive)
    }
    
    func testShakeSprintTrigger() {
        let notificationExpectation = XCTestExpectation(description: "Should trigger shake sprint notification")
        
        NotificationCenter.default.addObserver(
            forName: .shouldStartShakeSprint,
            object: nil,
            queue: .main
        ) { _ in
            notificationExpectation.fulfill()
        }
        
        // Manually set usage time to trigger condition
        usageTimer.totalUsageTime = 30 * 60 - 1 // Almost at target
        usageTimer.startTimer()
        
        wait(for: [notificationExpectation], timeout: 3.0)
    }
} 