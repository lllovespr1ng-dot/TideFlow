import SwiftUI
import EventKit
import Combine

struct NowView: View {
    @EnvironmentObject var calendarManager:     CalendarManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var lang:                LanguageManager

    @State private var showingSettings = false
    @State private var now = Date()   // updated every minute → forces re-render & fresh greeting
    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var greeting: String {
        switch Calendar.current.component(.hour, from: now) {
        case 0..<5:  return lang.t(.greeting_night)
        case 5..<12: return lang.t(.greeting_morning)
        case 12..<17: return lang.t(.greeting_afternoon)
        default:     return lang.t(.greeting_evening)
        }
    }

    private var ringTotal: Int {
        guard let event = calendarManager.nextEvent else { return 60 }
        let mins = calendarManager.minutesUntil(event)
        return mins > 0 ? min(120, max(30, mins * 2))
                        : max(1, Int(event.endDate.timeIntervalSince(event.startDate) / 60))
    }

    var body: some View {
        ZStack {
            Color.tideBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // ── Header ──────────────────────────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(greeting)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.tideSeafoam)
                            Text(lang.t(.right_now))
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundColor(.tideDeep)
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            Button { calendarManager.fetchTodayEvents() } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.tideSeafoam)
                                    .padding(10)
                                    .background(Color.tideSand)
                                    .clipShape(Circle())
                            }
                            Button { showingSettings = true } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.tideSeafoam)
                                    .padding(10)
                                    .background(Color.tideSand)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // ── Main content ─────────────────────────────────────────
                    switch calendarManager.authorizationStatus {
                    case .notDetermined:
                        permissionCard
                    case .denied, .restricted:
                        deniedCard
                    default:
                        if let event = calendarManager.nextEvent {
                            eventContent(event)
                        } else {
                            freeTimeCard
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .task {
            // Always ask for notification permission (system silently no-ops if already decided)
            await notificationManager.requestPermission()
            // Then ask for calendar access if not yet granted
            if !calendarManager.isAuthorized {
                await calendarManager.requestAccess()
            }
            // Schedule for whatever events are already loaded
            scheduleNotifications()
        }
        // Re-schedule whenever today's event list changes *or* the store reports any change
        // (handles the case where count stays the same but events differ)
        .onChange(of: calendarManager.todayEvents.count) { _ in scheduleNotifications() }
        .onChange(of: calendarManager.lastUpdated)       { _ in scheduleNotifications() }
        .onReceive(ticker) { date in
            now = date                         // triggers greeting re-computation
            calendarManager.fetchTodayEvents()
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }

    // MARK: - Notifications

    private func scheduleNotifications() {
        // Use upcomingWeekEvents (7 days) so tomorrow's and this-week's events are covered too
        notificationManager.scheduleReminders(
            for: calendarManager.upcomingWeekEvents,
            oneHourBody: lang.t(.notif_one_hour),
            nowBody:     lang.t(.notif_now)
        )
    }

    // MARK: - Event content

    @ViewBuilder
    private func eventContent(_ event: EKEvent) -> some View {
        TimeRingView(minutesRemaining: calendarManager.minutesUntil(event), totalMinutes: ringTotal)
            .padding(.top, 8)

        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(lang.t(.next_label))
            EventCardView(event: event, isNext: true).padding(.horizontal)
        }

        if let loc = event.location, !loc.isEmpty {
            leaveByBanner(event: event)
        }

        let rest = Array(calendarManager.upcomingEvents.dropFirst().prefix(2))
        if !rest.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(lang.t(.after_that))
                ForEach(rest, id: \.eventIdentifier) { e in
                    EventCardView(event: e).padding(.horizontal)
                }
            }
        }
    }

    // MARK: - State cards

    private var permissionCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64)).foregroundColor(.tideTeal)
            Text(lang.t(.allow_access))
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(.tideDeep)
            Text("Your events stay private and never leave your device.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.tideSeafoam).multilineTextAlignment(.center)
            Button(lang.t(.calendar_allow_btn)) {
                Task { await calendarManager.requestAccess() }
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 36).padding(.vertical, 14)
            .background(Color.tideTeal).cornerRadius(16)
        }
        .padding(32)
    }

    private var deniedCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48)).foregroundColor(.tideSeafoam)
            Text("Calendar access needed")
                .font(.system(size: 18, weight: .medium, design: .rounded)).foregroundColor(.tideDeep)
            Text(lang.t(.calendar_denied_desc))
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.tideSeafoam).multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var freeTimeCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "water.waves").font(.system(size: 60)).foregroundColor(.tideSeafoam)
            Text(lang.t(.all_clear))
                .font(.system(size: 26, weight: .light, design: .rounded)).foregroundColor(.tideDeep)
            Text(lang.t(.no_more_events))
                .font(.system(size: 15, design: .rounded)).foregroundColor(.tideSeafoam)
        }
        .padding(.top, 40)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(.tideSeafoam).tracking(2).padding(.horizontal)
    }

    private func leaveByBanner(event: EKEvent) -> some View {
        let leaveTime = event.startDate.addingTimeInterval(-15 * 60)
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return HStack(spacing: 10) {
            Image(systemName: "figure.walk").foregroundColor(.tideTeal)
            Text(lang.t(.leave_by))
                .font(.system(size: 14, design: .rounded)).foregroundColor(.tideDeep)
            Text(f.string(from: leaveTime))
                .font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.tideTeal)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(Color.tideSand).cornerRadius(14).padding(.horizontal)
    }
}
