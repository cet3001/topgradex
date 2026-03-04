import Foundation

final class GemProvider: UpdateProvider {
    var id: String { "gem" }
    var displayName: String { "gem (Ruby)" }

    private let allowRiskyUpdates: Bool

    init(allowRiskyUpdates: Bool = false) {
        self.allowRiskyUpdates = allowRiskyUpdates
    }

    func isAvailable(runner: CommandRunner) async -> Bool {
        let result = await runner.runShell("command -v gem")
        return result.exitCode == 0
    }

    func checkUpdates(runner: CommandRunner) async throws -> [UpdateItem] {
        let available = await isAvailable(runner: runner)
        guard available else { return [] }

        let result = await runner.runShell("gem outdated")
        if result.exitCode != 0 {
            let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? result.stdout
                : result.stderr
            print("[GemProvider] gem outdated failed (exit \(result.exitCode)): \(message)")
            throw NSError(domain: "GemProvider", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? "Command failed" : message])
        }
        if result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        let lines = result.stdout.split(separator: "\n")
        var items: [UpdateItem] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            guard let firstSpace = trimmed.firstIndex(of: " ") else { continue }
            let name = String(trimmed[..<firstSpace])
            let details = String(trimmed[firstSpace...]).trimmingCharacters(in: .whitespaces)

            items.append(UpdateItem(name: name, details: details, selected: true))
        }

        return items
    }

    func performUpdates(_ items: [UpdateItem], runner: CommandRunner) async throws {
        let names = items.filter(\.selected).map(\.name)
        guard !names.isEmpty else { return }

        let envResult = await runner.runShell("gem environment gemdir")
        let gemdir = envResult.exitCode == 0
            ? envResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            : ""

        if !allowRiskyUpdates {
            let message = "System Ruby gems at \(gemdir) require elevated permissions. Enable 'Allow Ruby to update system gems with sudo' in Settings → Integrations → Advanced to let TopgradeX attempt updates."
            print("[GemProvider] \(message)")
            throw NSError(domain: "GemProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let command = "sudo gem update \(names.joined(separator: " "))"
        let result = await runner.runShell(command)
        if result.exitCode != 0 {
            let output = result.stderr.isEmpty ? result.stdout : result.stderr
            let message = "[GemProvider] gem update failed (exit \(result.exitCode)): \(output)"
            print(message)
            throw NSError(domain: "GemProvider", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: output])
        }
    }
}
