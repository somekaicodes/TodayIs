//
//  SplashView.swift
//  TodayIs
//
//  Created by Kai Kim on 2026-05-17.
//

import SwiftUI

struct SplashView: View {
    @Binding var isShowing: Bool
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Kyumin")
                    .font(.system(size: 48, weight: .thin, design: .default))
                    .foregroundStyle(.primary)
                Text("productions")
                    .font(.system(size: 16, weight: .light, design: .default))
                    .foregroundStyle(.secondary)
                    .kerning(4)
            }
        }
        .opacity(opacity)
        .onAppear {
            // Hold for 3 seconds then fade out over 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isShowing = false
                }
            }
        }
    }
}

#Preview {
    SplashView(isShowing: .constant(true))
}
