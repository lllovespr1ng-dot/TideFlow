import SwiftUI
import Combine

/// Stores brain-dump tasks in UserDefaults so they survive app restarts.
class BrainDumpManager: ObservableObject {

    @Published var tasks: [BrainDumpTask] = [] {
        didSet { save() }
    }

    init() { load() }

    // MARK: - Actions

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tasks.insert(BrainDumpTask(title: trimmed), at: 0)
    }

    func complete(_ task: BrainDumpTask) {
        update(task) { $0.isCompleted = true }
    }

    func delete(_ task: BrainDumpTask) {
        tasks.removeAll { $0.id == task.id }
    }

    func clearCompleted() {
        tasks.removeAll { $0.isCompleted }
    }

    func clearAll() {
        tasks.removeAll()
    }

    // MARK: - Persistence

    private func update(_ task: BrainDumpTask, transform: (inout BrainDumpTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        transform(&tasks[index])
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "brainDumpTasks")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "brainDumpTasks"),
              let decoded = try? JSONDecoder().decode([BrainDumpTask].self, from: data)
        else { return }
        tasks = decoded
    }
}
