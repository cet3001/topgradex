import Foundation

final class MasProvider: UpdateProvider {
    var id: String { "mas" }
    var displayName: String { "Mac App Store" }

    func isAvailable(runner: CommandRunner) async -> Bool {
        let result = await runner.runShell("command -v mas")
        return result.exitCode == 0
    }

    func checkUpdates(runner: CommandRunner) async throws -> [UpdateItem] {
        let available = await isAvailable(runner: runner)
        guard available else { return [] }

        let result = await runner.runShell("mas outdated")
        if result.exitCode != 0 || result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        let lines = result.stdout.split(separator: "\n")
        var items: [UpdateItem] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            guard let firstSpace = trimmed.firstIndex(of: " ") else { continue }
            let idPart = String(trimmed[..<firstSpace])
            let rest = String(trimmed[firstSpace...]).trimmingCharacters(in: .whitespaces)

            let name: String
            let details: String
            if let parenIndex = rest.firstIndex(of: "(") {
                name = String(rest[..<parenIndex]).trimmingCharacters(in: .whitespaces)
                details = String(rest[parenIndex...]).trimmingCharacters(in: .whitespaces)
            } else {
                name = rest
                details = "Update available"
            }

            let itemName = "\(name) [\(idPart)]"
            let itemDetails = details.isEmpty ? "Update available" : details

            items.append(UpdateItem(name: itemName, details: itemDetails, selected: true))
        }

        return items
    }

    func performUpdates(_ items: [UpdateItem], runner: CommandRunner) async throws {
        let ids: [String] = items.filter(\.selected).compactMap { item in
            guard let open = item.name.lastIndex(of: "["),
                  let close = item.name.lastIndex(of: "]"),
                  open < close else { return nil }
            return String(item.name[item.name.index(after: open)..<close])
        }

        guard !ids.isEmpty else { return }

        let command = "mas upgrade \(ids.joined(separator: " "))"
        let result = await runner.runShell(command)
        if result.exitCode != 0 {
            print("[MasProvider] mas upgrade failed: \(result.stderr)")
        }
    }
}
