import XCTest
@testable import LoopKit

final class OctreotideAlgorithmTests: XCTestCase {
    var algorithm: OctreotideAlgorithm!
    
    override func setUp() {
        super.setUp()
        algorithm = OctreotideAlgorithm()
    }
    
    func testSafetyChecks() {
        // Test insufficient history
        let rec1 = algorithm.computeRecommendation(
            glucoseNow: 80,
            glucoseHistory: [80, 82], // Only 2 samples
            scheduledBasal: 1.0,
            lastBolusDate: nil,
            dailyBolusTotal: 0
        )
        XCTAssertTrue(rec1.safetyFlags.contains(.insufficientHistory))
        XCTAssertEqual(rec1.basalRate, algorithm.minBasal)
        XCTAssertEqual(rec1.bolus, 0)
        
        // Test critical low
        let rec2 = algorithm.computeRecommendation(
            glucoseNow: algorithm.criticalLow - 1,
            glucoseHistory: [70, 67, 64],
            scheduledBasal: 1.0,
            lastBolusDate: nil,
            dailyBolusTotal: 0
        )
        XCTAssertTrue(rec2.safetyFlags.contains(.criticalLow))
        XCTAssertEqual(rec2.basalRate, algorithm.maxBasal)
        XCTAssertEqual(rec2.bolus, 0)
    }
    
    func testTrendComputation() {
        // Stable glucose
        let rec1 = algorithm.computeRecommendation(
            glucoseNow: 85,
            glucoseHistory: [85, 85, 85],
            scheduledBasal: 1.0,
            lastBolusDate: nil,
            dailyBolusTotal: 0
        )
        XCTAssertEqual(rec1.trend, 0, accuracy: 0.01)
        
        // Falling glucose (-2 mg/dL/min)
        let rec2 = algorithm.computeRecommendation(
            glucoseNow: 80,
            glucoseHistory: [100, 90, 80],
            scheduledBasal: 1.0,
            lastBolusDate: nil,
            dailyBolusTotal: 0
        )
        XCTAssertEqual(rec2.trend, -2.0, accuracy: 0.01)
        XCTAssertTrue(rec2.basalRate > 1.0) // Should increase basal
    }
    
    func testBolusLimits() {
        // Test daily max
        let rec1 = algorithm.computeRecommendation(
            glucoseNow: 65,
            glucoseHistory: [75, 70, 65],
            scheduledBasal: 1.0,
            lastBolusDate: nil,
            dailyBolusTotal: algorithm.maxDailyBolus
        )
        XCTAssertTrue(rec1.safetyFlags.contains(.bolusCap))
        XCTAssertEqual(rec1.bolus, 0)
        
        // Test minimum delay
        let rec2 = algorithm.computeRecommendation(
            glucoseNow: 65,
            glucoseHistory: [75, 70, 65],
            scheduledBasal: 1.0,
            lastBolusDate: Date(),
            dailyBolusTotal: 0
        )
        XCTAssertTrue(rec2.safetyFlags.contains(.bolusDelay))
        XCTAssertEqual(rec2.bolus, 0)
    }
    
    func testBasalAdjustments() {
        // Low glucose should increase basal
        let rec1 = algorithm.computeRecommendation(
            glucoseNow: algorithm.targetLow - 1,
            glucoseHistory: [70, 69, 68],
            scheduledBasal: 1.0,
            lastBolusDate: nil,
            dailyBolusTotal: 0
        )
        XCTAssertEqual(rec1.basalRate, 1.0 * algorithm.basalMultLow)
        
        // High glucose should decrease basal
        let rec2 = algorithm.computeRecommendation(
            glucoseNow: algorithm.targetHigh + 1,
            glucoseHistory: [95, 98, 101],
            scheduledBasal: 1.0,
            lastBolusDate: nil,
            dailyBolusTotal: 0
        )
        XCTAssertEqual(rec2.basalRate, 1.0 * algorithm.basalMultHigh)
    }
    
    func testPDValidation() {
        // Invalid PD params
        algorithm.pdOnsetMinutes = 0
        let rec1 = algorithm.computeRecommendation(
            glucoseNow: 80,
            glucoseHistory: [80, 80, 80],
            scheduledBasal: 1.0,
            lastBolusDate: nil,
            dailyBolusTotal: 0
        )
        XCTAssertTrue(rec1.safetyFlags.contains(.pdParamsInvalid))
        
        // Valid PD params
        algorithm.pdOnsetMinutes = 30
        algorithm.pdPeakMinutes = 90
        algorithm.pdDurationMinutes = 240
        let rec2 = algorithm.computeRecommendation(
            glucoseNow: 80,
            glucoseHistory: [80, 80, 80],
            scheduledBasal: 1.0,
            lastBolusDate: nil,
            dailyBolusTotal: 0
        )
        XCTAssertFalse(rec2.safetyFlags.contains(.pdParamsInvalid))
    }
}