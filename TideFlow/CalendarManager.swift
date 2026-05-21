import EventKit
import SwiftUI
import Combine

/// Manages all calendar access and event fetching via EventKit.
class CalendarManager: ObservableObject {

    private let store = EKEventStore()

    @Published var todayEvents: [EKEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    /// Bumped every time the EventKit store changes — lets other views re-fetch.
    @Published var lastUpdated: Date = Date()

    private var storeObserverToken: Any?

    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if isAuthorized { fetchTodayEvents() }

        // Automatically refresh whenever the EventKit store changes
        // (covers Quick Add saves, external calendar edits, deletions, etc.)
        storeObserverToken = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.isAuthorized else { return }
            self.fetchTodayEvents()
        }
    }

    deinit {
        if let token = storeObserverToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    // MARK: - Authorization

    var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return authorizationStatus == .authorized
        }
    }

    func requestAccess() async {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            let status = EKEventStore.authorizationStatus(for: .event)
            await MainActor.run { self.authorizationStatus = status }
            if granted { fetchTodayEvents() }
        } catch {
            print("Calendar access error: \(error)")
        }
    }

    // MARK: - Fetching

    func fetchTodayEvents() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end   = calendar.date(byAdding: .day, value: 1, to: start)!
        let fetched = events(from: start, to: end)
        DispatchQueue.main.async {
            self.todayEvents  = fetched
            self.lastUpdated  = Date()     // signal PlanView (and others) to re-fetch
        }
    }

    /// Returns all non-all-day events in the given range, sorted by start time.
    func events(from start: Date, to end: Date) -> [EKEvent] {
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Convenience

    /// The next event that hasn't ended yet (could be in progress or upcoming).
    var nextEvent: EKEvent? {
        todayEvents.first { $0.endDate > Date() }
    }

    /// All of today's events that haven't ended yet.
    var upcomingEvents: [EKEvent] {
        todayEvents.filter { $0.endDate > Date() }
    }

    /// All events in the next 7 days — used for notification scheduling so the
    /// user gets reminders for tomorrow's (and this week's) events too.
    var upcomingWeekEvents: [EKEvent] {
        let now = Date()
        guard let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: now) else { return [] }
        return events(from: now, to: weekEnd)
    }

    /// Whole minutes until an event starts (0 if already started).
    func minutesUntil(_ event: EKEvent) -> Int {
        max(0, Int(event.startDate.timeIntervalSince(Date()) / 60))
    }

    /// Formats a Date as "9:30 AM".
    func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    // MARK: - Create

    /// Saves a new event to the default calendar and refreshes today's list.
    @discardableResult
    func createEvent(title: String, startDate: Date, endDate: Date) throws -> EKEvent {
        let event       = EKEvent(eventStore: store)
        event.title     = title
        event.startDate = startDate
        event.endDate   = endDate
        event.calendar  = store.defaultCalendarForNewEvents
        try store.save(event, span: .thisEvent)
        fetchTodayEvents()
        return event
    }

    // MARK: - Delete

    /// Removes the given event from the calendar store and refreshes today's list.
    func deleteEvent(_ event: EKEvent) throws {
        try store.remove(event, span: .thisEvent)
        fetchTodayEvents()
    }
}
