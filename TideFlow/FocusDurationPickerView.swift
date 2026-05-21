import SwiftUI

/// Bottom sheet shown before starting a focus session — lets the user pick duration.
struct FocusDurationPickerView: View {
    let task: BrainDumpTask
    let onStart: (Int) -> Void   // passes chosen minutes

    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) private var dismiss

    // Remembered from last session
    @State private var selectedMinutes: Int = UserDefaults.standard.integer(forKey: "lastFocusDuration") == 0
                                              ? 25
                                              : UserDefaults.standard.integer(forKey: "lastFocusDuration")
    @State private var showCustomWheel = false
    @State private var customHours = 0
    @State private var customMins  = 25

    private let presets = [3, 5, 10, 20, 25, 30, 40, 60, 90, 180]

    var body: some View {
        ZStack {
            Color.tideBg.ignoresSafeArea()

            VStack(spacing: 0) {

                // Handle bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.tideSeafoam.opacity(0.4))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // Task name
                VStack(spacing: 4) {
                    Text(lang.t(.focusing_on))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.tideSeafoam)
                    Text(task.title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.tideDeep)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 24)

                // Duration presets
                Text(lang.t(.duration_label).uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.tideSeafoam)
                    .tracking(1.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                // Preset chips grid (2 rows)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                    GridItem(.flexible()), GridItem(.flexible()),
                                    GridItem(.flexible())], spacing: 8) {
                    ForEach(presets, id: \.self) { m in
                        durationChip(label: minuteLabel(m), selected: selectedMinutes == m && !isCustomActive) {
                            selectedMinutes = m
                        }
                    }
                    // Custom chip
                    durationChip(
                        label: isCustomActive ? minuteLabel(selectedMinutes) : lang.t(.custom_label),
                        selected: isCustomActive,
                        icon: "slider.horizontal.3"
                    ) {
                        showCustomWheel = true
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 20)

                // Start button
                Button(action: {
                    UserDefaults.standard.set(selectedMinutes, forKey: "lastFocusDuration")
                    onStart(selectedMinutes)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 14))
                        Text("Start · \(minuteLabel(selectedMinutes))")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.tideTeal)
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showCustomWheel) {
            customWheelSheet
        }
    }

    // MARK: - Custom wheel

    private var customWheelSheet: some View {
        VStack(spacing: 20) {
            Text(lang.t(.custom_label))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.tideDeep)
                .padding(.top, 20)

            HStack(spacing: 0) {
                Picker("", selection: $customHours) {
                    ForEach(0...5, id: \.self) { h in
                        Text("\(h) \(lang.t(.hour_abbr))").tag(h)
                    }
                }
                .pickerStyle(.wheel).frame(maxWidth: .infinity, maxHeight: 150)

                Picker("", selection: $customMins) {
                    ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { m in
                        Text("\(m) \(lang.t(.min_abbr))").tag(m)
                    }
                }
                .pickerStyle(.wheel).frame(maxWidth: .infinity, maxHeight: 150)
            }
            .padding(.horizontal)

            Button("Done") {
                let total = customHours * 60 + customMins
                selectedMinutes = max(1, total)
                showCustomWheel = false
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(Color.tideTeal).cornerRadius(14)
            .padding(.horizontal).padding(.bottom, 20)
        }
        .background(Color.tideBg)
        .presentationDetents([.height(300)])
    }

    // MARK: - Helpers

    private var isCustomActive: Bool {
        !presets.contains(selectedMinutes)
    }

    private func minuteLabel(_ m: Int) -> String {
        lang.durationLabel(m)
    }

    @ViewBuilder
    private func durationChip(label: String, selected: Bool, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                if let icon { Image(systemName: icon).font(.system(size: 11)) }
                Text(label).font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(selected ? .white : .tideDeep)
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(selected ? Color.tideTeal : Color.tideSand)
            .cornerRadius(10)
        }
    }
}

private let minuteLabelHelper: (Int) -> String = { m in
    if m < 60 { return "\(m)m" }
    let h = m / 60, rem = m % 60
    return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
}
