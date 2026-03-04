import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            IntegrationsSettingsView()
                .tabItem {
                    Label("Integrations", systemImage: "puzzlepiece.extension")
                }

            ServersSettingsView()
                .tabItem {
                    Label("Servers", systemImage: "server.rack")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - General
private struct GeneralSettingsView: View {
    @AppStorage("autoCheckEnabled") private var autoCheckEnabled: Bool = true
    @AppStorage("autoCheckIntervalDays") private var autoCheckIntervalDays: Int = 3
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

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
        }
        .formStyle(.grouped)
    }
}

// MARK: - Integrations
private struct IntegrationsSettingsView: View {
    @AppStorage("provider_homebrew_enabled") private var homebrewEnabled: Bool = true
    @AppStorage("provider_mas_enabled") private var masEnabled: Bool = true
    @AppStorage("provider_npm_enabled") private var npmEnabled: Bool = true
    @AppStorage("provider_pip_enabled") private var pipEnabled: Bool = false
    @AppStorage("provider_macports_enabled") private var macPortsEnabled: Bool = false
    @AppStorage("provider_nix_enabled") private var nixEnabled: Bool = false
    @AppStorage("pip_allow_risky_updates") private var pipAllowRisky: Bool = false

    @State private var showPipWarning = false
    @State private var showPipRiskWarning = false

    var body: some View {
        Form {
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

                Text("These options can break your Python installation. Only enable if you understand the risks.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Why no Ruby?") {
                Text("We intentionally do not manage the macOS system Ruby. System gems live under /Library/Ruby and are managed by the OS, and using sudo to update them can break system tools. If you need Ruby updates, use a user Ruby (for example via rbenv) instead.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .alert("Be careful with Python updates", isPresented: $showPipWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your Python environment is externally managed (PEP 668). Auto-updating packages here can break your Homebrew or system Python. Prefer Homebrew, pipx, or virtual environments for Python tools.")
        }
        .alert("Risky Python updates", isPresented: $showPipRiskWarning) {
            Button("Cancel", role: .cancel) {
                pipAllowRisky = false
            }
            Button("I understand", role: .destructive) { }
        } message: {
            Text("TopgradeX will call pip with '--break-system-packages' and '--user'. This can still break your Python or Homebrew installation. Prefer Homebrew, pipx, or virtual environments when possible.")
        }
    }
}

// MARK: - Servers
private struct ServersSettingsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel

    @AppStorage("provider_servers_enabled") private var serversEnabled: Bool = true

    @State private var newServerName: String = ""
    @State private var newServerHost: String = ""
    @State private var newServerPort: String = ""
    @State private var newServerType: ServerType = .ubuntuDebian
    @State private var newServerCheckCommand: String = ""
    @State private var newServerUpdateCommand: String = ""
    @State private var newServerNotes: String = ""

    var body: some View {
        Form {
            Section("Servers & fleet") {
                Toggle("Enable Servers provider", isOn: $serversEnabled)
                Text("Remote servers over SSH")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("TopgradeX uses your existing SSH keys and ssh-agent. Set up SSH access separately before adding servers here.")
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
                TextField("Port (optional)", text: $newServerPort)
                    .help("Leave empty for default SSH port 22")

                Picker("Server type", selection: $newServerType) {
                    ForEach(ServerType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                .onChange(of: newServerType) { _, newType in
                    let checkEmpty = newServerCheckCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    let updateEmpty = newServerUpdateCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    guard checkEmpty, updateEmpty else { return }
                    switch newType {
                    case .ubuntuDebian:
                        newServerCheckCommand = "apt list --upgradable 2>/dev/null | grep -v \"^Listing\""
                        newServerUpdateCommand = "sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y"
                    case .centosRhel:
                        newServerCheckCommand = "yum check-update || true"
                        newServerUpdateCommand = "sudo yum -y update"
                    case .other:
                        newServerCheckCommand = ""
                        newServerUpdateCommand = ""
                    }
                }

                Text("Commands auto-filled for this server type. You can tweak them if needed.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Check command", text: $newServerCheckCommand)
                TextField("Update command", text: $newServerUpdateCommand)
                TextField("Notes (SSH key, config, etc.)", text: $newServerNotes, axis: .vertical)
                    .lineLimit(2...4)

                HStack {
                    Spacer()
                    Button("Save server") {
                        let trimmedName = newServerName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedHost = newServerHost.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedCheck = newServerCheckCommand.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedUpdate = newServerUpdateCommand.trimmingCharacters(in: .whitespacesAndNewlines)
                        let port: Int? = Int(newServerPort.trimmingCharacters(in: .whitespacesAndNewlines))
                        let trimmedNotes = newServerNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                        let notes: String? = trimmedNotes.isEmpty ? nil : trimmedNotes

                        guard !trimmedName.isEmpty, !trimmedHost.isEmpty, !trimmedCheck.isEmpty, !trimmedUpdate.isEmpty else {
                            return
                        }

                        let profile = ServerProfile(
                            name: trimmedName,
                            host: trimmedHost,
                            port: port,
                            serverType: newServerType,
                            checkCommand: trimmedCheck,
                            updateCommand: trimmedUpdate,
                            notes: notes
                        )
                        viewModel.addServerProfile(profile)

                        newServerName = ""
                        newServerHost = ""
                        newServerPort = ""
                        newServerNotes = ""
                        newServerType = .ubuntuDebian
                        newServerCheckCommand = "apt list --upgradable 2>/dev/null | grep -v \"^Listing\""
                        newServerUpdateCommand = "sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y"
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            if newServerCheckCommand.isEmpty && newServerUpdateCommand.isEmpty && newServerName.isEmpty {
                newServerCheckCommand = "apt list --upgradable 2>/dev/null | grep -v \"^Listing\""
                newServerUpdateCommand = "sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y"
            }
        }
    }
}

// MARK: - About
private struct AboutSettingsView: View {
    @State private var appVersion: String = ""
    @State private var appBuild: String = ""

    var body: some View {
        Form {
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
        .onAppear {
            if let info = Bundle.main.infoDictionary {
                appVersion = info["CFBundleShortVersionString"] as? String ?? ""
                appBuild = info["CFBundleVersion"] as? String ?? ""
            }
        }
    }
}
