import SwiftUI

struct BorrowersView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var showingAddForm = false
    @State private var borrowerToEdit: Borrower?
    @State private var searchText = ""
    
    var filteredBorrowers: [Borrower] {
        if searchText.isEmpty {
            return apiClient.borrowers
        }
        return apiClient.borrowers.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            ($0.phoneNumber?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: { showingAddForm = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Borrower")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(6)
                }
                
                SearchField(text: $searchText, placeholder: "Search borrowers...")
            }
            .padding(20)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(20)
            
            if apiClient.borrowers.isEmpty {
                Text("No borrowers yet")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("Name").font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Email").font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Phone").font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Address").font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Actions").font(.system(size: 12, weight: .semibold)).frame(width: 80, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(nsColor: NSColor.controlBackgroundColor))

                    ForEach(apiClient.borrowers) { borrower in
                        BorrowerRow(
                            borrower: borrower,
                            onEdit: { borrowerToEdit = borrower },
                            onDelete: { apiClient.deleteBorrower(id: borrower.id) }
                        )
                    }
                }
                .background(Color(nsColor: NSColor.windowBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(20)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingAddForm) {
            AddBorrowerForm(isPresented: $showingAddForm)
                .environmentObject(apiClient)
        }
        .sheet(item: $borrowerToEdit) { borrower in
            EditBorrowerForm(borrower: borrower)
                .environmentObject(apiClient)
        }
        .onAppear {
            apiClient.fetchBorrowers()
        }
    }
}

struct AddBorrowerForm: View {
    @EnvironmentObject var apiClient: APIClient
    @Binding var isPresented: Bool
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var address = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add New Borrower")
                .font(.system(size: 18, weight: .semibold))
            
            Form {
                Section("Personal Information") {
                    TextField("First Name *", text: $firstName)
                    TextField("Last Name *", text: $lastName)
                }
                
                Section("Contact Information") {
                    TextField("Email", text: $email)
                    TextField("Phone Number", text: $phoneNumber)
                    TextField("Address", text: $address)
                }
            }
            
            HStack {
                Button("Cancel") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add Borrower") {
                    apiClient.addBorrower(
                        firstName: firstName,
                        lastName: lastName,
                        address: address.isEmpty ? nil : address,
                        phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                        email: email.isEmpty ? nil : email
                    )
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(firstName.isEmpty || lastName.isEmpty)
            }
            .padding()
        }
        .padding(20)
        .frame(minWidth: 400, minHeight: 400)
    }
}

private struct BorrowerRow: View {
    let borrower: Borrower
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(borrower.fullName)
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(borrower.email ?? "-")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(borrower.phoneNumber ?? "-")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(borrower.address ?? "-")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()
        }
    }
}

#Preview {
    BorrowersView()
        .environmentObject(APIClient())
}

struct EditBorrowerForm: View {
    @EnvironmentObject var apiClient: APIClient
    @Environment(\.dismiss) private var dismiss
    let borrower: Borrower

    @State private var firstName: String
    @State private var lastName: String
    @State private var phoneNumber: String
    @State private var address: String

    init(borrower: Borrower) {
        self.borrower = borrower
        _firstName = State(initialValue: borrower.firstName)
        _lastName = State(initialValue: borrower.lastName)
        _phoneNumber = State(initialValue: borrower.phoneNumber ?? "")
        _address = State(initialValue: borrower.address ?? "")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Borrower")
                .font(.system(size: 18, weight: .semibold))

            Form {
                Section("Personal Information") {
                    TextField("First Name *", text: $firstName)
                    TextField("Last Name *", text: $lastName)
                }

                Section("Contact Information") {
                    TextField("Phone Number", text: $phoneNumber)
                    TextField("Address", text: $address)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save Changes") {
                    apiClient.updateBorrower(
                        id: borrower.id,
                        firstName: firstName,
                        lastName: lastName,
                        address: address.isEmpty ? nil : address,
                        phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(firstName.isEmpty || lastName.isEmpty)
            }
            .padding()
        }
        .padding(20)
        .frame(minWidth: 400, minHeight: 400)
    }
}
