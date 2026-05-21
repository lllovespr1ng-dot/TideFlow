import Foundation

/// A single brain-dump item — lightweight, no calendar needed.
struct BrainDumpTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
    var createdAt: Date = Date()
}
