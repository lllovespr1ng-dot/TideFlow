import SwiftUI
import EventKit

struct PlanView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var lang: LanguageManager

    @State private var selectedDate     = Date()
    @State private var weekEvents: [Date: [EKEvent]] = [:]
    @State private var showingWeekPicker = false

    private var weekDays: [Date] {
        let cal = Calendar.current
        guard let start = cal.dateInterval(of: .weekOfYear, for: selectedDate)?.start else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private func startOfDay(_ date: Date) -> Date { Calendar.current.startOfDay(for: date) }

    /// Returns 0 for the current week (always "This Week"), otherwise the signed
    /// number of days from today to the SELECTED DAY CHIP.
    /// e.g. today = May 21, selectedDate = May 29  →  +8  →  "In 8 days"
    ///      today = May 21, selectedDate = May 15  →  -6  →  "6 days ago"
    private var weekOffsetDays: Int {
        let cal = Calendar.current
        // Same calendar week as today → label never changes from "This Week"
        guard !cal.isDate(selectedDate, equalTo: Date(), toGranularity: .weekOfYear) else { return 0 }
        // Days from today to the specific day the user tapped
        let today    = cal.startOfDay(for: Date())
        let selected = cal.startOfDay(for: selectedDate)
        return cal.dateComponents([.day], from: today, to: selected).day ?? 0
    }

    private var weekRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d LLL"        // "d LLL" → standalone nominative month (e.g. "1 май", not "1 мая")
        f.locale = lang.locale
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        return "\(f.string(from: first)) – \(f.string(from: last))"
    }

    var body: some View {
        ZStack {
            Color.tideBg.ignoresSafeArea()
            VStack(spacing: 0) {

                // ── Header: prev / week label / next ─────────────────────
                HStack(spacing: 8) {
                    // ← previous week
                    Button(action: { shiftWeek(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.tideSeafoam)
                            .frame(width: 34, height: 34)
                            .background(Color.tideSand)
                            .clipShape(Circle())
                    }

                    // Tappable week label → opens picker
                    Button(action: { showingWeekPicker = true }) {
                        VStack(spacing: 2) {
                            Text(weekRangeLabel)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.tideSeafoam)
                            // Dynamic label: "This Week" / "In 4 days" / "3 days ago"
                            Text(lang.weekOffsetLabel(days: weekOffsetDays))
                                .font(.system(size: 26, weight: .semibold, design: .rounded))
                                .foregroundColor(.tideDeep)
                                .minimumScaleFactor(0.75)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)

                    // → next week
                    Button(action: { shiftWeek(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.tideSeafoam)
                            .frame(width: 34, height: 34)
                            .background(Color.tideSand)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 16)

                // ── Day strip ────────────────────────────────────────────
                HStack(spacing: 6) {
                    ForEach(weekDays, id: \.self) { day in
                        DayChip(
                            date: day,
                            isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                            eventCount: weekEvents[startOfDay(day)]?.count ?? 0
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedDate = day }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)

                // ── Events for selected day ───────────────────────────────
                let dayEvents = weekEvents[startOfDay(selectedDate)] ?? []
                if dayEvents.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40)).foregroundColor(.tideSeafoam)
                        Text(lang.t(.open_day))
                            .font(.system(size: 18, design: .rounded)).foregroundColor(.tideDeep)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(dayEvents, id: \.eventIdentifier) { event in
                            EventCardView(event: event)
                                .listRowBackground(Color.tideBg)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteEvent(event)
                                    } label: {
                                        Label(lang.t(.delete_event), systemImage: "trash")
                                    }
                                }
                        }
                        // Bottom padding so last card clears the floating + button
                        Color.clear.frame(height: 80)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear { fetchWeekEvents() }
        .onChange(of: selectedDate) { _ in fetchWeekEvents() }
        // Re-fetch whenever CalendarManager reports a store change (e.g. Quick Add just saved)
        .onChange(of: calendarManager.lastUpdated) { _ in fetchWeekEvents() }
        // Week picker sheet
        .sheet(isPresented: $showingWeekPicker) {
            WeekPickerSheet(selectedDate: $selectedDate, isPresented: $showingWeekPicker)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Actions

    private func shiftWeek(by weeks: Int) {
        guard let newDate = Calendar.current.date(
            byAdding: .weekOfYear, value: weeks, to: selectedDate) else { return }
        withAnimation(.easeInOut(duration: 0.2)) { selectedDate = newDate }
    }

    private func deleteEvent(_ event: EKEvent) {
        try? calendarManager.deleteEvent(event)
        fetchWeekEvents()
    }

    // MARK: - Data

    private func fetchWeekEvents() {
        guard let start = weekDays.first, let last = weekDays.last,
              let end = Calendar.current.date(byAdding: .day, value: 1, to: last)
        else { return }
        let all = calendarManager.events(from: start, to: end)
        var grouped: [Date: [EKEvent]] = [:]
        for event in all { grouped[startOfDay(event.startDate), default: []].append(event) }
        weekEvents = grouped
    }
}

// MARK: - Week picker sheet

struct WeekPickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        ZStack {
            Color.tideBg.ignoresSafeArea()
            VStack(spacing: 0) {

                // Title bar
                HStack {
                    Text(lang.t(.select_week))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.tideDeep)
                    Spacer()
                    Button(lang.t(.save_label)) { isPresented = false }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.tideTeal)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 8)

                // Calendar picker — locale drives month/weekday names and their grammatical form
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.tideTeal)
                // Inject the app's chosen locale so the picker renders in Russian, Spanish, etc.
                // iOS uses the standalone/nominative month form for calendar headers automatically.
                .environment(\.locale, lang.locale)
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}

// MARK: - Day chip

struct DayChip: View {
    let date: Date
    let isSelected: Bool
    let eventCount: Int
    @EnvironmentObject var lang: LanguageManager

    private var letter: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = lang.locale
        return String(f.string(from: date).prefix(1))
    }
    private var dayNumber: String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(spacing: 4) {
            Text(letter)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .tideSeafoam)
            Text(dayNumber)
                .font(.system(size: 16, weight: isToday ? .bold : .regular, design: .rounded))
                .foregroundColor(isSelected ? .white : .tideDeep)
            Circle()
                .fill(eventCount > 0
                      ? (isSelected ? Color.white.opacity(0.7) : Color.tideTeal)
                      : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isSelected ? Color.tideTeal : Color.tideSand)
        .cornerRadius(12)
    }
}
