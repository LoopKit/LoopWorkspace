// OctreotideAlgorithm.swift
// Reverse-Logic control module for Octreotide infusion
// Designed as a drop-in module for Loop (developer preview, simulation only).
// IMPORTANT: This is a clinical experiment template. Do NOT run closed-loop on a patient without
// rigorous simulation, clinical oversight, and regulatory/safety approval.

import Foundation

/// Represents a recommended change in medication delivery
struct DeliveryRecommendation {
    let basalRate: Double  // U/hr
    let bolus: Double      // U
    let messages: [String] // User/clinician messages
    let trend: Double      // mg/dL/min
    let safetyFlags: Set<SafetyFlag>
    
    enum SafetyFlag: String {
        case insufficientHistory = "Insufficient glucose history"
        case rapidChange = "Rapid glucose change detected"
        case bolusCap = "Daily bolus cap reached"
        case bolusDelay = "Minimum time between boluses not met"
        case criticalLow = "Critical low glucose"
        case pdParamsInvalid = "PD parameters invalid or missing"
    }
}

/// Algorithm for Octreotide (somatostatin analog) delivery based on CGM trend
struct OctreotideAlgorithm {
    // MARK: - Tunable parameters (clinician-adjustable)
    
    /// Glucose target range (mg/dL)
    var targetLow: Double = 70.0
    var targetHigh: Double = 100.0
    var criticalLow: Double = 65.0
    
    /// Basal delivery limits (U/hr)
    var minBasal: Double = 0.25
    var maxBasal: Double = 5.0
    
    /// Basal multipliers for different glucose ranges
    var basalMultLow: Double = 1.5   // Multiply scheduled basal by this when low
    var basalMultHigh: Double = 0.5  // Multiply by this when high/rising
    
    /// Trend thresholds (mg/dL per min) - negative is falling
    var trendFallFast: Double = -1.0
    var trendRiseFast: Double = 1.0
    
    /// Bolus configuration
    var bolusUnit: Double = 1.0  // Standard bolus size (U)
    var bolusRepeatDelay: TimeInterval = 15 * 60  // Min seconds between boluses
    var maxDailyBolus: Double = 30.0  // Maximum total bolus units per day
    
    /// Pharmacodynamic parameters (required for safety)
    var pdOnsetMinutes: Double = 30.0  // Time to start of action
    var pdPeakMinutes: Double = 90.0   // Time to peak action  
    var pdDurationMinutes: Double = 240.0 // Total duration of action
    
    // MARK: - Utility
    
    private func clamp(_ value: Double, _ minVal: Double, _ maxVal: Double) -> Double {
        return max(minVal, min(value, maxVal))
    }
    
    /// Compute trend in mg/dL per minute using 3 samples
    /// - Parameter glucoseHistory: Ordered oldest to newest, ~5min spacing
    private func computeTrendRate(glucoseHistory: [Double]) -> Double {
        guard glucoseHistory.count >= 3 else { return 0.0 }
        let last = glucoseHistory[glucoseHistory.count - 1]
        let thirdLast = glucoseHistory[glucoseHistory.count - 3]
        // Approximate over ~10 minutes
        return (last - thirdLast) / 10.0
    }
    
    /// Validate PD parameters are present and reasonable
    private func validatePDParams() -> Bool {
        guard pdOnsetMinutes > 0,
              pdPeakMinutes > pdOnsetMinutes,
              pdDurationMinutes > pdPeakMinutes else {
            return false
        }
        return true
    }
    
    /// Main recommendation function
    /// - Parameters:
    ///   - glucoseNow: Current glucose in mg/dL
    ///   - glucoseHistory: Recent glucose samples (mg/dL), oldest->newest, ~5min spacing
    ///   - scheduledBasal: Current scheduled basal rate (U/hr)
    ///   - lastBolusDate: Time of last bolus (if any)
    ///   - dailyBolusTotal: Total bolus units given today
    /// - Returns: Recommended basal rate, bolus amount, and status messages
    func computeRecommendation(
        glucoseNow: Double,
        glucoseHistory: [Double],
        scheduledBasal: Double,
        lastBolusDate: Date?,
        dailyBolusTotal: Double
    ) -> DeliveryRecommendation {
        // Start with current basal as baseline
        var recommendedBasal = scheduledBasal
        var recommendedBolus: Double = 0.0
        var messages: [String] = []
        var safetyFlags: Set<DeliveryRecommendation.SafetyFlag> = []
        
        // Compute trend (mg/dL/min)
        let trend = computeTrendRate(glucoseHistory: glucoseHistory)
        
        // MARK: Safety Checks
        
        // 1. Check glucose history
        guard glucoseHistory.count >= 3 else {
            safetyFlags.insert(.insufficientHistory)
            return DeliveryRecommendation(
                basalRate: minBasal,
                bolus: 0,
                messages: ["Insufficient glucose history for safe automation"],
                trend: 0,
                safetyFlags: safetyFlags
            )
        }
        
        // 2. Validate PD parameters
        guard validatePDParams() else {
            safetyFlags.insert(.pdParamsInvalid)
            return DeliveryRecommendation(
                basalRate: minBasal,
                bolus: 0,
                messages: ["Invalid pharmacodynamic parameters - check configuration"],
                trend: trend,
                safetyFlags: safetyFlags
            )
        }
        
        // 3. Check for rapid changes
        if abs(trend) > max(abs(trendFallFast), abs(trendRiseFast)) {
            safetyFlags.insert(.rapidChange)
            messages.append("Rapid glucose change detected")
        }
        
        // 4. Check critical low
        if glucoseNow <= criticalLow {
            safetyFlags.insert(.criticalLow)
            // Max out basal but no bolus
            recommendedBasal = maxBasal
            messages.append("Critical low - maximizing basal delivery")
            return DeliveryRecommendation(
                basalRate: recommendedBasal,
                bolus: 0,
                messages: messages,
                trend: trend,
                safetyFlags: safetyFlags
            )
        }
        
        // MARK: Basal Adjustments
        
        // Adjust basal rate based on current glucose and trend
        if glucoseNow < targetLow || trend < trendFallFast {
            // Low or falling fast - increase basal
            recommendedBasal = scheduledBasal * basalMultLow
            messages.append("Increasing basal due to low/falling glucose")
        } else if glucoseNow > targetHigh || trend > trendRiseFast {
            // High or rising fast - decrease basal
            recommendedBasal = scheduledBasal * basalMultHigh
            messages.append("Decreasing basal due to high/rising glucose")
        }
        
        // Clamp basal rate to limits
        recommendedBasal = clamp(recommendedBasal, minBasal, maxBasal)
        
        // MARK: Bolus Logic
        
        // Helper to check bolus eligibility
        func canGiveBolus() -> Bool {
            if dailyBolusTotal + bolusUnit > maxDailyBolus {
                safetyFlags.insert(.bolusCap)
                return false
            }
            if let last = lastBolusDate {
                if Date().timeIntervalSince(last) < bolusRepeatDelay {
                    safetyFlags.insert(.bolusDelay)
                    return false
                }
            }
            return true
        }
        
        // Consider bolus for significant lows or rapid drops
        if (glucoseNow < targetLow && trend < 0) || trend < trendFallFast {
            if canGiveBolus() {
                recommendedBolus = bolusUnit
                messages.append("Recommending bolus for low/falling glucose")
            } else {
                messages.append("Bolus indicated but safety cap prevents delivery")
            }
        }
        
        return DeliveryRecommendation(
            basalRate: recommendedBasal,
            bolus: recommendedBolus,
            messages: messages,
            trend: trend,
            safetyFlags: safetyFlags
        )
    }
}