//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ChordSheetView: View {
    let title: String
    let key: Key
    let segmentStartTime: TimeInterval
    let segmentDuration: TimeInterval
    let segments: [[ChordInSegment]]

    /// ImageRenderer를 사용할 때는 반드시 `@MainActor`에서 실행되어야 합니다.
    /// 그렇지 않을 경우 런타임 크래시가 발생합니다.
    @MainActor
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

    var body: some View {
        ZStack {
            Color.white1
                .ignoresSafeArea()

            VStack(spacing: 30) {
                ScoreInformationView(title: title, key: key)

                VStack(spacing: 20) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        let startTime: TimeInterval =
                            segmentStartTime + segmentDuration * TimeInterval(index)
                        let endTime: TimeInterval = startTime + segmentDuration

                        SegmentView(
                            startTime: startTime,
                            endTime: endTime,
                            chordInSegments: segment
                        )
                    }
                }
                .frame(minHeight: 500)

                LogoView()
                    .padding(.top, 30)
            }
            .padding(Spacing.md)
        }
    }
}

extension ChordSheetView {
    struct ScoreInformationView: View {
        let title: String
        let key: Key

        var body: some View {
            VStack(spacing: Spacing.md) {
                Text(title)
                    .font(.custom(Typography.WantedSansStd.Bold, size: 40))
                Text("\(key.description) Key")
                    .font(Typography.WantedSansStd.R7)
            }
            .foregroundStyle(Color.black1)
        }
    }

    struct SegmentView: View {
        let startTime: TimeInterval
        let endTime: TimeInterval
        let chordInSegments: [ChordInSegment]

        private var dotCount: Int {
            max(0, Int(2 * (endTime - startTime) - 1))
        }

        var body: some View {
            VStack(spacing: Spacing.xs) {
                Grid {
                    GridRow {
                        ForEach(Array(chordInSegments.enumerated()), id: \.offset) {
                            index, chordInSegment in
                            Group {
                                if let chord: Chord = chordInSegment.chord {
                                    ChordInSegmentView(chord: chord)
                                } else {
                                    Color.clear
                                }
                            }
                            .frame(height: 62)
                            .gridCellColumns(
                                max(1, Int((chordInSegment.proportion * 100).rounded(.down))))
                        }
                    }
                }

                TimeRulerView(startTime: startTime, endTime: endTime, dotCount: dotCount)
            }
        }
    }

    struct ChordInSegmentView: View {
        let chord: Chord

        var body: some View {
            ViewThatFits(in: .horizontal) {
                Text(chord.description)
                VStack(alignment: .center) {
                    Text(chord.root.description + "\n" + chord.quality.description)
                        .multilineTextAlignment(.center)
                }
                .minimumScaleFactor(0.1)
            }
            .padding(Spacing.xxs)
            .font(Typography.WantedSansStd.R7)
            .foregroundStyle(Color.black1)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black9)
            }
        }
    }

    struct TimeRulerView: View {
        let startTime: TimeInterval
        let endTime: TimeInterval
        let dotCount: Int

        var body: some View {
            HStack {
                Text("\(startTime, specifier: "%.0f")s")
                    .font(Typography.WantedSansStd.R2)
                    .fixedSize()
                ForEach(0..<dotCount, id: \.self) { _ in
                    Circle()
                        .frame(width: 2, height: 2)
                        .frame(maxWidth: .infinity)
                }
                Text("\(endTime, specifier: "%.0f")s")
                    .font(Typography.WantedSansStd.R2)
                    .fixedSize()
            }
            .foregroundStyle(Color.black7)
            .padding(.horizontal, Spacing.xs)
        }
    }

    struct LogoView: View {
        var body: some View {
            Image(.sheetLogo)
        }
    }
}

#Preview {
    let score: Score = Score.mock
    let segments: [[ChordInSegment]] = ChordInSegment.convert(score: score)

    ChordSheetView(
        title: score.title,
        key: score.key,
        segmentStartTime: 0,
        segmentDuration: 5,
        segments: Array(segments[0..<min(segments.count, 5)])
    )
}
