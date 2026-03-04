import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("autoCheckEnabled") private var autoCheckEnabled: Bool = true
    @State private var currentPage: Int = 0
    @State private var isSpinning: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            if currentPage == 0 {
                welcomePage
            } else if currentPage == 1 {
                permissionsPage
            } else {
                preferencesPage
            }

            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                }
                Spacer()
                if currentPage < 2 {
                    Button("Continue") {
                        withAnimation { currentPage += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get started") {
                        isSpinning = true
                        withAnimation(.easeInOut(duration: 0.6)) {}
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onboardingCompleted = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private var welcomePage: some View {
        VStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(.easeInOut(duration: 0.6), value: isSpinning)

            Text("Welcome to TopgradeX")
                .font(.title2.bold())

            Text("TopgradeX keeps your Mac, developer tools, and servers up to date from one menu bar.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }

    private var permissionsPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What we keep fresh")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                bullet("Homebrew, Mac App Store, npm and other developer tools.")
                bullet("Optional: MacPorts, Nix, pip, and Ruby for advanced setups.")
                bullet("Servers over SSH, using your existing keys and ssh-agent.")
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }

    private var preferencesPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Automation & startup")
                .font(.title2.bold())

            Text("TopgradeX runs quiet checks in the background so updates are ready when you are.")
                .font(.body)
                .foregroundColor(.secondary)

            Text("It starts at login by default, and you can turn this off any time in Settings.")
                .font(.body)
                .foregroundColor(.secondary)

            Toggle("Auto check for updates", isOn: $autoCheckEnabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
