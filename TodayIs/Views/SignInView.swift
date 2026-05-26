//
//  SignInView.swift
//  TodayIs
//
//  Presented when the user taps the account icon and is not signed in.
//  Currently offers Google Sign-In only.
//  Sign in with Apple can be re-enabled once a paid Apple Developer account
//  is set up — uncomment the Apple button below and add the
//  "Sign in with Apple" capability in Signing & Capabilities.
//

import SwiftUI

struct SignInView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            // ── Hero ──
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                VStack(spacing: 6) {
                    Text("Sync your goals")
                        .font(.title2.weight(.bold))
                    Text("Sign in to access your calendars\non any device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // ── Buttons ──
            VStack(spacing: 12) {

                // Google
                Button {
                    Task { await authService.signInWithGoogle() }
                } label: {
                    HStack(spacing: 10) {
                        // Simple "G" badge — replace with a real Google logo asset if desired
                        ZStack {
                            Circle().fill(Color.white).frame(width: 22, height: 22)
                            Text("G")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(red: 0.26, green: 0.52, blue: 0.96))
                        }
                        Text("Continue with Google")
                            .font(.body.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(.separator), lineWidth: 1)
                    )
                }

                // Apple — re-enable once paid Apple Developer account is set up
                // Button {
                //     authService.startAppleSignIn()
                // } label: {
                //     HStack(spacing: 10) {
                //         Image(systemName: "apple.logo")
                //             .font(.body.weight(.medium))
                //         Text("Continue with Apple")
                //             .font(.body.weight(.medium))
                //     }
                //     .frame(maxWidth: .infinity)
                //     .padding(.vertical, 14)
                //     .background(Color.primary)
                //     .foregroundStyle(Color(.systemBackground))
                //     .clipShape(RoundedRectangle(cornerRadius: 12))
                // }

                // Skip
                Button("Not now") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
        // Dismiss automatically once signed in
        .onChange(of: authService.isSignedIn) { _, signedIn in
            if signedIn { dismiss() }
        }
        // Loading overlay
        .overlay {
            if authService.isLoading {
                Color(.systemBackground).opacity(0.6)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.4)
            }
        }
        .alert("Sign-in error",
               isPresented: Binding(
                get: { authService.error != nil },
                set: { if !$0 { authService.error = nil } }
               )
        ) {
            Button("OK") { authService.error = nil }
        } message: {
            Text(authService.error ?? "")
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthService())
}
