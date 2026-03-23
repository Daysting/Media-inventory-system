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
            
            Table(apiClient.borrowers) {
                TableColumn("Name", value: \.fullName)
                TableColumn("Email") { borrower in
                    Text(borrower.email ?? "-")
                }
                TableColumn("Phone") { borrower in
                    Text(borrower.phoneNumber ?? "-")
                }
                TableColumn("Address") { borrower in
                    Text(borrower.address ?? "-")
                }
                TableColumn("") { borrower in
                    HStack(spacing: 8) {
                        Button(action: { borrowerToEdit = borrower }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: { apiClient.deleteBorrower(id: borrower.id) }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(20)
            
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
