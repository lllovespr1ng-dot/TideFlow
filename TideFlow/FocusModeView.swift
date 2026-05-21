import SwiftUI
import Combine

struct FocusModeView: View {
    let task:            BrainDumpTask
    let durationMinutes: Int
    let onComplete:      () -> Void

    @EnvironmentObject var lang:                LanguageManager
    @EnvironmentObject var notificationManager: NotificationManager

    // Scene-phase lets us recalculate the moment the app comes back to the foreground.
    @Environment(\.scenePhase) private var scenePhase

    // ── Anchor-based timer state ──────────────────────────────────────────────
    // Instead of decrementing a counter each second, we store the absolute
    // moment the session ends and derive `timeRemaining` from (endDate - now).
    // This means backgrounding/foregrounding the app has zero effect on accuracy.
    @State private var endDate:       Date
    @State private var timeRemaining: Int       // seconds, derived from endDate
    @State private var totalSeconds:  Int       // original duration — used for progress ring
    @State private var isRunning      = true
    @State private var showCompletion = false
    @State private var pausedAt:      Date?     // non-nil only while timer is paused

    // UserDefaults keys used to survive full-kill + relaunch
    static let kEndDate   = "tf_focus_end_date"    // TimeInterval (reference date)
    static let kTaskID    = "tf_focus_task_id"     // UUID string
    static let kTotalSecs = "tf_focus_total_secs"  // Int

