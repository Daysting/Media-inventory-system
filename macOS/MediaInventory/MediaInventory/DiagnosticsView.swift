import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var showRepairConfirm = false
    @State private var repairMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - System Stats
                DiagnosticsCard(
                    title: "System Stats",
                    icon: "server.rack",
                    iconColor: .blue
                ) {
                    if apiClient.isLoadingDiagnostics {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text("Loading…").font(.system(size: 13)).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else if let stats = apiClient.diagnosticsStats {
                        DiagnosticsStatGrid(stats: stats)
                    } else {
                        Text("No data — tap Refresh to load stats.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                } actions: {
                    Button(action: { apiClient.fetchDiagnosticsStats() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(apiClient.isLoadingDiagnostics)
                }

                // MARK: - Database Integrity
                DiagnosticsCard(
                    title: "Database Integrity",
                    icon: "checkmark.shield.fill",
                    iconColor: integrityIconColor
                ) {
                    if apiClient.isCheckingIntegrity {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text("Checking integrity…").font(.system(size: 13)).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else if let healthy = apiClient.dbHealthy {
                        HStack(spacing: 10) {
                            Image(systemName: healthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(healthy ? .green : .orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(healthy ? "Database is Healthy" : "Issues Detected")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(healthy
                                     ? "All tables, records and foreign keys passed checks."
                                     : "Run Repair to attempt automatic fixes.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        Text("Not checked yet — tap Check Integrity to run validation.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                } actions: {
                    Button(action: { apiClient.checkDatabaseIntegrity() }) {
                        Label("Check Integrity", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .disabled(apiClient.isCheckingIntegrity)
                }

                // MARK: - Repair Database
                DiagnosticsCard(
                    title: "Repair Database",
                    icon: "wrench.and.screwdriver.fill",
                    iconColor: .orange
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Repair performs the following automatic fixes:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            RepairBullet("Remove orphaned checkout records")
                            RepairBullet("Fix checkout records with invalid status")
                            RepairBullet("Replace blank book titles with [Unknown Title]")
                            RepairBullet("Replace blank borrower names with [Unknown]")
                        }

                        if apiClient.isRepairing {
                            HStack {
                                ProgressView().scaleEffect(0.8)
                                Text("Repairing…").font(.system(size: 13)).foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        } else if let msg = repairMessage {
                            HStack(spacing: 6) {
                                Image(systemName: apiClient.lastRepairSuccess == true
                                      ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(apiClient.lastRepairSuccess == true ? .green : .red)
                                Text(msg)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                } actions: {
                    Button(role: .destructive, action: { showRepairConfirm = true }) {
                        Label("Repair Database", systemImage: "wrench.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(apiClient.isRepairing)
                    .confirmationDialog(
                        "Repair Database?",
                        isPresented: $showRepairConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Repair", role: .destructive) {
                            repairMessage = nil
                            apiClient.repairDatabase { success in
                                repairMessage = success
                                    ? "Repair completed successfully."
                                    : "Repair failed — check the error panel."
                                // Re-run integrity check to reflect new state
                                apiClient.checkDatabaseIntegrity()
                                apiClient.fetchDiagnosticsStats()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will modify database records. Run an integrity check first to confirm issues exist.")
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .onAppear {
            apiClient.fetchDiagnosticsStats()
        }
    }

    private var integrityIconColor: Color {
        guard let healthy = apiClient.dbHealthy else { return .gray }
        return healthy ? .green : .orange
    }
}

// MARK: - Diagnostics Card

private struct DiagnosticsCard<Content: View, Actions: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    @ViewBuilder let actions: Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                actions
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: NSColor.controlBackgroundColor))

            Divider()

            content
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Stat Grid

private struct DiagnosticsStatGrid: View {
    let stats: DiagnosticsStats

    var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                DiagnosticsStatCell(label: "Books",    value: stats.totalBooks,      icon: "book.fill",          color: .blue)
                DiagnosticsStatCell(label: "Games",    value: stats.totalGames,      icon: "gamecontroller.fill", color: .purple)
                DiagnosticsStatCell(label: "Movies",   value: stats.totalMovies,     icon: "film.fill",           color: .red)
            }
            GridRow {
                DiagnosticsStatCell(label: "Borrowers",  value: stats.totalBorrowers,  icon: "person.2.fill",    color: .teal)
                DiagnosticsStatCell(label: "Checked Out", value: stats.itemsCheckedOut, icon: "arrow.up.forward.circle.fill", color: .orange)
                Color.clear.gridCellColumns(1)
            }
        }
    }
}

private struct DiagnosticsStatCell: View {
    let label: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 20, weight: .semibold))
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - Repair Bullet

private struct RepairBullet: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Label(text, systemImage: "arrow.right.circle.fill")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .labelStyle(.titleAndIcon)
    }
}

#Preview {
    DiagnosticsView()
        .environmentObject(APIClient())
        .frame(width: 700, height: 600)
}
