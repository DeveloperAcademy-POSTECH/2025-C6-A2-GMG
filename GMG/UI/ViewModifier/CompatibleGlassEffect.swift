//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct CompatibleGlassEffect<S: InsettableShape>: ViewModifier {
    let shape: S

    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
        } else {
            let (startPoint, endPoint) = calculatePoints(size)

            content
                .background {
                    BackdropView()
                        .padding(-4)
                        .brightness(0.1)
                        .blur(radius: 2)
                        .clipShape(shape)
                    shape
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: Color.white.opacity(0.2), location: 0.1),
                                    Gradient.Stop(color: Color.clear, location: 0.5),
                                    Gradient.Stop(color: Color.white.opacity(0.2), location: 0.9),
                                ],
                                startPoint: startPoint,
                                endPoint: endPoint
                            )
                        )
                }
                .onGeometryChange(for: CGSize.self) { geometry in
                    geometry.size
                } action: { size in
                    self.size = size
                }
        }
    }

    private func calculatePoints(_ size: CGSize) -> (startPoint: UnitPoint, endPoint: UnitPoint) {
        guard size.width > 0 && size.height > 0 else {
            return (.topLeading, .bottomTrailing)
        }

        let w = size.width
        let h = size.height

        let length = sqrt(w * w + h * h)
        let ux = (-h) / (w * length)
        let uy = (w) / (h * length)

        let maxScaleX = ux == 0 ? CGFloat.infinity : 0.5 / abs(ux)
        let maxScaleY = uy == 0 ? CGFloat.infinity : 0.5 / abs(uy)
        let scale = min(maxScaleX, maxScaleY)

        let cx: CGFloat = 0.5
        let cy: CGFloat = 0.5

        func clamp(_ v: CGFloat) -> CGFloat { min(max(v, 0), 1) }

        let s = UnitPoint(x: clamp(cx + ux * scale), y: clamp(cy - uy * scale))
        let e = UnitPoint(x: clamp(cx - ux * scale), y: clamp(cy + uy * scale))

        return (s, e)
    }
}

extension CompatibleGlassEffect {
    private class UIBackdropView: UIView {
        override class var layerClass: AnyClass {
            NSClassFromString("CABackdropLayer") ?? CALayer.self
        }
    }

    private struct BackdropView: UIViewRepresentable {
        func makeUIView(context: Context) -> UIBackdropView {
            UIBackdropView()
        }

        func updateUIView(_ uiView: UIBackdropView, context: Context) {}
    }
}

#Preview {
    @Previewable @State var previousOffset: CGSize = .zero
    @Previewable @State var offset: CGSize = .zero

    ZStack {
        Text(
            "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
        )

        Text("CompatibleGlassEffect")
            .padding()
            .modifier(CompatibleGlassEffect(shape: RoundedRectangle(cornerRadius: 16)))
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        let translation: CGSize = value.translation
                        let newOffset: CGSize = CGSize(
                            width: previousOffset.width + translation.width,
                            height: previousOffset.height + translation.height)
                        offset = newOffset
                    })
                    .onEnded({ value in
                        previousOffset = offset
                    })
            )
    }
    .preferredColorScheme(.dark)
}
