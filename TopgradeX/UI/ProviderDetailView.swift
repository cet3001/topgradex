import SwiftUI

struct ProviderDetailView: View {
    let status: ProviderStatus
    let onApply: ([UpdateItem]) -> Void

    @EnvironmentObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var items: [UpdateItem]
    @State private var isApplying: Bool = false
    @State private var isLoading: Bool = false

    init(status: ProviderStatus, onApply: @escaping ([UpdateItem]) -> Void) {
        self.status = status
        self.onApply = onApply
        _items = State(initialValue: status.updates)
    }

    private var currentStatus: ProviderStatus? {
        viewModel.items.first { $0.id == status.id }
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(status.name)
                        .font(.headline)
                    Spacer()
                    Button("Cancel") {
                        dismiss()
                    }
                }
                .padding()

                Divider()

                if let error = status.errorDetail {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isLoading {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.accentColor)
                        Text("Loading updates…")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                } else {
                    List {
                        Section("Select updates to apply") {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                Toggle(isOn: binding(at: index, for: item)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.body)
                                        if !item.details.isEmpty {
                                            Text(item.details)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .toggleStyle(.checkbox)
                            }
                        }
                    }
                    .listStyle(.inset)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Divider()

                HStack {
                    Spacer()
                    Button("Update selected") {
                        let selected = items.filter { $0.selected }
                        guard !selected.isEmpty else { return }
                        isApplying = true
                        onApply(selected)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(items.filter { $0.selected }.isEmpty || status.errorDetail != nil)
                }
                .padding()
            }
            .frame(minWidth: 360, minHeight: 320)
            .onAppear {
                if !status.updates.isEmpty {
                    isLoading = false
                } else if viewModel.isCheckingUpdates {
                    isLoading = true
                }
            }
            .onChange(of: viewModel.items) { _, _ in
                guard let current = currentStatus, !current.updates.isEmpty else { return }
                if items.isEmpty {
                    withAnimation(.easeOut(duration: 0.25)) {
                        items = current.updates
                        isLoading = false
                    }
                }
            }

            if isApplying {
                LoadingOverlay(text: "Applying updates…", progress: nil)
            }
        }
    }

    private func binding(at index: Int, for item: UpdateItem) -> Binding<Bool> {
        Binding(
            get: {
                guard index < items.count, items[index].id == item.id else { return item.selected }
                return items[index].selected
            },
            set: { newValue in
                guard index < items.count, items[index].id == item.id else { return }
                var updated = items
                updated[index] = UpdateItem(id: item.id, name: item.name, details: item.details, selected: newValue)
                items = updated
            }
        )
    }
}
