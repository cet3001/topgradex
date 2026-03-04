import Foundation

final class PipProvider: UpdateProvider {
    var id: String { "pip" }
    var displayName: String { "pip (Python)" }

    private let allowRiskyUpdates: Bool

    init(allowRiskyUpdates: Bool = false) {
        self.allowRiskyUpdates = allowRiskyUpdates
    }

    func isAvailable(runner: CommandRunner) async -> Bool {
        let direct = await runner.runShell("command -v pip")
        if direct.exitCode == 0 { return true }
        let viaPython = await runner.runShell("python3 -m pip --version")
        return viaPython.exitCode == 0
    }

    func checkUpdates(runner: CommandRunner) async throws -> [UpdateItem] {
        let available = await isAvailable(runner: runner)
        guard available else { return [] }

        let result = await runner.runShell("python3 -m pip list --outdated --format=columns")
        if result.exitCode != 0 {
            let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? result.stdout
                : result.stderr
            print("[PipProvider] pip list --outdated failed (exit \(result.exitCode)): \(message)")
            throw NSError(domain: "PipProvider", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? "Command failed" : message])
        }
        if result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        let lines = result.stdout.split(separator: "\n")
        var items: [UpdateItem] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Skip header line and any separators
            if index == 0, trimmed.localizedCaseInsensitiveContains("Package") {
                continue
            }
            if trimmed.hasPrefix("--") || trimmed.hasPrefix("==") {
                continue
            }

            let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 3 else { continue }

            let name = parts[0]
            let current = parts[1]
            let latest = parts[2]

            // Skip names that look like separators
            guard !name.hasPrefix("-") else { continue }

            let details = "\(current) → \(latest)"
            items.append(UpdateItem(name: name, details: details, selected: true))
        }

        return items
    }

    func performUpdates(_ items: [UpdateItem], runner: CommandRunner) async throws {
        let names = items.filter(\.selected).map(\.name)
        guard !names.isEmpty else { return }

        if !allowRiskyUpdates {
            let message = "Python environment is externally managed (PEP 668). Enable 'Allow pip to modify system Python' in Settings → Integrations → Advanced if you want TopgradeX to run risky updates."
            print("[PipProvider] \(message)")
            throw NSError(domain: "PipProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }

        for name in names {
            let command = "python3 -m pip install --upgrade --break-system-packages --user \(name)"
            let result = await runner.runShell(command)
            if result.exitCode != 0 {
                let output = result.stderr.isEmpty ? result.stdout : result.stderr
                let message = "[PipProvider] pip install --upgrade \(name) failed (exit \(result.exitCode)): \(output)"
                print(message)
                throw NSError(domain: "PipProvider", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: output])
            }
        }
    }
}
