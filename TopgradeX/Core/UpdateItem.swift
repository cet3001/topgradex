import Foundation

struct UpdateItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let details: String
    var selected: Bool

    init(id: UUID = UUID(), name: String, details: String, selected: Bool = true) {
        self.id = id
        self.name = name
        self.details = details
        self.selected = selected
    }
}
