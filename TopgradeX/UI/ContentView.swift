import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @State private var selectedStatus: ProviderStatus?
    @State private var isShowingDetail = false
    @State private var showDashboard: Bool = false

    var body: some View {
        Group {
            if onboardingCompleted {
                dashboardView
                    .opacity(showDashboard ? 1 : 0)
                    .scaleEffect(showDashboard ? 1 : 0.97)
            } else {
                OnboardingView()
            }
        }
        .onChange(of: onboardingCompleted) { oldValue, newValue in
            if !oldValue && newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showDashboard = true
                }
            }
        }
        .task {
            if onboardingCompleted {
                showDashboard = true
            }
        }
        .sheet(isPresented: $isShowingDetail) {
            if let status = selectedStatus {
                ProviderDetailView(status: status) { items in
                    Task {
                        await viewModel.applyUpdates(for: status.id, items: items)
                        isShowingDetail = false
                    }
                }
            }
        }
    }

    private var dashboardView: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TopgradeX")
                        .font(.headline)
                    Spacer()
                    Button("Check now") {
                        Task { await viewModel.runAllChecks() }
                    }
                    Button("Update all") {
                        Task { await viewModel.updateAll() }
                    }
                    .disabled(viewModel.isCheckingUpdates || viewModel.isApplyingUpdates)
                }

                List(viewModel.items) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text(item.statusText)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(item.statusColor.opacity(0.15))
                            .foregroundColor(item.statusColor)
                            .clipShape(Capsule())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedStatus = item
                        isShowingDetail = true
                    }
                }
                .frame(maxHeight: 280)

                Toggle("Auto check twice per week", isOn: $viewModel.autoCheckEnabled)

                SettingsLink {
                    HStack {
                        Spacer()
                        Text("Settings…")
                    }
                }
                .buttonStyle(.link)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(nsColor: .windowBackgroundColor),
                        Color.accentColor.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)

            if viewModel.isCheckingUpdates || viewModel.isApplyingUpdates {
                LoadingOverlay(
                    text: viewModel.currentTaskLabel.isEmpty
                        ? (viewModel.isCheckingUpdates ? "Checking for updates…" : "Applying updates…")
                        : viewModel.currentTaskLabel,
                    progress: viewModel.currentTaskProgress
                )
            }
        }
    }
}
