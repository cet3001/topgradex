import Foundation

final class NixProvider: UpdateProvider {
    var id: String { "nix" }
    var displayName: String { "Nix" }

    func isAvailable(runner: CommandRunner) async -> Bool {
        let result = await runner.runShell("command -v nix-env")
        return result.exitCode == 0
    }

    func checkUpdates(runner: CommandRunner) async throws -> [UpdateItem] {
        let available = await isAvailable(runner: runner)
        guard available else { return [] }

        let result = await runner.runShell("nix-env -u --dry-run 2>&1")
        if result.exitCode != 0 && !result.stdout.lowercased().contains("would be upgraded") {
            if !result.stderr.isEmpty {
                print("[NixProvider] nix-env -u --dry-run failed: \(result.stderr)")
            }
            return []
        }

        var items: [UpdateItem] = []
        let lines = result.stdout.split(separator: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            // Skip header-like lines; accept lines that look like package names (alphanumeric, dash, underscore)
            let firstWord = trimmed.split(whereSeparator: { $0.isWhitespace }).first.flatMap { String($0) }
            guard let name = firstWord, !name.isEmpty, name.allSatisfy({ c in c.isLetter || c.isNumber || c == "-" || c == "_" }) else { continue }

            let details = trimmed
            items.append(UpdateItem(name: name, details: details, selected: true))
        }

        return items
    }

    func performUpdates(_ items: [UpdateItem], runner: CommandRunner) async throws {
        let names = items.filter(\.selected).map(\.name)
        guard !names.isEmpty else { return }

        let list = names.joined(separator: " ")
        let result = await runner.runShell("nix-env -u \(list)")
        if result.exitCode != 0 {
            print("[NixProvider] nix-env -u failed: \(result.stderr)")
        }
    }
}
