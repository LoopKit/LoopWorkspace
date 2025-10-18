import Foundation

/// Simulates glucose patterns for testing the Octreotide algorithm
struct GlucoseSimulator {
    // Base glucose level (mg/dL)
    private var baseLevel: Double
    // Current trend direction (-1 to 1)
    private var trendDirection: Double
    // Noise amplitude (mg/dL)
    private var noiseAmplitude: Double
    
    init(baseLevel: Double = 80.0, trendDirection: Double = 0.0, noiseAmplitude: Double = 2.0) {
        self.baseLevel = baseLevel
        self.trendDirection = trendDirection
        self.noiseAmplitude = noiseAmplitude
    }
    
    /// Generate simulated glucose values
    /// - Parameters:
    ///   - count: Number of samples to generate
    ///   - intervalMinutes: Minutes between samples
    func generateSamples(count: Int, intervalMinutes: Double = 5.0) -> [Double] {
        var samples: [Double] = []
        var currentLevel = baseLevel
        
        for _ in 0..<count {
            // Add random noise
            let noise = Double.random(in: -noiseAmplitude...noiseAmplitude)
            
            // Add trend
            let trendChange = trendDirection * intervalMinutes
            
            currentLevel += trendChange + noise
            samples.append(currentLevel)
            
            // Randomly adjust trend direction slightly
            trendDirection += Double.random(in: -0.1...0.1)
            trendDirection = max(-1.0, min(1.0, trendDirection))
        }
        
        return samples
    }
    
    /// Generate a falling glucose pattern
    static func fallingPattern(from startLevel: Double = 90.0) -> GlucoseSimulator {
        return GlucoseSimulator(baseLevel: startLevel, trendDirection: -0.5)
    }
    
    /// Generate a rising glucose pattern
    static func risingPattern(from startLevel: Double = 70.0) -> GlucoseSimulator {
        return GlucoseSimulator(baseLevel: startLevel, trendDirection: 0.5)
    }
}