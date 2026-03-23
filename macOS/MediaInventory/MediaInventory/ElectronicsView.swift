import SwiftUI

struct ElectronicsView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var showingAddForm = false
    @State private var electronicToEdit: Electronic?
    @State private var searchText = ""

    var filteredElectronics: [Electronic] {
        if searchText.isEmpty {
            return apiClient.electronics
        }

        return apiClient.electronics.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.serialNumber?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: { showingAddForm = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Electronic")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(6)
                }

                SearchField(text: $searchText, placeholder: "Search electronics...")
            }
            .padding(20)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(20)

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220, maximum: 260))],
                    spacing: 16
                ) {
                    ForEach(filteredElectronics) { electronic in
                        ElectronicCard(
                            title: electronic.title,
                            serialNumber: electronic.serialNumber,
                            description: electronic.description,
                            cost: electronic.cost,
                            onEdit: { electronicToEdit = electronic }
                        ) {
                            apiClient.deleteElectronic(id: electronic.id)
                        }
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showingAddForm) {
            AddElectronicForm(isPresented: $showingAddForm)
                .environmentObject(apiClient)
        }
        .sheet(item: $electronicToEdit) { electronic in
            EditElectronicForm(electronic: electronic)
                .environmentObject(apiClient)
        }
        .onAppear {
            apiClient.fetchElectronics()
        }
    }
}

private struct ElectronicCard: View {
    let title: String
    let serialNumber: String?
    let description: String?
    let cost: Double?
    var onEdit: (() -> Void)?
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)

                    Text(serialNumberLine)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if let cost {
                        Text("Cost: \(cost.currencyDisplayText)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    if let description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }

                Spacer(minLength: 12)

                if isHovering {
                    HStack(spacing: 4) {
                        if let onEdit {
                            Button(action: onEdit) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.blue.opacity(0.85))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Button(action: onDelete) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.red.opacity(0.85))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(
            color: Color.black.opacity(isHovering ? 0.12 : 0.05),
            radius: isHovering ? 8 : 3,
            x: 0,
            y: 2
        )
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }

    private var serialNumberLine: String {
        if let serialNumber, !serialNumber.isEmpty {
            return "Serial Number: \(serialNumber)"
        }

        return "Serial Number: Not set"
    }
}

private struct AddElectronicForm: View {
    @EnvironmentObject var apiClient: APIClient
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var serialNumber = ""
    @State private var cost = ""
    @State private var description = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Electronic")
                .font(.system(size: 18, weight: .semibold))

            Form {
                Section("Basic Information") {
                    TextField("Title *", text: $title)
                    TextField("Serial Number", text: $serialNumber)
                    TextField("Cost", text: $cost)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                }
            }

            HStack {
                Button("Cancel") { isPresented = false }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add Electronic") {
                    apiClient.addElectronic(
                        title: title,
                        serialNumber: serialNumber.isEmpty ? nil : serialNumber,
                        cost: parseCurrency(cost),
                        description: description.isEmpty ? nil : description
                    )
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
            .padding()
        }
        .padding(20)
        .frame(minWidth: 500, minHeight: 460)
    }
}

private struct EditElectronicForm: View {
    @EnvironmentObject var apiClient: APIClient
    @Environment(\.dismiss) private var dismiss
    let electronic: Electronic

    @State private var title: String
    @State private var serialNumber: String
    @State private var cost: String
    @State private var description: String

    init(electronic: Electronic) {
        self.electronic = electronic
        _title = State(initialValue: electronic.title)
        _serialNumber = State(initialValue: electronic.serialNumber ?? "")
        _cost = State(initialValue: electronic.cost.map { String(format: "%.2f", $0) } ?? "")
        _description = State(initialValue: electronic.description ?? "")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Electronic")
                .font(.system(size: 18, weight: .semibold))

            Form {
                Section("Basic Information") {
                    TextField("Title *", text: $title)
                    TextField("Serial Number", text: $serialNumber)
                    TextField("Cost", text: $cost)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save Changes") {
                    apiClient.updateElectronic(
                        id: electronic.id,
                        title: title,
                        serialNumber: serialNumber.isEmpty ? nil : serialNumber,
                        cost: parseCurrency(cost),
                        description: description.isEmpty ? nil : description
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
            .padding()
        }
        .padding(20)
        .frame(minWidth: 500, minHeight: 460)
    }
}

#Preview {
    ElectronicsView()
        .environmentObject(APIClient())
}
