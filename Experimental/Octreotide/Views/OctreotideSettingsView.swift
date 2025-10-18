import SwiftUI
import LoopKit

struct OctreotideSettingsView: View {
    @Binding var isEnabled: Bool
    @Binding var algorithm: OctreotideAlgorithm
    @State private var showingWarning = false
    @State private var clinicianConfirmed = false
    
    var body: some View {
        Form {
            Section(header: Text("Octreotide Mode")) {
                Toggle("Enable Octreotide Mode", isOn: $isEnabled)
                    .onChange(of: isEnabled) { newValue in
                        if newValue {
                            showingWarning = true
                        }
                    }
            }
            .alert("Important Safety Warning", isPresented: $showingWarning) {
                Button("Cancel") {
                    isEnabled = false
                }
                Button("I Understand") {
                    clinicianConfirmed = true
                }
            } message: {
                Text("This mode is for clinical research use only. It must be configured by a healthcare provider familiar with octreotide therapy. Incorrect settings can cause severe hypoglycemia or hyperglycemia.")
            }
            
            if isEnabled {
                Section(header: Text("Glucose Targets")) {
                    HStack {
                        Text("Target Range")
                        Spacer()
                        TextField("Low", value: $algorithm.targetLow, format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("-")
                        TextField("High", value: $algorithm.targetHigh, format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("mg/dL")
                    }
                    HStack {
                        Text("Critical Low")
                        Spacer()
                        TextField("Value", value: $algorithm.criticalLow, format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("mg/dL")
                    }
                }
                
                Section(header: Text("Basal Settings")) {
                    HStack {
                        Text("Minimum Basal")
                        Spacer()
                        TextField("Value", value: $algorithm.minBasal, format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("U/hr")
                    }
                    HStack {
                        Text("Maximum Basal")
                        Spacer()
                        TextField("Value", value: $algorithm.maxBasal, format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("U/hr")
                    }
                }
                
                Section(header: Text("Bolus Settings")) {
                    HStack {
                        Text("Standard Bolus")
                        Spacer()
                        TextField("Value", value: $algorithm.bolusUnit, format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("U")
                    }
                    HStack {
                        Text("Daily Maximum")
                        Spacer()
                        TextField("Value", value: $algorithm.maxDailyBolus, format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("U")
                    }
                    HStack {
                        Text("Minimum Interval")
                        Spacer()
                        TextField("Value", value: .constant(algorithm.bolusRepeatDelay / 60), format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("min")
                    }
                }
                
                Section(header: Text("Pharmacodynamics")) {
                    HStack {
                        Text("Onset Time")
                        Spacer()
                        TextField("Value", value: $algorithm.pdOnsetMinutes, format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("min")
                    }
                    HStack {
                        Text("Peak Time")
                        Spacer()
                        TextField("Value", value: $algorithm.pdPeakMinutes, format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("min")
                    }
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("Value", value: $algorithm.pdDurationMinutes, format: .number)
                            .multilineTextAlignment(.trailing)
                        Text("min")
                    }
                }
                
                if !clinicianConfirmed {
                    Section {
                        Text("⚠️ Settings must be reviewed by your healthcare provider")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .navigationTitle("Octreotide Settings")
    }
}