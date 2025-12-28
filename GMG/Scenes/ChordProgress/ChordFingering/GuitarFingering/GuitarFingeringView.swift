//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct GuitarFingeringView: View {
    let chord: Chord

    @State private var fretboardSize: CGSize = .zero

    private var chordDiagram: GuitarChordDiagram {
        .init(chord: chord) ?? .empty
    }

    var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: Spacing.xxs) {
                GuitarStringIndicatorView(strings: chordDiagram.strings)

                HStack(spacing: -Spacing.xxxs) {
                    NutView(startFret: chordDiagram.startFret)
                        .padding(.vertical, fretboardSize.height / 32)
                        .zIndex(1)

                    FretboardView(
                        chordDiagram: chordDiagram
                    )
                    .onGeometryChange(
                        for: CGSize.self,
                    ) { geometry in
                        geometry.size
                    } action: { size in
                        self.fretboardSize = size
                    }
                }
            }

            HStack(spacing: .zero) {
                Spacer()

                FretIndicatorView(
                    startFret: chordDiagram.startFret
                )
                .frame(width: fretboardSize.width)
            }
        }
    }
}

extension GuitarFingeringView {
    private struct GuitarStringIndicatorView: View {
        private static let indicatorSize: CGSize = .init(width: 12, height: 8)

        let strings: [GuitarString: GuitarStringState]

        var body: some View {
            VStack(spacing: .zero) {
                ForEach(GuitarString.allCases.reversed(), id: \.self) { string in
                    Text(symbol(for: strings[string]))
                        .font(Typography.WantedSansStd.R4.font)
                        .foregroundStyle(ProgressPalette.Fingering.GuitarStringIndicator.text)
                        .frame(
                            width: Self.indicatorSize.width,
                            height: Self.indicatorSize.height
                        )
                        .frame(maxHeight: .infinity)
                }
            }
        }

        private func symbol(for state: GuitarStringState?) -> String {
            return switch state {
            case .mute: "X"
            case .open: "O"
            default: ""
            }
        }
    }

    private struct NutView: View {
        private static let nutWidth: CGFloat = 8

        let startFret: Int

        var body: some View {
            RoundedRectangle(cornerRadius: 2)
                .fill(ProgressPalette.Fingering.Nut.fill)
                .opacity(startFret <= 1 ? 1.0 : 0.0)
                .frame(width: Self.nutWidth)
        }
    }

    private struct FretboardView: View {
        let chordDiagram: GuitarChordDiagram

        @State private var height: CGFloat = .zero

        private var padding: CGFloat {
            height / CGFloat(GuitarString.allCases.count) / 2
        }

        var body: some View {
            GuitarStringView(strings: chordDiagram.strings)
                .background {
                    FretDividerView()
                        .padding(.vertical, padding)
                }
                .overlay {
                    FrettedFingeringView(
                        startFret: chordDiagram.startFret,
                        strings: chordDiagram.strings
                    )
                    BarreFingeringView(
                        startFret: chordDiagram.startFret,
                        barres: chordDiagram.barres
                    )
                }
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.height
                } action: { height in
                    self.height = height
                }
        }
    }

    private struct GuitarStringView: View {
        let strings: [GuitarString: GuitarStringState]

        var body: some View {
            VStack(spacing: .zero) {
                ForEach(GuitarString.allCases.reversed(), id: \.self) { string in
                    Capsule()
                        .fill(guitarStringColor(for: strings[string]))
                        .frame(height: 2)
                        .frame(maxHeight: .infinity)
                }
            }
        }

        private func guitarStringColor(for state: GuitarStringState?) -> Color {
            return switch state {
            case .mute: ProgressPalette.Fingering.String.mute
            default: ProgressPalette.Fingering.String.normal
            }
        }
    }

    private struct FretDividerView: View {
        private static let dividerWidth: CGFloat = 2

        var body: some View {
            HStack(spacing: .zero) {
                Spacer()

                ForEach(0..<3) { _ in
                    Rectangle()
                        .fill(ProgressPalette.Fingering.FretDivider.line)
                        .frame(width: Self.dividerWidth)

                    Spacer()
                }
            }
        }
    }

    private struct FrettedFingeringView: View {
        private static let dotSize: CGSize = .init(width: 10, height: 10)

        let startFret: Int
        let strings: [GuitarString: GuitarStringState]

        var body: some View {
            Grid(horizontalSpacing: .zero, verticalSpacing: .zero) {
                ForEach(GuitarString.allCases.reversed(), id: \.self) { string in
                    GridRow {
                        ForEach(0..<4) { fret in
                            let currentFret: Int = max(startFret, 1) + fret

                            Circle()
                                .fill(ProgressPalette.Fingering.Dot.fill)
                                .frame(
                                    width: Self.dotSize.width,
                                    height: Self.dotSize.height
                                )
                                .opacity(
                                    fretToPress(for: string) == currentFret ? 1.0 : 0.0
                                )
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }

        private func fretToPress(for string: GuitarString) -> Int? {
            guard case .fretted(let fret, _) = strings[string] else { return nil }
            return fret
        }
    }

    private struct BarreFingeringView: View {
        private static let barreWidth: CGFloat = 10
        private static let guitarStringCount: Int = GuitarString.allCases.count

        let startFret: Int
        let barres: [Barre]

        var body: some View {
            GeometryReader { geometry in
                let height: CGFloat = geometry.size.height
                let stringHeight: CGFloat = height / CGFloat(Self.guitarStringCount)

                HStack(spacing: .zero) {
                    ForEach(0..<4) { fret in
                        let currentFret: Int = max(startFret, 1) + fret
                        let barre: Barre? = barres.first(where: { $0.fret == currentFret })

                        VStack(spacing: .zero) {
                            if let barre {
                                Color.clear
                                    .frame(
                                        height: stringHeight * CGFloat(barre.to.rawValue - 1)
                                    )

                                Capsule()
                                    .fill(ProgressPalette.Fingering.Barre.fill)
                                    .frame(width: Self.barreWidth)

                                Color.clear
                                    .frame(
                                        height: stringHeight
                                            * CGFloat(Self.guitarStringCount - barre.from.rawValue)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private struct FretIndicatorView: View {
        let startFret: Int

        var body: some View {
            HStack(spacing: .zero) {
                ForEach(0..<4) { fret in
                    let currentFret: Int = max(startFret, 1) + fret

                    Text("\(currentFret)")
                        .font(Typography.WantedSansStd.R4.font)
                        .foregroundStyle(ProgressPalette.Fingering.FretIndicator.text)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var chord: Chord = .init(root: .C, quality: .maj)

    VStack {
        GuitarFingeringView(chord: chord)
            .frame(width: 144)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .frame(height: 128)
            .frame(maxWidth: .infinity)
            .background(
                ProgressPalette.Fingering.Preview.background,
                in: RoundedRectangle(cornerRadius: 12)
            )

        HStack {
            Picker(
                "Root",
                selection: Binding(
                    get: { chord.root },
                    set: { chord = .init(root: $0, quality: chord.quality) }
                )
            ) {
                ForEach(NoteName.allCases, id: \.self) { note in
                    Text(note.description)
                }
            }
            .pickerStyle(.wheel)
            Picker(
                "Quality",
                selection: Binding(
                    get: { chord.quality },
                    set: { chord = .init(root: chord.root, quality: $0) }
                )
            ) {
                ForEach(ChordQuality.allCases, id: \.self) { quality in
                    Text(quality.description)
                }
            }
            .pickerStyle(.wheel)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    .padding()
}
