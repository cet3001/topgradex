import Foundation

struct ServerProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String          // e.g. "API server"
    var host: String          // e.g. "ubuntu@api.example.com"
    var checkCommand: String  // e.g. "apt list --upgradable"
    var updateCommand: String // e.g. "sudo apt update && sudo apt upgrade -y"

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        checkCommand: String,
        updateCommand: String
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.checkCommand = checkCommand
        self.updateCommand = updateCommand
    }
}
