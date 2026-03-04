import Foundation

struct CommandResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

final class CommandRunner {
    private static var mergedPath: String {
        let extraPaths = "/opt/homebrew/bin:/usr/local/bin"
        let current = ProcessInfo.processInfo.environment["PATH"] ?? ""
        if current.isEmpty { return extraPaths }
        return "\(extraPaths):\(current)"
    }

    func run(
        _ launchPath: String,
        arguments: [String] = [],
        env: [String: String]? = nil
    ) async -> CommandResult {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: launchPath)
            process.arguments = arguments

            var environment = ProcessInfo.processInfo.environment
            environment["PATH"] = Self.mergedPath
            if let env = env {
                for (k, v) in env { environment[k] = v }
            }
            process.environment = environment

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            do {
                try process.run()
                process.waitUntilExit()

                let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(data: outData, encoding: .utf8) ?? ""
                let stderr = String(data: errData, encoding: .utf8) ?? ""

                continuation.resume(returning: CommandResult(
                    stdout: stdout,
                    stderr: stderr,
                    exitCode: process.terminationStatus
                ))
            } catch {
                continuation.resume(returning: CommandResult(
                    stdout: "",
                    stderr: error.localizedDescription,
                    exitCode: -1
                ))
            }
        }
    }

    func runShell(_ command: String) async -> CommandResult {
        await run("/bin/zsh", arguments: ["-lc", command])
    }
}
