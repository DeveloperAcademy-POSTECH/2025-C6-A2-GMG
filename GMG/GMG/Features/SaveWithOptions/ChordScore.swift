//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ChordScore: View {
    let title: String
    let timeSignature: String
    let bpm: Int
    let key: String
    let measures: [[Chord?]]

    typealias Chord = String

    var body: some View {
        ZStack {
            Color.backgroundLight1
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.NeoDonggeunmoPro.R8)
                        .foregroundStyle(.text1)
                    HStack(spacing: Spacing.xl) {
                        Text(timeSignature)
                        HStack(spacing: Spacing.xxxs) {
                            Text("\(bpm)")
                            Text("BPM")
                        }
                        HStack(spacing: Spacing.xxxs) {
                            Text("\(key)")
                            Text("Key")
                        }
                    }
                    .font(Typography.DOSGothic.M5)
                    .foregroundStyle(.text1)
                }

                VStack(spacing: Spacing.md) {
                    ForEach(Array(measures.enumerated()), id: \.offset) {
                        index,
                        measure in
                        VStack(alignment: .leading, spacing: .zero) {
                            Text("\(index + 1)")
                                .font(Typography.DOSGothic.M2)
                                .foregroundStyle(.text1)
                                .padding(.leading, Spacing.md)
                            Measure(measure: measure)
                        }
                    }
                }
            }
        }
    }

    struct Measure: View {
        let measure: [Chord?]

        var body: some View {
            HStack(spacing: .zero) {
                ForEach(Array(measure.enumerated()), id: \.offset) { index, chord in
                    HStack {
                        Text(chord ?? "")
                            .lineHeight(.normal)
                            .font(Typography.DOSGothic.M10)
                            .foregroundStyle(.text1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 64)
                    if index != measure.count - 1 {
                        Rectangle()
                            .fill(.black.opacity(0.1))
                            .frame(width: 1, height: 62)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray2)
                    .strokeBorder(.black.opacity(0.1))
            }
        }
    }

    var uiImage: UIImage? {
        let ratio: CGFloat = 393 / 852

        let height: CGFloat = 852
        let width: CGFloat = ratio * height

        let renderer = ImageRenderer(
            content:
                self
                .frame(width: width, height: height)
        )

        renderer.scale = 3.0

        return renderer.uiImage
    }
}

#Preview {
    ChordScore(
        title: "나의 웃음에게",
        timeSignature: "4/4",
        bpm: 80,
        key: "E",
        measures: [
            ["Am7", "G", "E", "F#m"],
            ["C", "E", "Bm", "F#m"],
            ["B", nil, "E", nil],
            ["C", nil, nil, "D"],
            [nil, "G", nil, "Am"],
        ]
    )
}
