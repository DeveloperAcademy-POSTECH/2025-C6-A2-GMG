//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct PianoFingeringView: View {
    private static let midiNumberC2: Int8 = 48
    private static let midiNumberB3: Int8 = 71

    private static let range: ClosedRange<Int8> = midiNumberC2...midiNumberB3

    let chord: Chord

    var body: some View {
        let midiNoteNumbers: [Int8] = chord.tonicChord.midiNoteNumbers(octave: 2)
        let notes: [PianoNote] = Self.range.map(PianoNote.init)

        let whiteNotes: [PianoNote] = notes.filter { !$0.isBlackKey }
        let blackNotes: [PianoNote] = notes.filter { $0.isBlackKey }

        GeometryReader { geometry in
            let width: CGFloat = geometry.size.width
            let height: CGFloat = geometry.size.height
            let spacing: CGFloat = Spacing.xxxs

            let whiteKeyCount: CGFloat = CGFloat(whiteNotes.count)
            let whiteKeyWidth: CGFloat = (width - (whiteKeyCount - 1) * spacing) / whiteKeyCount
            let blackKeyWidth: CGFloat = whiteKeyWidth * 0.75

            ZStack(alignment: .topLeading) {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(whiteNotes, id: \.self) { note in
                        WhiteKeyView(
                            isActive: midiNoteNumbers.contains(note.midiNumber)
                        )
                        .frame(width: whiteKeyWidth, height: height)
                    }
                }
                ForEach(blackNotes, id: \.self) { note in
                    if let precedingWhiteIndex =
                        whiteNotes.firstIndex(where: { $0.midiNumber == note.midiNumber - 1 })
                    {
                        let offsetX =
                            (CGFloat(precedingWhiteIndex + 1) * whiteKeyWidth)
                            + (CGFloat(precedingWhiteIndex) * spacing)
                            + (spacing / 2)
                            - (blackKeyWidth / 2)

                        BlackKeyView(
                            isActive: midiNoteNumbers.contains(note.midiNumber)
                        )
                        .frame(width: blackKeyWidth, height: height * 0.6)
                        .offset(x: offsetX)
                    }
                }
            }
        }
    }

    private struct PianoNote: Hashable {
        let midiNumber: Int8

        var isBlackKey: Bool {
            let key: Int8 = midiNumber % 12
            return [1, 3, 6, 8, 10].contains(key)
        }

        var needsPrecedingSpacer: Bool {
            let key: Int8 = midiNumber % 12
            return key == 0 || key == 5
        }
    }
}

extension PianoFingeringView {
    private struct BlackKeyView: View {
        let isActive: Bool

        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(
                    isActive
                        ? ProgressPalette.Fingering.PianoKey.blackActive
                        : ProgressPalette.Fingering.PianoKey.blackInactive
                )
        }
    }

    private struct WhiteKeyView: View {
        let isActive: Bool

        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(
                    isActive
                        ? ProgressPalette.Fingering.PianoKey.whiteActive
                        : ProgressPalette.Fingering.PianoKey.whiteInactive
                )
        }
    }
}

#Preview {
    @Previewable @State var chord: Chord = .init(root: .C, quality: .maj)

    VStack {
        PianoFingeringView(
            chord: chord
        )
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(height: 128)
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
