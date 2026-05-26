//
//  AccountView.swift
//  TodayIs
//
//  Shown when the user taps the person icon in the toolbar.
//  - Not signed in → shows SignInView inline
//  - Signed in     → shows profile info + sign-out button
//

import FirebaseAuth
import SwiftUI

struct AccountView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if authService.isSignedIn {
                signedInBody
            } else {
                SignInView()
            }
        }
    }

    // MARK: - Signed-in state

    private var signedInBody: some View {
        List {
            // Profile row
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        if let name = authService.user?.displayName, !name.isEmpty {
                            Text(name).font(.headline)
                        }
                        if let email = authService.user?.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            // Sync status
            Section {
                Label("Goals synced to cloud", systemImage: "checkmark.icloud")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }

            // Sign out
            Section {
                Button(role: .destructive) {
                    authService.signOut()
                    dismiss()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    AccountView()
        .environment(AuthService())
}
