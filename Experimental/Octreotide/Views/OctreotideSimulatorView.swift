import SwiftUI
import Charts

struct OctreotideSimulatorView: View {
    @State private var algorithm = OctreotideAlgorithm()
    @State private var glucoseValues: [Double] = []
    @State private var recommendations: [DeliveryRecommendation] = []
    @State private var simulationMode: String = "stable"
    @State private var isSimulating = false
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Picker("Simulation Mode", selection: $simulationMode) {
                Text("Stable").tag("stable")
                Text("Falling").tag("falling")
                Text("Rising").tag("rising")
            }
            .pickerStyle(.segmented)
            .padding()
            
            if !glucoseValues.isEmpty {
                Chart {
                    ForEach(Array(glucoseValues.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Glucose", value)
                        )
                    }
                }
                .frame(height: 200)
                .padding()
            }
            
            if let latest = recommendations.last {
                VStack(alignment: .leading) {
                    Text("Latest Recommendation:")
                        .font(.headline)
                    Text("Basal Rate: \(latest.basalRate, specifier: "%.2f") U/hr")
                    Text("Bolus: \(latest.bolus, specifier: "%.2f") U")
                    Text("Trend: \(latest.trend, specifier: "%.2f") mg/dL/min")
                    if !latest.messages.isEmpty {
                        Text("Messages:")
                        ForEach(latest.messages, id: \.self) { message in
                            Text("• \(message)")
                                .foregroundColor(.secondary)
                        }
                    }
                    if !latest.safetyFlags.isEmpty {
                        Text("Safety Flags:")
                            .foregroundColor(.red)
                        ForEach(Array(latest.safetyFlags), id: \.rawValue) { flag in
                            Text("⚠️ \(flag.rawValue)")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
            }
            
            Button(isSimulating ? "Stop Simulation" : "Start Simulation") {
                isSimulating.toggle()
                if isSimulating {
                    startSimulation()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onReceive(timer) { _ in
            if isSimulating {
                updateSimulation()
            }
        }
    }
    
    private func startSimulation() {
        glucoseValues = []
        recommendations = []
        
        let simulator: GlucoseSimulator
        switch simulationMode {
        case "falling":
            simulator = .fallingPattern()
        case "rising":
            simulator = .risingPattern()
        default:
            simulator = GlucoseSimulator()
        }
        
        glucoseValues = simulator.generateSamples(count: 3)
        updateRecommendation()
    }
    
    private func updateSimulation() {
        let simulator: GlucoseSimulator
        switch simulationMode {
        case "falling":
            simulator = .fallingPattern(from: glucoseValues.last ?? 90.0)
        case "rising":
            simulator = .risingPattern(from: glucoseValues.last ?? 70.0)
        default:
            simulator = GlucoseSimulator(baseLevel: glucoseValues.last ?? 80.0)
        }
        
        let newValue = simulator.generateSamples(count: 1)[0]
        glucoseValues.append(newValue)
        
        // Keep last 12 values (1 hour at 5-min intervals)
        if glucoseValues.count > 12 {
            glucoseValues.removeFirst()
        }
        
        updateRecommendation()
    }
    
    private func updateRecommendation() {
        guard glucoseValues.count >= 3 else { return }
        
        let recommendation = algorithm.computeRecommendation(
            glucoseNow: glucoseValues.last!,
            glucoseHistory: glucoseValues,
            scheduledBasal: 1.0,
            lastBolusDate: nil,
            dailyBolusTotal: 0
        )
        
        recommendations.append(recommendation)
        
        // Keep last 12 recommendations
        if recommendations.count > 12 {
            recommendations.removeFirst()
        }
    }
}