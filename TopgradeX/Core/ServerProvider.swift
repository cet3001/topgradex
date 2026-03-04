import Foundation

final class ServerProvider: UpdateProvider {
    var id: String { "servers" }
    var displayName: String { "Servers" }

    private let profiles: [ServerProfile]

    init(profiles: [ServerProfile]) {
        self.profiles = profiles
    }

    func isAvailable(runner: CommandRunner) async -> Bool {
        let result = await runner.runShell("command -v ssh")
        return result.exitCode == 0 && !profiles.isEmpty
    }

    func checkUpdates(runner: CommandRunner) async throws -> [UpdateItem] {
        guard !profiles.isEmpty else { return [] }

        var items: [UpdateItem] = []

        for profile in profiles {
            let command = #"ssh \#(profile.host) "\#(profile.checkCommand)""#
            let result = await runner.runShell(command)

            if result.exitCode != 0 {
                let output = result.stderr.isEmpty ? result.stdout : result.stderr
                print("[ServerProvider] Check failed for \(profile.name) (\(profile.host)): \(output)")
                continue
            }

            let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                continue
            }

            let lines = trimmed.split(separator: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            let count = lines.count
            let details = count == 1 ? "1 item reported" : "\(count) items reported"

            items.append(
                UpdateItem(
                    id: profile.id,
                    name: profile.name,
                    details: "\(profile.host) – \(details)",
                    selected: true
                )
            )
        }

        return items
    }

    func performUpdates(_ items: [UpdateItem], runner: CommandRunner) async throws {
        for item in items where item.selected {
            guard let profile = profiles.first(where: { $0.name == item.name }) else { continue }

            let command = #"ssh \#(profile.host) "\#(profile.updateCommand)""#
            let result = await runner.runShell(command)
            if result.exitCode != 0 {
                let output = result.stderr.isEmpty ? result.stdout : result.stderr
                print("[ServerProvider] Update failed for \(profile.name) (\(profile.host)): \(output)")
            }
        }
    }
}
