//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

private struct ToastView: View {
    let icon: ImageResource
    let message: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text(message)
                .font(Typography.NeoDonggeunmoPro.R5)
                .foregroundStyle(.text1)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background {
            Capsule()
                .fill(.green3.opacity(0.8))
        }
    }
}

private struct ToastAlert: ViewModifier {
    @Binding var isPresented: Bool

    let icon: ImageResource
    let message: String

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                Group {
                    if isPresented {
                        ToastView(icon: icon, message: message)
                            .transition(
                                .move(edge: .bottom)
                                    .combined(with: .blurReplace)
                                    .animation(.snappy)
                            )
                    }
                }
                .padding(.bottom, Spacing.xxxl * 2)
                .animation(.default, value: isPresented)
            }
            .onChange(of: isPresented) { oldValue, newValue in
                if newValue {
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        isPresented = false
                    }
                }
            }
    }
}

extension View {
    @ViewBuilder
    func toastAlert(
        isPresented: Binding<Bool>,
        icon: ImageResource,
        message: String
    ) -> some View {
        self
            .modifier(
                ToastAlert(
                    isPresented: isPresented,
                    icon: icon,
                    message: message
                )
            )
    }
}

#Preview {
    @Previewable @State var isPresented = false

    Button("Present") {
        isPresented.toggle()
    }
    .toastAlert(
        isPresented: $isPresented,
        icon: .download,
        message: "녹음본과 악보가 저장되었어요"
    )
}
