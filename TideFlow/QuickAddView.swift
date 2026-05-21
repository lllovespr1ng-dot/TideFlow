import SwiftUI
import EventKit

// MARK: - Duration choice model

enum DurationChoice: Equatable {
    case preset(Int)               // fixed minutes
    case custom(hours: Int, mins: Int)
    case allDay

    var label: String {
        switch self {
        case .preset(let m):
            if m < 60 { return "\(m)m" }
            let h = m / 60, rem = m % 60
            return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
        case .custom(let h, let m):
            if h == 0 { return "\(m)m" }
            return m == 0 ? "\(h)h" : "\(h)h \(m)m"
        case .allDay:
            return "—"   // replaced by localised string at call site
        }
    }

    var minutes: Int {
        switch self {
        case .preset(let m): return m
        case .custom(let h, let m): return h * 60 + m
        case .allDay: return 0  // computed dynamically
        }
    }
}

// MARK: - Main view

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var lang: LanguageManager

    @State private var title      = ""
    @State private var date:      Date
    @State private var startTime  = Date()
    @State private var choice: DurationChoice = .preset(60)

    init(initialDate: Date = Date()) {
        _date = State(initialValue: initialDate)
    }
    @State private var isSaving   = false
    @State private var showError  = false
    @State private var showCustomPicker = false

    // Custom wheel state
    @State private var customHours = 1
    @State private var customMins  = 0

    @FocusState private var titleFocused: Bool

    private let presets = [15, 30, 45, 60, 90, 120]

    var body: some View {
        NavigationView {
            ZStack {
                Color.tideBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // Title
                        fieldBlock(label: lang.t(.event_name)) {
                            TextField(lang.t(.whats_happening), text: $title)
                                .font(.system(size: 17, design: .rounded))
                                .focused($titleFocused)
                        }

                        // Date
                        fieldBlock(label: lang.t(.date_label)) {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.compact).labelsHidden()
                        }

                        // Start time
                        fieldBlock(label: lang.t(.start_time)) {
                            DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact).labelsHidden()
                        }

                        // Duration chips
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel(lang.t(.duration_label))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {

                                    // Fixed presets
                                    ForEach(presets, id: \.self) { m in
                                        chip(label: lang.durationLabel(m),
                                             selected: choice == .preset(m)) {
                                            choice = .preset(m)
                                        }
                                    }

                                    // Custom
                                    chip(label: customChipLabel, selected: isCustomSelected,
                                         icon: "slider.horizontal.3") {
                                        showCustomPicker = true
                                    }

                                    // All Day
                                    chip(label: lang.t(.all_day_label), selected: choice == .allDay,
                                         icon: "sun.max.fill") {
                                        choice = .allDay
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }

                        // Save
                        Button(action: saveEvent) {
                            Group {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(lang.t(.add_to_calendar))
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(title.isEmpty ? Color.tideSeafoam.opacity(0.5) : Color.tideTeal)
                            .cornerRadius(16)
                        }
                        .disabled(title.isEmpty || isSaving)
                        .padding(.top, 4)
                    }
                    .padding()
                }
            }
            .navigationTitle(lang.t(.quick_add))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.t(.cancel_label)) { dismiss() }.foregroundColor(.tideSeafoam)
                }
            }
        }
        .onAppear { titleFocused = true }
        .alert("Couldn't save the event", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        }
        // Custom duration bottom sheet
        .sheet(isPresented: $showCustomPicker) {
            customDurationSheet
        }
    }

    // MARK: - Custom duration sheet

    private var customDurationSheet: some View {
        VStack(spacing: 24) {
            Text(lang.t(.custom_label))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.tideDeep)
                .padding(.top, 20)

            HStack(spacing: 0) {
                // Hours wheel
                VStack(spacing: 4) {
                    Picker("", selection: $customHours) {
                        ForEach(0...8, id: \.self) { h in
                            Text("\(h) \(lang.t(.hour_abbr))").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                }

                // Minutes wheel
                VStack(spacing: 4) {
                    Picker("", selection: $customMins) {
                        ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { m in
                            Text("\(m) \(lang.t(.min_abbr))").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                }
            }
            .padding(.horizontal)

            Button(action: {
                choice = .custom(hours: customHours, mins: customMins)
                showCustomPicker = false
            }) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.tideTeal).cornerRadius(14)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color.tideBg)
        .presentationDetents([.height(300)])
    }

    // MARK: - Save

    private func saveEvent() {
        isSaving = true
        let cal   = Calendar.current
        var dc    = cal.dateComponents([.year, .month, .day], from: date)
        let tc    = cal.dateComponents([.hour, .minute], from: startTime)
        dc.hour   = tc.hour; dc.minute = tc.minute
        guard let eventStart = cal.date(from: dc) else { isSaving = false; return }

        let durationMins: Int
        if choice == .allDay {
            // Remaining time until 23:59 of the chosen date
            var endDC = cal.dateComponents([.year, .month, .day], from: date)
            endDC.hour = 23; endDC.minute = 59
            let endOfDay = cal.date(from: endDC) ?? eventStart
            durationMins = max(30, Int(endOfDay.timeIntervalSince(eventStart) / 60))
        } else {
            durationMins = choice.minutes > 0 ? choice.minutes : 60
        }

        let eventEnd = eventStart.addingTimeInterval(Double(durationMins * 60))
        do {
            try calendarManager.createEvent(title: title, startDate: eventStart, endDate: eventEnd)
            dismiss()
        } catch {
            showError = true
        }
        isSaving = false
    }

    // MARK: - Chip helpers

    private var isCustomSelected: Bool {
        if case .custom = choice { return true }
        return false
    }

    private var customChipLabel: String {
        if case .custom(let h, let m) = choice {
            return lang.durationLabel(h * 60 + m)
        }
        return lang.t(.custom_label)
    }

    @ViewBuilder
    private func chip(label: String, selected: Bool, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.system(size: 11)) }
                Text(label).font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundColor(selected ? .white : .tideDeep)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(selected ? Color.tideTeal : Color.tideSand)
            .cornerRadius(10)
        }
    }

    // MARK: - Layout helpers

    @ViewBuilder
    private func fieldBlock<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(label)
            content()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tideSand).cornerRadius(12)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(.tideSeafoam).tracking(1.5)
    }
}
