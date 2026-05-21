import SwiftUI
import EventKit

/// A single event displayed as a sand-coloured card with a teal left strip.
struct EventCardView: View {
    let event: EKEvent
    var isNext: Bool = false
    @EnvironmentObject var lang: LanguageManager

    private var timeRange: String {
        let f = DateFormatter()
        f.timeStyle = .short   // locale-aware: 9:30 AM in EN, 09:30 in RU/FR/ES
        f.dateStyle = .none
        f.locale    = lang.locale
        return "\(f.string(from: event.startDate)) – \(f.string(from: event.endDate))"
    }

    var body: some View {
        HStack(spacing: 14) {

            RoundedRectangle(cornerRadius: 3)
                .fill(isNext ? Color.tideTeal : Color.tideSeafoam)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title ?? "Untitled")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.tideDeep)

                Text(timeRange)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.tideSeafoam)

                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "location.fill")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.tideSeafoam.opacity(0.8))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.tideSand)
        .cornerRadius(16)
    }
}
