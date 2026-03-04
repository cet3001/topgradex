import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel

    @AppStorage("autoCheckEnabled") private var autoCheckEnabled: Bool = true
    @AppStorage("autoCheckIntervalDays") private var autoCheckIntervalDays: Int = 3
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("provider_homebrew_enabled") private var homebrewEnabled: Bool = true
    @AppStorage("provider_mas_enabled") private var masEnabled: Bool = true
    @AppStorage("provider_npm_enabled") private var npmEnabled: Bool = true
    @AppStorage("provider_pip_enabled") private var pipEnabled: Bool = false
    @AppStorage("provider_gem_enabled") private var gemEnabled: Bool = false
    @AppStorage("provider_servers_enabled") private var serversEnabled: Bool = true
    @AppStorage("provider_macports_enabled") private var macPortsEnabled: Bool = false
    @AppStorage("provider_nix_enabled") private var nixEnabled: Bool = false
    @AppStorage("pip_allow_risky_updates") private var pipAllowRisky: Bool = false
    @AppStorage("gem_allow_risky_updates") private var gemAllowRisky: Bool = false

    @State private var showPipWarning = false
    @State private var showGemWarning = false
    @State private var showPipRiskWarning = false
    @State private var showGemRiskWarning = false
    @State private var appVersion: String = ""
    @State private var appBuild: String = ""
    @State private var newServerName: String = ""
    @State private var newServerHost: String = ""
    @State private var newServerCheckCommand: String = ""
    @State private var newServerUpdateCommand: String = ""

    var body: some View {
        Form {
            Section("Updates & automation") {
                Toggle("Auto check for updates", isOn: $autoCheckEnabled)
                Stepper("Check every \(autoCheckIntervalDays) days", value: $autoCheckIntervalDays, in: 1...14)
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onAppear {
                        if SMAppService.mainApp.status == .enabled {
                            launchAtLogin = true
                        }
                    }
                    .onChange(of: launchAtLogin) { _, newValue in
                        if newValue {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
            }

            Section("Servers & fleet") {
                Toggle("Enable Servers provider", isOn: $serversEnabled)
                Text("Remote servers over SSH")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.serverProfiles.isEmpty {
                    Text("No servers configured yet. Add one below.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(viewModel.serverProfiles) { profile in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name)
                                    .font(.headline)
                                Text(profile.host)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: viewModel.deleteServerProfiles)
                    }
                    .frame(maxHeight: 200)
                }

                Text("Add server")
                    .font(.subheadline)
                    .padding(.top, 8)

                TextField("Name (e.g. API server)", text: $newServerName)
                TextField("Host (e.g. ubuntu@api.example.com)", text: $newServerHost)
                TextField("Check command", text: $newServerCheckCommand)
                TextField("Update command", text: $newServerUpdateCommand)

                HStack {
                    Spacer()
                    Button("Save server") {
                        let trimmedName = newServerName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedHost = newServerHost.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedCheck = newServerCheckCommand.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedUpdate = newServerUpdateCommand.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard !trimmedName.isEmpty, !trimmedHost.isEmpty, !trimmedCheck.isEmpty, !trimmedUpdate.isEmpty else {
                            return
                        }

                        let profile = ServerProfile(
                            name: trimmedName,
                            host: trimmedHost,
                            checkCommand: trimmedCheck,
                            updateCommand: trimmedUpdate
                        )
                        viewModel.addServerProfile(profile)

                        newServerName = ""
                        newServerHost = ""
                        newServerCheckCommand = ""
                        newServerUpdateCommand = ""
                    }
                }
            }

            Section("Integrations") {
                Toggle("Homebrew", isOn: $homebrewEnabled)
                Text("CLI packages and casks")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Mac App Store (mas)", isOn: $masEnabled)
                Text("Mac App Store apps")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("npm (global)", isOn: $npmEnabled)
                Text("Global Node.js packages")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("pip (Python)", isOn: $pipEnabled)
                    .onChange(of: pipEnabled) { oldValue, newValue in
                        if !oldValue && newValue {
                            showPipWarning = true
                        }
                    }
                Text("Python packages (opt-in)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("gem (Ruby)", isOn: $gemEnabled)
                    .onChange(of: gemEnabled) { oldValue, newValue in
                        if !oldValue && newValue {
                            showGemWarning = true
                        }
                    }
                Text("Ruby gems (opt-in)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("MacPorts", isOn: $macPortsEnabled)
                Text("MacPorts packages (opt-in)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Nix", isOn: $nixEnabled)
                Text("Nix user environment (opt-in)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Advanced") {
                Toggle("Allow pip to modify system Python (PEP 668)", isOn: $pipAllowRisky)
                    .onChange(of: pipAllowRisky) { oldValue, newValue in
                        if !oldValue && newValue {
                            showPipRiskWarning = true
                        }
                    }

                Toggle("Allow Ruby to update system gems with sudo", isOn: $gemAllowRisky)
                    .onChange(of: gemAllowRisky) { oldValue, newValue in
                        if !oldValue && newValue {
                            showGemRiskWarning = true
                        }
                    }

                Text("These options can break your Python and Ruby installations. Only enable them if you understand the risks.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("About") {
                Text("TopgradeX keeps your Mac, developer tools, and servers up to date from a single menu bar app.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(appBuild)
                }
            }

            Section("Contact") {
                if let url = URL(string: "mailto:support@topgradex.app?subject=TopgradeX%20Feedback") {
                    Link("Email support", destination: url)
                }
                Text("Support emails are routed to calvin@blackstonerow.com.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            if SMAppService.mainApp.status == .enabled {
                launchAtLogin = true
            }
            if let info = Bundle.main.infoDictionary {
                appVersion = info["CFBundleShortVersionString"] as? String ?? ""
                appBuild = info["CFBundleVersion"] as? String ?? ""
            }
        }
        .alert("Be careful with Python updates", isPresented: $showPipWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your Python environment is externally managed (PEP 668). Auto-updating packages here can break your Homebrew or system Python. Prefer Homebrew, pipx, or virtual environments for Python tools.")
        }
        .alert("Be careful with Ruby updates", isPresented: $showGemWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("macOS system Ruby gems live under /Library/Ruby and require elevated permissions. Updating them here can break system tools. Prefer a user Ruby via rbenv or similar.")
        }
        .alert("Risky Python updates", isPresented: $showPipRiskWarning) {
            Button("Cancel", role: .cancel) {
                pipAllowRisky = false
            }
            Button("I understand", role: .destructive) { }
        } message: {
            Text("TopgradeX will call pip with '--break-system-packages' and '--user'. This can still break your Python or Homebrew installation. Prefer Homebrew, pipx, or virtual environments when possible.")
        }
        .alert("Risky Ruby updates", isPresented: $showGemRiskWarning) {
            Button("Cancel", role: .cancel) {
                gemAllowRisky = false
            }
            Button("I understand", role: .destructive) { }
        } message: {
            Text("TopgradeX will call 'sudo gem update' on system Ruby gems under /Library/Ruby. This can affect macOS system tools. Prefer using a user Ruby via rbenv.")
        }
    }
}
