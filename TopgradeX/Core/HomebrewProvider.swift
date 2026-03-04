import Foundation

final class HomebrewProvider: UpdateProvider {
    var id: String { "homebrew" }
    var displayName: String { "Homebrew" }

    func isAvailable(runner: CommandRunner) async -> Bool {
        let result = await runner.runShell("command -v brew")
        return result.exitCode == 0
    }

    func checkUpdates(runner: CommandRunner) async throws -> [UpdateItem] {
        let available = await isAvailable(runner: runner)
        guard available else { return [] }

        let result = await runner.runShell("brew outdated --verbose")
        if result.exitCode != 0 {
            if !result.stderr.isEmpty {
                print("[HomebrewProvider] brew outdated failed: \(result.stderr)")
            }
            return []
        }

        var items: [UpdateItem] = []
        let lines = result.stdout.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            let name = parts.isEmpty ? String(trimmed) : String(parts[0])
            let details: String
            if parts.count > 1 {
                details = String(parts[1]).trimmingCharacters(in: .whitespaces)
            } else {
                details = "current → latest"
            }

            items.append(UpdateItem(
                name: name,
                details: details,
                selected: true
            ))
        }

        return items
    }

    func performUpdates(_ items: [UpdateItem], runner: CommandRunner) async throws {
        let names = items.filter(\.selected).map(\.name)
        guard !names.isEmpty else { return }

        let list = names.joined(separator: " ")
        let result = await runner.runShell("brew upgrade \(list)")
        if result.exitCode != 0 {
            print("[HomebrewProvider] brew upgrade failed: \(result.stderr)")
        }
    }
}
