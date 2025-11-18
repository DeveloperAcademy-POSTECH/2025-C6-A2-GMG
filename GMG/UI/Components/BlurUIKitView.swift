//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import BlurUIKit
import SwiftUI

struct BlurUIKitView: UIViewRepresentable {
    let direction: VariableBlurView.Direction
    let maximumBlurRadius: Double
    let blurStartingInset: VariableBlurView.GradientSizing?
    let dimmingTintColor: UIColor?
    let dimmingAlpha: VariableBlurView.DimmingAlpha?
    let dimmingOvershoot: VariableBlurView.GradientSizing?
    let dimmingStartingInset: VariableBlurView.GradientSizing?

    init(
        direction: VariableBlurView.Direction = .down,
        maximumBlurRadius: Double = 3.5,
        blurStartingInset: VariableBlurView.GradientSizing? = nil,
        dimmingTintColor: UIColor? = .systemBackground,
        dimmingAlpha: VariableBlurView.DimmingAlpha? =
            .interfaceStyle(
                lightModeAlpha: 0.5,
                darkModeAlpha: 0.25
            ),
        dimmingOvershoot: VariableBlurView.GradientSizing? = .relative(fraction: 0.25),
        dimmingStartingInset: VariableBlurView.GradientSizing? = nil
    ) {
        self.direction = direction
        self.maximumBlurRadius = maximumBlurRadius
        self.blurStartingInset = blurStartingInset
        self.dimmingTintColor = dimmingTintColor
        self.dimmingAlpha = dimmingAlpha
        self.dimmingOvershoot = dimmingOvershoot
        self.dimmingStartingInset = dimmingStartingInset
    }

    func makeUIView(context: Context) -> VariableBlurView {
        let blurView = VariableBlurView()

        blurView.direction = direction
        blurView.maximumBlurRadius = maximumBlurRadius
        blurView.blurStartingInset = blurStartingInset
        blurView.dimmingTintColor = dimmingTintColor
        blurView.dimmingAlpha = dimmingAlpha
        blurView.dimmingOvershoot = dimmingOvershoot
        blurView.dimmingStartingInset = dimmingStartingInset

        return blurView
    }

    func updateUIView(_ uiView: VariableBlurView, context: Context) {}
}

#Preview {
    ZStack {
        Text(
            "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
        )

        BlurUIKitView()
            .frame(width: 100, height: 100)
    }
}
