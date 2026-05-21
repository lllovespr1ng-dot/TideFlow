import Foundation

/// Carries the task + chosen duration into FocusModeView.
struct FocusSession: Identifiable {
    let id = UUID()
    let task: BrainDumpTask
    let minutes: Int
}
