import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var borrowerScanValue = ""
    @State private var activeBorrowerID = ""
    @State private var scannedMediaIDs: [String] = []
    @State private var mediaScanValue = ""
    @State private var showingMediaScanDialog = false
    @State private var checkoutResultMessage = ""
    @State private var isRunningCheckout = false
    @State private var returnScanValue = ""
    @State private var scannedReturnMediaIDs: [String] = []
    @State private var returnMediaScanValue = ""
    @State private var showingReturnScanDialog = false
    @State private var returnResultMessage = ""
    @State private var isRunningReturn = false
    @FocusState private var focusedField: FocusField?

    private enum FocusField {
        case borrowerID
        case mediaID
        case returnID
        case returnMediaID
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Checkout & Return Media")
                .font(.system(size: 18, weight: .semibold))
                .padding(20)
            
            HStack(spacing: 20) {
                // Checkout Form
                VStack(alignment: .leading, spacing: 12) {
                    Text("Checkout Media (Barcode Scanner)")
                        .font(.system(size: 14, weight: .semibold))
                    
                    VStack(spacing: 12) {
                        Text("1. Scan borrower barcode")
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("Scan Borrower ID", text: $borrowerScanValue)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .borrowerID)
                            .onSubmit {
                                beginMediaScanFlow()
                            }
                        
                        Button(action: beginMediaScanFlow) {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                Text("Continue to Media Scan")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        }

                        if !checkoutResultMessage.isEmpty {
                            Text(checkoutResultMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(16)
                .background(Color(nsColor: NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Return Form
                VStack(alignment: .leading, spacing: 12) {
                    Text("Return Media (Barcode Scanner)")
                        .font(.system(size: 14, weight: .semibold))
                    
                    VStack(spacing: 12) {
                        Text("1. Scan first media barcode")
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("Scan Media ID to Return", text: $returnScanValue)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .returnID)
                            .onSubmit {
                                beginReturnScanFlow()
                            }
                        
                        Button(action: beginReturnScanFlow) {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                Text("Continue to Return Scan")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        }

                        if !returnResultMessage.isEmpty {
                            Text(returnResultMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(16)
                .background(Color(nsColor: NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(20)
            
            Text("Currently Checked Out Items")
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("No items currently checked out")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(20)
            
            Spacer()
        }
        .sheet(isPresented: $showingMediaScanDialog) {
            mediaScanDialog
        }
        .sheet(isPresented: $showingReturnScanDialog) {
            returnScanDialog
        }
        .onAppear {
            apiClient.fetchBorrowers()
            focusedField = .borrowerID
        }
    }

    private var mediaScanDialog: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("2. Scan up to 5 media barcodes")
                .font(.system(size: 17, weight: .semibold))

            Text("Borrower ID: \(activeBorrowerID)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            TextField("Scan media barcode", text: $mediaScanValue)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .mediaID)
                .onSubmit {
                    addScannedMediaID()
                }

            Button("Add Scanned Barcode", action: addScannedMediaID)
                .disabled(mediaScanValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || scannedMediaIDs.count >= 5)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        Text("\(index + 1).")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 20, alignment: .leading)

                        if index < scannedMediaIDs.count {
                            Text(scannedMediaIDs[index])
                                .font(.system(size: 12))

                            Spacer()

                            Button {
                                scannedMediaIDs.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("Waiting for scan")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    resetScanSession()
                }

                Spacer()

                Button {
                    runCheckout()
                } label: {
                    if isRunningCheckout {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Checkout Scanned Media")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(scannedMediaIDs.isEmpty || isRunningCheckout)
            }
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 360)
        .onAppear {
            focusedField = .mediaID
        }
    }

    private var returnScanDialog: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("2. Scan up to 5 media barcodes to return")
                .font(.system(size: 17, weight: .semibold))

            TextField("Scan media barcode", text: $returnMediaScanValue)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .returnMediaID)
                .onSubmit {
                    addScannedReturnMediaID()
                }

            Button("Add Scanned Barcode", action: addScannedReturnMediaID)
                .disabled(returnMediaScanValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || scannedReturnMediaIDs.count >= 5)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        Text("\(index + 1).")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 20, alignment: .leading)

                        if index < scannedReturnMediaIDs.count {
                            Text(scannedReturnMediaIDs[index])
                                .font(.system(size: 12))

                            Spacer()

                            Button {
                                scannedReturnMediaIDs.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("Waiting for scan")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    resetReturnSession()
                }

                Spacer()

                Button {
                    runReturn()
                } label: {
                    if isRunningReturn {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Return Scanned Media")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(scannedReturnMediaIDs.isEmpty || isRunningReturn)
            }
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 360)
        .onAppear {
            focusedField = .returnMediaID
        }
    }

    private func beginMediaScanFlow() {
        let normalizedID = borrowerScanValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedID.isEmpty else {
            checkoutResultMessage = "Scan a borrower ID first."
            return
        }

        guard apiClient.borrowers.contains(where: { $0.id == normalizedID }) else {
            checkoutResultMessage = "Borrower ID \(normalizedID) was not found."
            return
        }

        activeBorrowerID = normalizedID
        scannedMediaIDs = []
        mediaScanValue = ""
        checkoutResultMessage = ""
        showingMediaScanDialog = true
    }

    private func addScannedMediaID() {
        guard scannedMediaIDs.count < 5 else { return }
        let normalizedValue = mediaScanValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedValue.isEmpty else { return }
        guard !scannedMediaIDs.contains(normalizedValue) else {
            mediaScanValue = ""
            return
        }

        scannedMediaIDs.append(normalizedValue)
        mediaScanValue = ""
        focusedField = .mediaID
    }

    private func runCheckout() {
        isRunningCheckout = true
        let borrowerID = activeBorrowerID
        let mediaIDs = scannedMediaIDs

        apiClient.checkoutMediaBatch(borrowerID: borrowerID, mediaIDs: mediaIDs) { result in
            isRunningCheckout = false

            let successCount = result.attempts.filter { $0.success }.count
            let failureMessages = result.attempts
                .filter { !$0.success }
                .map { "\($0.mediaID): \($0.message)" }

            checkoutResultMessage = "Checked out \(successCount)/\(result.attempts.count) items for borrower \(result.borrowerID)."
            if !failureMessages.isEmpty {
                checkoutResultMessage += " Failed: " + failureMessages.joined(separator: "; ")
            }

            showingMediaScanDialog = false
            borrowerScanValue = ""
            activeBorrowerID = ""
            scannedMediaIDs = []
            mediaScanValue = ""
            focusedField = .borrowerID
        }
    }

    private func beginReturnScanFlow() {
        let firstScan = returnScanValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !firstScan.isEmpty else {
            returnResultMessage = "Scan a media barcode first."
            return
        }

        scannedReturnMediaIDs = [firstScan]
        returnMediaScanValue = ""
        returnResultMessage = ""
        showingReturnScanDialog = true
    }

    private func addScannedReturnMediaID() {
        guard scannedReturnMediaIDs.count < 5 else { return }
        let normalizedValue = returnMediaScanValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedValue.isEmpty else { return }
        guard !scannedReturnMediaIDs.contains(normalizedValue) else {
            returnMediaScanValue = ""
            return
        }

        scannedReturnMediaIDs.append(normalizedValue)
        returnMediaScanValue = ""
        focusedField = .returnMediaID
    }

    private func runReturn() {
        isRunningReturn = true
        let mediaIDs = scannedReturnMediaIDs

        apiClient.returnMediaBatch(mediaIDs: mediaIDs) { result in
            isRunningReturn = false

            let successCount = result.attempts.filter { $0.success }.count
            let failureMessages = result.attempts
                .filter { !$0.success }
                .map { "\($0.mediaID): \($0.message)" }

            returnResultMessage = "Returned \(successCount)/\(result.attempts.count) items."
            if !failureMessages.isEmpty {
                returnResultMessage += " Failed: " + failureMessages.joined(separator: "; ")
            }

            showingReturnScanDialog = false
            returnScanValue = ""
            scannedReturnMediaIDs = []
            returnMediaScanValue = ""
            focusedField = .returnID
        }
    }

    private func resetScanSession() {
        showingMediaScanDialog = false
        activeBorrowerID = ""
        scannedMediaIDs = []
        mediaScanValue = ""
        isRunningCheckout = false
        focusedField = .borrowerID
    }

    private func resetReturnSession() {
        showingReturnScanDialog = false
        scannedReturnMediaIDs = []
        returnMediaScanValue = ""
        isRunningReturn = false
        focusedField = .returnID
    }
}

#Preview {
    CheckoutView()
        .environmentObject(APIClient())
}