    init(task: BrainDumpTask, durationMinutes: Int, onComplete: @escaping () -> Void) {
        self.task            = task
        self.durationMinutes = durationMinutes
        self.onComplete      = onComplete
        let total = durationMinutes * 60
        _totalSeconds  = State(initialValue: total)
        _timeRemaining = State(initialValue: total)
        // Placeholder end-date — corrected in onAppear (restore or fresh start)
        _endDate = State(initialValue: Date().addingTimeInterval(TimeInterval(total)))
    }

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var progress: Double {
        guard totalSeconds > 0 else { return 1 }
        return 1.0 - Double(timeRemaining) / Double(totalSeconds)
    }
    private var timeString: String {
        let t = max(0, timeRemaining)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.tideBg.ignoresSafeArea()
            if showCompletion {
                completionView.transition(.opacity)
            } else {
                focusContent.transition(.opacity)
            }
        }
        .onAppear { configureSession() }
        // Instantly correct the counter as soon as the app returns to the foreground
        .onChange(of: scenePhase) { phase in
            guard phase == .active, isRunning, !showCompletion else { return }
            syncToEndDate()
        }
        // Tick every second while running
        .onReceive(ticker) { _ in
            guard isRunning, !showCompletion else { return }
            syncToEndDate()
        }
    }

    // MARK: - Session setup

    /// On first appear, check whether there is a persisted session for this task.
    /// If yes (e.g. app was killed and relaunched), restore the anchor date so the
    /// timer picks up exactly where it left off.  Otherwise start fresh.
    private func configureSession() {
        let defaults  = UserDefaults.standard
        let storedID  = defaults.string(forKey: Self.kEndDate)
        let storedEnd = (defaults.object(forKey: Self.kEndDate) as? TimeInterval)
            .map { Date(timeIntervalSinceReferenceDate: $0) }
        let matchesTask = defaults.string(forKey: Self.kTaskID) == task.id.uuidString

        if matchesTask, let stored = storedEnd, stored > Date() {
            // ── Restore ────────────────────────────────────────────────────
            endDate      = stored
            totalSeconds = defaults.integer(forKey: Self.kTotalSecs)
            timeRemaining = Int(stored.timeIntervalSinceNow)
            // The notification was scheduled when the session originally started —
            // no need to reschedule it.
        } else {
            // ── Fresh start ────────────────────────────────────────────────
            let total  = durationMinutes * 60
            let newEnd = Date().addingTimeInterval(TimeInterval(total))
            endDate      = newEnd
            totalSeconds = total
            timeRemaining = total

            persistSession(endDate: newEnd, total: total)
            notificationManager.scheduleFocusEnd(
                taskTitle: task.title,
                body:      lang.t(.notif_focus_done),
                in:        TimeInterval(total)
            )
        }
        _ = storedID   // suppress unused-variable warning
    }

    // MARK: - Timer sync

    /// Derives `timeRemaining` from `endDate - now`.  Triggers completion when
    /// the deadline passes — whether the app was in the foreground or just returned.
    private func syncToEndDate() {
        let remaining = Int(endDate.timeIntervalSinceNow)
        if remaining <= 0 {
            timeRemaining = 0
            isRunning     = false
            notificationManager.cancelFocusNotification()
            clearPersistedSession()
            withAnimation { showCompletion = true }
        } else {
            timeRemaining = remaining
        }
    }

    // MARK: - Pause / resume

    private func togglePause() {
        if isRunning {
            // Pause — record the moment we stopped and cancel the notification
            isRunning = false
            pausedAt  = Date()
            notificationManager.cancelFocusNotification()
        } else {
            // Resume — slide the end-date forward by however long we were paused,
            // then reschedule the notification against the updated deadline
            if let p = pausedAt {
                let elapsed = Date().timeIntervalSince(p)
                endDate = endDate.addingTimeInterval(elapsed)
                persistSession(endDate: endDate, total: totalSeconds)
            }
            pausedAt  = nil
            isRunning = true

            let remaining = max(1, endDate.timeIntervalSinceNow)
            notificationManager.scheduleFocusEnd(
                taskTitle: task.title,
                body:      lang.t(.notif_focus_done),
                in:        remaining
            )
        }
    }

    // MARK: - Persistence helpers

    private func persistSession(endDate: Date, total: Int) {
        let d = UserDefaults.standard
        d.set(endDate.timeIntervalSinceReferenceDate, forKey: Self.kEndDate)
        d.set(task.id.uuidString,                    forKey: Self.kTaskID)
        d.set(total,                                 forKey: Self.kTotalSecs)
    }

    private func clearPersistedSession() {
        let d = UserDefaults.standard
        d.removeObject(forKey: Self.kEndDate)
        d.removeObject(forKey: Self.kTaskID)
        d.removeObject(forKey: Self.kTotalSecs)
    }

    // MARK: - Focus screen

    private var focusContent: some View {
        VStack(spacing: 0) {
            HStack {
                // X — exit early; cancel notification + clear persistence
                Button(action: {
                    notificationManager.cancelFocusNotification()
                    clearPersistedSession()
                    onComplete()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium)).foregroundColor(.tideSeafoam)
                        .padding(12).background(Color.tideSand).clipShape(Circle())
                }
                Spacer()
                // Pause / resume
                Button(action: togglePause) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .medium)).foregroundColor(.tideSeafoam)
                        .padding(12).background(Color.tideSand).clipShape(Circle())
                }
            }
            .padding(.horizontal, 24).padding(.top, 60)

            Spacer()

            VStack(spacing: 8) {
                Text(lang.t(.focusing_on))
                    .font(.system(size: 14, design: .rounded)).foregroundColor(.tideSeafoam)
                Text(task.title)
                    .font(.system(size: 24, weight: .semibold, design: .rounded)).foregroundColor(.tideDeep)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
            }

            Spacer()

            ZStack {
                WaveView(progress: progress)
                    .frame(width: 220, height: 220)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.tideMist, lineWidth: 2))
                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 46, weight: .light, design: .rounded)).foregroundColor(.white)
                    Text(isRunning ? lang.t(.flowing) : lang.t(.paused_label))
                        .font(.system(size: 13, design: .rounded)).foregroundColor(.white.opacity(0.75))
                }
            }

            Spacer()

            // "I'm done" — mark complete early; cancel notification + clear persistence
            Button(action: {
                notificationManager.cancelFocusNotification()
                clearPersistedSession()
                isRunning = false
                withAnimation { showCompletion = true }
            }) {
                Text(lang.t(.im_done))
                    .font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.tideTeal).cornerRadius(16)
            }
            .padding(.horizontal, 32).padding(.bottom, 52)
        }
    }

    // MARK: - Completion screen

    private var completionView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                Text("🌊").font(.system(size: 72))
                Text(lang.t(.wave_complete))
                    .font(.system(size: 36, weight: .semibold, design: .rounded)).foregroundColor(.tideDeep)
                Text(task.title)
                    .font(.system(size: 18, design: .rounded)).foregroundColor(.tideSeafoam)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
            }
            Spacer()
            Button(action: {
                clearPersistedSession()
                onComplete()
            }) {
                Text(lang.t(.back_to_dump))
                    .font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.tideTeal).cornerRadius(16)
            }
            .padding(.horizontal, 32).padding(.bottom, 52)
        }
    }
}
