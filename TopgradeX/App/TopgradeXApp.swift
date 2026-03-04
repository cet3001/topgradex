import SwiftUI

@main
struct TopgradeXApp: App {
    @StateObject private var dashboardViewModel = DashboardViewModel()

    var body: some Scene {
        MenuBarExtra("TopgradeX", systemImage: "arrow.triangle.2.circlepath") {
            ContentView()
                .environmentObject(dashboardViewModel)
                .frame(width: 360, height: 460)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(dashboardViewModel)
        }
    }
}
