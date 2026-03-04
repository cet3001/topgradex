import SwiftUI
import ServiceManagement

struct ProviderStatus: Identifiable, Equatable {
    let id: String
    let name: String
    let statusText: String
    let statusColor: Color
    let updates: [UpdateItem]
    /// When status indicates an error, optional detail message (e.g. stderr).
    let errorDetail: String?
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var items: [ProviderStatus] = []
    @Published var isCheckingUpdates: Bool = false
    @Published var isApplyingUpdates: Bool = false
    @Published var currentTaskLabel: String = ""
    @Published var currentTaskProgress: Double? = nil
    @Published var serverProfiles: [ServerProfile] = []

    @AppStorage("autoCheckEnabled") var autoCheckEnabled: Bool = true
    @AppStorage("autoCheckIntervalDays") var autoCheckIntervalDays: Int = 3
    @AppStorage("lastAutoCheck") private var lastAutoCheck: Double = 0
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false
    @AppStorage("provider_homebrew_enabled") var homebrewEnabled: Bool = true
    @AppStorage("provider_mas_enabled") var masEnabled: Bool = true
    @AppStorage("provider_npm_enabled") var npmEnabled: Bool = true
    @AppStorage("provider_pip_enabled") var pipEnabled: Bool = false
    @AppStorage("provider_servers_enabled") var serversEnabled: Bool = true
    @AppStorage("provider_macports_enabled") var macPortsEnabled: Bool = false
    @AppStorage("provider_nix_enabled") var nixEnabled: Bool = false
    @AppStorage("pip_allow_risky_updates") var pipAllowRisky: Bool = false
    @AppStorage("serverProfilesData") private var serverProfilesData: Data = Data()
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("launchAtLoginConfigured") private var launchAtLoginConfigured: Bool = false

    private var allProviders: [UpdateProvider] {
        var list: [UpdateProvider] = []
        if homebrewEnabled { list.append(HomebrewProvider()) }
        if masEnabled { list.append(MasProvider()) }
        if npmEnabled { list.append(NpmProvider()) }
        if pipEnabled { list.append(PipProvider(allowRiskyUpdates: pipAllowRisky)) }
        if serversEnabled && !serverProfiles.isEmpty {
            list.append(ServerProvider(profiles: serverProfiles))
        }
        if macPortsEnabled { list.append(MacPortsProvider()) }
        if nixEnabled { list.append(NixProvider()) }
        return list
    }

    private let runner = CommandRunner()
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        loadServerProfiles()
        if !launchAtLoginConfigured {
            launchAtLogin = true
            launchAtLoginConfigured = true
            try? SMAppService.mainApp.register()
        }
        Task { @MainActor in
            await runAllChecks()
            await maybeRunAutoCheck()
        }
    }

    func loadServerProfiles() {
        guard !serverProfilesData.isEmpty else {
            serverProfiles = []
            return
        }
        if let profiles = try? decoder.decode([ServerProfile].self, from: serverProfilesData) {
            serverProfiles = profiles
        } else {
            serverProfiles = []
        }
    }

    func saveServerProfiles() {
        if let data = try? encoder.encode(serverProfiles) {
            serverProfilesData = data
        }
    }

    func addServerProfile(_ profile: ServerProfile) {
        serverProfiles.append(profile)
        saveServerProfiles()
    }

    func updateServerProfile(_ profile: ServerProfile) {
        if let index = serverProfiles.firstIndex(where: { $0.id == profile.id }) {
            serverProfiles[index] = profile
            saveServerProfiles()
        }
    }

    func deleteServerProfiles(at offsets: IndexSet) {
        serverProfiles.remove(atOffsets: offsets)
        saveServerProfiles()
    }

    func runAllChecks() async {
        guard !isCheckingUpdates else { return }
        isCheckingUpdates = true
        defer { isCheckingUpdates = false }

        var newItems: [ProviderStatus] = []
        let providers = allProviders

        for provider in providers {
            let available = await provider.isAvailable(runner: runner)

            if !available {
                newItems.append(
                    ProviderStatus(
                        id: provider.id,
                        name: provider.displayName,
                        statusText: "Not installed",
                        statusColor: .gray,
                        updates: [],
                        errorDetail: nil
                    )
                )
                continue
            }

            do {
                let updates = try await provider.checkUpdates(runner: runner)
                if updates.isEmpty {
                    newItems.append(
                        ProviderStatus(
                            id: provider.id,
                            name: provider.displayName,
                            statusText: "Up to date",
                            statusColor: .green,
                            updates: updates,
                            errorDetail: nil
                        )
                    )
                } else {
                    newItems.append(
                        ProviderStatus(
                            id: provider.id,
                            name: provider.displayName,
                            statusText: "\(updates.count) updates",
                            statusColor: .orange,
                            updates: updates,
                            errorDetail: nil
                        )
                    )
                }
            } catch {
                newItems.append(
                    ProviderStatus(
                        id: provider.id,
                        name: provider.displayName,
                        statusText: "Error",
                        statusColor: .red,
                        updates: [],
                        errorDetail: (error as NSError).localizedDescription
                    )
                )
            }
        }

        self.items = newItems
    }

    func applyUpdates(for providerID: String, items selectedItems: [UpdateItem]) async {
        guard !isApplyingUpdates else { return }
        isApplyingUpdates = true
        defer { isApplyingUpdates = false }

        guard let provider = allProviders.first(where: { $0.id == providerID }) else { return }
        do {
            try await provider.performUpdates(selectedItems, runner: runner)
        } catch {
            print("[DashboardViewModel] applyUpdates failed: \(error)")
        }
        await runAllChecks()
    }

    func updateAll() async {
        isApplyingUpdates = true
        currentTaskProgress = 0
        currentTaskLabel = "Preparing updates…"
        defer {
            isApplyingUpdates = false
            currentTaskProgress = nil
            currentTaskLabel = ""
        }

        let providers = allProviders
        let runnable: [(provider: UpdateProvider, status: ProviderStatus, updates: [UpdateItem])] = providers.compactMap { provider in
            guard let status = items.first(where: { $0.id == provider.id }) else { return nil }
            let selectable = status.updates.filter { $0.selected }
            guard !selectable.isEmpty else { return nil }
            return (provider, status, selectable)
        }
        let totalProviders = runnable.count
        guard totalProviders > 0 else { return }

        var processedProviders = 0
        for entry in runnable {
            processedProviders += 1
            await MainActor.run {
                currentTaskLabel = "Updating \(entry.status.name) (\(processedProviders) of \(totalProviders))"
                currentTaskProgress = Double(processedProviders - 1) / Double(totalProviders)
            }
            try? await entry.provider.performUpdates(entry.updates, runner: runner)
            await MainActor.run {
                currentTaskProgress = Double(processedProviders) / Double(totalProviders)
            }
        }

        await runAllChecks()
    }

    func maybeRunAutoCheck() async {
        guard autoCheckEnabled else { return }
        let interval = Double(autoCheckIntervalDays) * 24 * 60 * 60
        let now = Date().timeIntervalSince1970
        guard now - lastAutoCheck >= interval else { return }
        lastAutoCheck = now
        await runAllChecks()
    }
}
