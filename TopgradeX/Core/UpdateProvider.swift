import Foundation

protocol UpdateProvider {
    var id: String { get }
    var displayName: String { get }

    func isAvailable(runner: CommandRunner) async -> Bool
    func checkUpdates(runner: CommandRunner) async throws -> [UpdateItem]
    func performUpdates(_ items: [UpdateItem], runner: CommandRunner) async throws
}
