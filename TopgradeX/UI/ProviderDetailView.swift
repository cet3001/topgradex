import SwiftUI

struct ProviderDetailView: View {
    let status: ProviderStatus
    let onApply: ([UpdateItem]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var items: [UpdateItem]
    @State private var isApplying: Bool = false

    init(status: ProviderStatus, onApply: @escaping ([UpdateItem]) -> Void) {
        self.status = status
        self.onApply = onApply
        _items = State(initialValue: status.updates)
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

                List {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Toggle("", isOn: binding(at: index, for: item))
                                .labelsHidden()
                                .toggleStyle(.checkbox)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.body)
                                Text(item.details)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                .listStyle(.inset)

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
