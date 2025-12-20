//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ChordFingeringView: View {
    private static let height: CGFloat = 128

    let instrument: Instrument
    let chord: Chord

    private var backgroundColor: Color {
        return switch instrument {
        case .piano: Color.black8
        case .guitar: Color.white1
        }
    }

    var body: some View {
        ZStack {
            switch instrument {
            case .piano:
                PianoFingeringView(chord: chord)
            case .guitar:
                GuitarFingeringView(chord: chord)
                    .frame(width: 144)
            }
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .frame(height: Self.height)
        .frame(maxWidth: .infinity)
        .background(
            backgroundColor,
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

#Preview {
    @Previewable @State var chord: Chord = .init(root: .C, quality: .maj)
    @Previewable @State var instrument: Instrument = .piano

    VStack {
        ChordFingeringView(instrument: instrument, chord: chord)

        Button {
            instrument =
                switch instrument {
                case .piano: .guitar
                case .guitar: .piano
                }
        } label: {
            switch instrument {
            case .piano:
                Text("피아노")
            case .guitar:
                Text("기타")
            }
        }

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
