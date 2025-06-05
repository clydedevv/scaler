import XCTest
import Combine
@testable import Scaler

final class PitchGateModelTests: XCTestCase {
    var pitchGateModel: PitchGateModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        pitchGateModel = PitchGateModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        pitchGateModel = nil
        cancellables = nil
    }
    
    func testInitialState() {
        XCTAssertFalse(pitchGateModel.isWithinThreshold)
        XCTAssertEqual(pitchGateModel.currentPitch, 0.0)
        XCTAssertEqual(pitchGateModel.thresholdLow, -10.0)
        XCTAssertEqual(pitchGateModel.thresholdHigh, 10.0)
    }
    
    func testPitchWithinThreshold() {
        let expectation = XCTestExpectation(description: "Pitch gate should open")
        
        pitchGateModel.$isWithinThreshold
            .dropFirst() // Skip initial value
            .sink { isWithin in
                if isWithin {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Set pitch within threshold
        pitchGateModel.setMockPitch(5.0)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(pitchGateModel.isWithinThreshold)
        XCTAssertEqual(pitchGateModel.currentPitch, 5.0)
    }
    
    func testPitchOutsideThreshold() {
        let expectation = XCTestExpectation(description: "Pitch gate should remain closed")
        
        // First set within threshold
        pitchGateModel.setMockPitch(5.0)
        XCTAssertTrue(pitchGateModel.isWithinThreshold)
        
        pitchGateModel.$isWithinThreshold
            .dropFirst() // Skip current value
            .sink { isWithin in
                if !isWithin {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Set pitch outside threshold
        pitchGateModel.setMockPitch(15.0)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(pitchGateModel.isWithinThreshold)
        XCTAssertEqual(pitchGateModel.currentPitch, 15.0)
    }
    
    func testNegativePitchWithinThreshold() {
        pitchGateModel.setMockPitch(-8.0)
        XCTAssertTrue(pitchGateModel.isWithinThreshold)
        XCTAssertEqual(pitchGateModel.currentPitch, -8.0)
    }
    
    func testNegativePitchOutsideThreshold() {
        pitchGateModel.setMockPitch(-15.0)
        XCTAssertFalse(pitchGateModel.isWithinThreshold)
        XCTAssertEqual(pitchGateModel.currentPitch, -15.0)
    }
    
    func testBoundaryValues() {
        // Test exact threshold values
        pitchGateModel.setMockPitch(-10.0) // Exact low threshold
        XCTAssertTrue(pitchGateModel.isWithinThreshold)
        
        pitchGateModel.setMockPitch(10.0) // Exact high threshold
        XCTAssertTrue(pitchGateModel.isWithinThreshold)
        
        pitchGateModel.setMockPitch(-10.1) // Just below low threshold
        XCTAssertFalse(pitchGateModel.isWithinThreshold)
        
        pitchGateModel.setMockPitch(10.1) // Just above high threshold
        XCTAssertFalse(pitchGateModel.isWithinThreshold)
    }
    
    func testThresholdAdjustment() {
        // Change thresholds
        pitchGateModel.thresholdLow = -5.0
        pitchGateModel.thresholdHigh = 5.0
        
        // Test with new thresholds
        pitchGateModel.setMockPitch(8.0) // Should be outside new threshold
        XCTAssertFalse(pitchGateModel.isWithinThreshold)
        
        pitchGateModel.setMockPitch(3.0) // Should be within new threshold
        XCTAssertTrue(pitchGateModel.isWithinThreshold)
    }
} 