import SwiftUI

struct BrainDumpView: View {
    @EnvironmentObject var brainDumpManager: BrainDumpManager
    @EnvironmentObject var lang: LanguageManager

    @State private var newTaskText      = ""
    @State private var taskForDuration: BrainDumpTask? = nil
    @State private var activeSession:   FocusSession?
    @State private var showClearAllAlert = false
    @FocusState private var inputFocused: Bool

    private var pending:   [BrainDumpTask] { brainDumpManager.tasks.filter { !$0.isCompleted } }
    private var completed: [BrainDumpTask] { brainDumpManager.tasks.filter {  $0.isCompleted } }

    private var presets: [(String, LKey)] {[
        ("figure.yoga",         .preset_yoga),
        ("figure.run",          .preset_workout),
        ("book.fill",           .preset_reading),
        ("camera.fill",         .preset_instagram),
        ("laptopcomputer",      .preset_work),
        ("gamecontroller.fill", .preset_games),
    ]}

    var body: some View {
        ZStack {
            Color.tideBg.ignoresSafeArea()
            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.t(.capture_everything))
                            .font(.system(size: 14, design: .rounded)).foregroundColor(.tideSeafoam)
                        Text(lang.t(.brain_dump))
                            .font(.system(size: 28, weight: .semibold, design: .rounded)).foregroundColor(.tideDeep)
                    }
                    Spacer()
                    HStack(spacing: 14) {
                        if !completed.isEmpty {
                            Button(lang.t(.clear_done)) {
                                withAnimation { brainDumpManager.clearCompleted() }
                            }
                            .font(.system(size: 13, design: .rounded)).foregroundColor(.tideSeafoam)
                        }
                        if !brainDumpManager.tasks.isEmpty {
                            Button(lang.t(.clear_all)) { showClearAllAlert = true }
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.tideSeafoam)
                        }
                    }
                }
                .padding(.horizontal).padding(.top, 16).padding(.bottom, 12)

                // ── Quick-access presets ──────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.1) { icon, key in
                            Button(action: {
                                withAnimation { brainDumpManager.add(lang.t(key)) }
                                FeedbackManager.shared.taskAdded()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: icon).font(.system(size: 13))
                                    Text(lang.t(key))
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.tideDeep)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.tideSand).cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 12)
                }

                // ── Task list (List for native swipe-to-delete) ───────────
                List {
                    ForEach(pending) { task in
                        TaskRow(
                            task:       task,
                            focusLabel: lang.t(.focus_button),
                            onComplete: {
                                withAnimation { brainDumpManager.complete(task) }
                                FeedbackManager.shared.taskCompleted()
                            },
                            onFocus:    { taskForDuration = task },
                            onDelete:   { withAnimation { brainDumpManager.delete(task) } }
                        )
                        .listRowBackground(Color.tideBg)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { brainDumpManager.delete(task) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    if !completed.isEmpty {
                        // Section divider
                        Text(lang.t(.done_section))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.tideSeafoam)
                            .tracking(2)
                            .listRowBackground(Color.tideBg)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 2, trailing: 16))

                        ForEach(completed) { task in
                            TaskRow(
                                task:       task,
                                focusLabel: lang.t(.focus_button),
                                onComplete: {},
                                onFocus:    {},
                                onDelete:   { withAnimation { brainDumpManager.delete(task) } }
                            )
                            .opacity(0.45)
                            .listRowBackground(Color.tideBg)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { brainDumpManager.delete(task) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }

                    // Bottom spacer so last card clears the input bar
                    Color.clear.frame(height: 100)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                // Dismiss keyboard when the user scrolls or taps inside the list
                .scrollDismissesKeyboard(.immediately)

                // ── Input bar ─────────────────────────────────────────────
                HStack(spacing: 12) {
                    TextField(lang.t(.whats_on_mind), text: $newTaskText)
                        .font(.system(size: 16, design: .rounded))
                        .focused($inputFocused)
                        .onSubmit { addTask() }
                    Button(action: addTask) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(newTaskText.isEmpty ? .tideSeafoam.opacity(0.35) : .tideTeal)
                    }
                    .disabled(newTaskText.isEmpty)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.tideSand).cornerRadius(16)
                .padding(.horizontal).padding(.bottom, 8)
            }
        }
        .onAppear { restoreSessionIfNeeded() }
        // Keyboard accessory: tap ⌨ chevron to dismiss without touching any row
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button { inputFocused = false } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .foregroundColor(.tideTeal)
                }
            }
        }
        // Duration picker
        .sheet(item: $taskForDuration) { task in
            FocusDurationPickerView(task: task) { minutes in
                activeSession = FocusSession(task: task, minutes: minutes)
            }
            .presentationDetents([.medium])
        }
        // Full-screen focus session
        .fullScreenCover(item: $activeSession) { session in
            FocusModeView(task: session.task, durationMinutes: session.minutes) {
                brainDumpManager.complete(session.task)
                activeSession = nil
            }
        }
        // Confirm "Clear all"
        .alert(lang.t(.clear_all), isPresented: $showClearAllAlert) {
            Button(lang.t(.clear_all), role: .destructive) {
                withAnimation { brainDumpManager.clearAll() }
            }
            Button(lang.t(.cancel_label), role: .cancel) {}
        }
    }

    private func addTask() {
        guard !newTaskText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation { brainDumpManager.add(newTaskText) }
        FeedbackManager.shared.taskAdded()
        newTaskText = ""
    }

    /// If the app was killed mid-session and relaunched, restore the active focus session
    /// so the user lands back inside FocusModeView with the timer still counting down.
    private func restoreSessionIfNeeded() {
        guard activeSession == nil else { return }   // already showing a session

        let defaults = UserDefaults.standard
        guard
            let taskIDStr = defaults.string(forKey: FocusModeView.kTaskID),
            let taskID    = UUID(uuidString: taskIDStr),
            let endInterval = defaults.object(forKey: FocusModeView.kEndDate) as? TimeInterval
        else { return }

        let endDate = Date(timeIntervalSinceReferenceDate: endInterval)

        guard endDate > Date() else {
            // Session expired while the app was away — clean up the leftovers
            defaults.removeObject(forKey: FocusModeView.kEndDate)
            defaults.removeObject(forKey: FocusModeView.kTaskID)
            defaults.removeObject(forKey: FocusModeView.kTotalSecs)
            return
        }

        // Find the matching task (it must still exist in the list)
        guard let task = brainDumpManager.tasks.first(where: { $0.id == taskID }) else {
            defaults.removeObject(forKey: FocusModeView.kEndDate)
            defaults.removeObject(forKey: FocusModeView.kTaskID)
            defaults.removeObject(forKey: FocusModeView.kTotalSecs)
            return
        }

        let totalSecs       = defaults.integer(forKey: FocusModeView.kTotalSecs)
        let durationMinutes = max(1, (totalSecs > 0 ? totalSecs : Int(endDate.timeIntervalSinceNow)) / 60)
        activeSession = FocusSession(task: task, minutes: durationMinutes)
    }
}

// MARK: - Task row

struct TaskRow: View {
    let task: BrainDumpTask
    let focusLabel: String
    let onComplete: () -> Void
    let onFocus:    () -> Void
    let onDelete:   () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isCompleted ? .tideTeal : .tideSeafoam)
            }
            Text(task.title)
                .font(.system(size: 16, design: .rounded)).foregroundColor(.tideDeep)
                .strikethrough(task.isCompleted, color: .tideSeafoam)
                .frame(maxWidth: .infinity, alignment: .leading)
            if !task.isCompleted {
                Button(action: onFocus) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill").font(.system(size: 11))
                        Text(focusLabel).font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.tideTeal)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.tideTeal.opacity(0.12)).cornerRadius(8)
                }
            }
        }
        .padding(16).background(Color.tideSand).cornerRadius(14)
    }
}
