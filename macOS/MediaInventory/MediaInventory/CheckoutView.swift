import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var apiClient: APIClient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Checkout & Return Media")
                .font(.system(size: 18, weight: .semibold))
                .padding(20)
            
            HStack(spacing: 20) {
                // Checkout Form
                VStack(alignment: .leading, spacing: 12) {
                    Text("Checkout Media")
                        .font(.system(size: 14, weight: .semibold))
                    
                    VStack(spacing: 12) {
                        TextField("Borrower ID", text: .constant(""))
                        TextField("Item ID", text: .constant(""))
                        Picker("Item Type", selection: .constant("book")) {
                            Text("Book").tag("book")
                            Text("Video Game").tag("game")
                            Text("Movie").tag("movie")
                        }
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "arrow.up")
                                Text("Checkout")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        }
                    }
                }
                .padding(16)
                .background(Color(nsColor: NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Return Form
                VStack(alignment: .leading, spacing: 12) {
                    Text("Return Media")
                        .font(.system(size: 14, weight: .semibold))
                    
                    VStack(spacing: 12) {
                        TextField("Checkout ID", text: .constant(""))
                        TextEditor(text: .constant(""))
                            .frame(height: 60)
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "arrow.down")
                                Text("Return")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
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
    }
}

#Preview {
    CheckoutView()
        .environmentObject(APIClient())
}
