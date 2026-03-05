import SwiftUI

struct GroupJoinView: View {
    @StateObject private var groupManager = GroupManager.shared
    @State private var code: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                // Title
                VStack(spacing: 8) {
                    Text("Únete a tu grupo")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Introduce el código de invitación que te han dado (ej. ROMA25)")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Input
                TextField("CÓDIGO", text: $code)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onChange(of: code) { newValue in
                        code = newValue.uppercased()
                    }
                
                if let error = groupManager.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                
                // Button
                Button(action: joinGroup) {
                    if groupManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Unirse al Grupo")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(code.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(code.isEmpty || groupManager.isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Grupo Privado")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
    
    private func joinGroup() {
        Task {
            if await groupManager.joinGroup(code: code) {
                dismiss() // Or navigate to detail
            }
        }
    }
}
