import Foundation

enum ServerType: String, CaseIterable, Identifiable, Codable {
    case ubuntuDebian
    case centosRhel
    case other

    var id: String { rawValue }
    var label: String {
        switch self {
        case .ubuntuDebian: return "Ubuntu / Debian"
        case .centosRhel: return "CentOS / RHEL"
        case .other: return "Other"
        }
    }
}

struct ServerProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String          // e.g. "API server"
    var host: String          // e.g. "ubuntu@api.example.com"
    var port: Int?            // optional SSH port, e.g. 22
    var serverType: ServerType?  // defaults to .ubuntuDebian when nil (old profiles)
    var checkCommand: String  // e.g. "apt list --upgradable"
    var updateCommand: String // e.g. "sudo apt update && sudo apt upgrade -y"
    var notes: String?        // optional free-form notes about SSH keys/config

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int? = nil,
        serverType: ServerType? = nil,
        checkCommand: String,
        updateCommand: String,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.serverType = serverType
        self.checkCommand = checkCommand
        self.updateCommand = updateCommand
        self.notes = notes
    }
}
