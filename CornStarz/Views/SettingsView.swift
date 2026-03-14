import SwiftUI

enum ReleaseMode: String, CaseIterable {
    case thumbLift = "Thumb Lift"
    case autoDetect = "Auto Detect"
    case buttonTap = "Button Tap"
}

struct SettingsView: View {
    @AppStorage("sensitivity") private var sensitivity: Double = 0.5
    @AppStorage("releaseMode") private var releaseMode: String = ReleaseMode.thumbLift.rawValue
    @AppStorage("showSafetyWarning") private var showSafetyWarning: Bool = true

    var body: some View {
        Form {
            Section("Throw Settings") {
                VStack(alignment: .leading) {
                    Text("Sensitivity: \(sensitivity, specifier: "%.1f")")
                    Slider(value: $sensitivity, in: 0.1...1.0, step: 0.1)
                }

                Picker("Release Mode", selection: $releaseMode) {
                    ForEach(ReleaseMode.allCases, id: \.rawValue) { mode in
                        Text(mode.rawValue).tag(mode.rawValue)
                    }
                }
            }

            Section("Safety") {
                Toggle("Show Wrist Strap Reminder", isOn: $showSafetyWarning)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Developer", value: "LNH Enterprises LLC")
            }
        }
        .navigationTitle("Settings")
    }
}
