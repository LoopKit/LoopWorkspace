# Octreotide Algorithm Module

**IMPORTANT: Clinical Research Use Only**
This module is a prototype for research and development. It is not approved for patient use.
All implementation must be done under clinical supervision with appropriate safety protocols.

## Overview

This module provides a reverse-logic control algorithm for Octreotide (somatostatin analog) delivery via insulin pump hardware. It is designed for patients with endogenous hyperinsulinism under clinical supervision.

Key features:
- Inverted glucose response (increase delivery for low/falling glucose)
- Configurable pharmacodynamic (PD) parameters
- Multiple safety checks and limits
- Comprehensive test coverage

## Integration Steps

1. Add to Loop Project:
   - Copy `OctreotideAlgorithm.swift` to `Loop/Loop/Algorithms/` or appropriate algorithm directory
   - Copy tests to `Loop/LoopTests/Algorithms/`
   - Add files to appropriate Xcode targets

2. Wire into LoopManager:
   ```swift
   class LoopManager {
       private var octreotideAlgorithm: OctreotideAlgorithm?
       
       func initializeOctreotideMode(enabled: Bool) {
           octreotideAlgorithm = enabled ? OctreotideAlgorithm() : nil
           // Configure PD params from settings
       }
       
       func getRecommendation() -> DeliveryRecommendation {
           if let algorithm = octreotideAlgorithm {
               return algorithm.computeRecommendation(
                   glucoseNow: currentGlucose,
                   glucoseHistory: recentGlucose,
                   scheduledBasal: scheduledBasalRate,
                   lastBolusDate: lastBolusDate,
                   dailyBolusTotal: totalDailyBolus
               )
           }
           // ... normal insulin logic
       }
   }
   ```

3. Add Settings UI:
   - Toggle in Advanced Settings
   - PD parameter configuration
   - Safety warnings and confirmations

4. Testing:
   - Run unit tests
   - Simulation mode testing
   - Clinician review of outputs

## Safety Notes

1. PD Parameter Validation
   - Must have valid onset, peak, duration
   - Should be configured by clinician
   
2. Multiple Safety Checks
   - Insufficient CGM data
   - Maximum daily bolus
   - Minimum time between boluses
   - Critical low detection
   
3. Required Clinical Setup
   - Must be enabled by clinician
   - Requires acceptance of warnings
   - Should run in simulation/open-loop first

## Development Status

- [x] Core algorithm implementation
- [x] Safety checks and limits
- [x] Unit tests
- [ ] Integration with Loop
- [ ] Settings UI
- [ ] Clinical validation
- [ ] Documentation