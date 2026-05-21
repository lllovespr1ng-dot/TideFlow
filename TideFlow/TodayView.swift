import SwiftUI
import EventKit

struct TodayView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var lang: LanguageManager

    private var dateHeader: String {
        let f = DateFormatter()
        // "d LLLL" → day number + standalone nominative month (no case inflection)
        // e.g. "21 май" in Russian, "21 May" in English, "21 mai" in French
        f.dateFormat = "EEEE, d LLLL"
        f.locale = lang.locale
        return f.string(from: Date())
    }

    var body: some View {
        ZStack {
            Color.tideBg.ignoresSafeArea()
            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dateHeader)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.tideSeafoam)
                        Text(lang.t(.today_title))
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(.tideDeep)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // ── Content ───────────────────────────────────────────────
                if calendarManager.todayEvents.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "sun.horizon")
                            .font(.system(size: 52)).foregroundColor(.tideSeafoam)
                        Text(lang.t(.nothing_scheduled))
                            .font(.system(size: 18, design: .rounded)).foregroundColor(.tideDeep)
                        Text(lang.t(.enjoy_open_water))
                            .font(.system(size: 14, design: .rounded)).foregroundColor(.tideSeafoam)
                    }
                    Spacer()
                } else {
                    // List gives us native swipe-to-delete out of the box
                    List {
                        ForEach(calendarManager.todayEvents, id: \.eventIdentifier) { event in
                            EventCardView(
                                event: event,
                                isNext: event.eventIdentifier == calendarManager.nextEvent?.eventIdentifier
                            )
                            .opacity(event.endDate < Date() ? 0.4 : 1.0)
                            .listRowBackground(Color.tideBg)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    try? calendarManager.deleteEvent(event)
                                } label: {
                                    Label(lang.t(.delete_event), systemImage: "trash")
                                }
                            }
                        }
                        // Extra space so the last card isn't hidden behind the floating + button
                        Color.clear.frame(height: 80)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear { calendarManager.fetchTodayEvents() }
    }
}
