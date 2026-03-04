import Foundation

final class NpmProvider: UpdateProvider {
    var id: String { "npm" }
    var displayName: String { "npm (global)" }

    func isAvailable(runner: CommandRunner) async -> Bool {
        let result = await runner.runShell("command -v npm")
        return result.exitCode == 0
    }

    func checkUpdates(runner: CommandRunner) async throws -> [UpdateItem] {
        let available = await isAvailable(runner: runner)
        guard available else { return [] }

        let result = await runner.runShell("npm outdated -g --depth=0 2>/dev/null")
        if result.exitCode != 0 || result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        let lines = result.stdout.split(separator: "\n")
        var items: [UpdateItem] = []

        for (index, line) in lines.enumerated() {
            if index == 0, line.localizedCaseInsensitiveContains("package") {
                continue
            }
            let parts = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 4 else { continue }

            let name = parts[0]
            let current = parts[1]
            let wanted = parts.count > 2 ? parts[2] : current
            let latest = parts.count > 3 ? parts[3] : wanted

            let details = "current \(current) → wanted \(wanted), latest \(latest)"
            items.append(UpdateItem(name: name, details: details, selected: true))
        }

        return items
    }

    func performUpdates(_ items: [UpdateItem], runner: CommandRunner) async throws {
        let names = items.filter(\.selected).map(\.name)
        guard !names.isEmpty else { return }

        let command = "npm update -g \(names.joined(separator: " "))"
        let result = await runner.runShell(command)
        if result.exitCode != 0 {
            print("[NpmProvider] npm update -g failed: \(result.stderr)")
        }
    }
}
