//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ChordFingeringView: View {
    private static let height: CGFloat = 128

    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    let instrument: Instrument
    let chord: Chord

    @State private var isPresented: Bool = false

    private var backgroundShape: RoundedRectangle {
        .init(cornerRadius: isPresented ? 12 : 32)
    }

    private var backgroundColor: Color {
        switch instrument {
        case .piano:
            // ProgressPalette.Fingering.ChordBackground.piano = Color.black8.opacity(0.2)
            return Color.black8.opacity(0.2)
        case .guitar:
            // ProgressPalette.Fingering.ChordBackground.guitar = Color.white1.opacity(0.7)
            return palette.sheetBackground.opacity(0.7)
        }
    }

    private var symbolColor: Color {
        switch colorScheme {
        case .light:
            // ProgressPalette.Fingering.Symbol.light = Color.black1
            return palette.primaryText
        case .dark:
            // ProgressPalette.Fingering.Symbol.dark = Color.white1
            return palette.overlayPrimaryText
        @unknown default:
            return palette.primaryText
        }
    }

    var body: some View {
        ZStack {
            if isPresented {
                ZStack {
                    Group {
                        switch instrument {
                        case .piano:
                            PianoFingeringView(chord: chord)
                        case .guitar:
                            GuitarFingeringView(chord: chord)
                                .frame(width: 144)
                        }
                    }
                    .transition(.blurReplace)
                }
                .frame(maxWidth: .infinity)
                .transition(
                    .scale(.zero, anchor: .bottomTrailing)
                        .combined(with: .blurReplace)
                )
            }
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .frame(height: Self.height)
        .frame(maxWidth: .infinity)
        .background(alignment: .bottomTrailing) {
            backgroundShape
                .fill(
                    backgroundColor
                        .opacity(isPresented ? 1.0 : 0.0)
                )
                .frame(
                    width: isPresented ? nil : 44,
                    height: isPresented ? nil : 44
                )
                .compatibleGlassEffect(in: backgroundShape)
                .overlay {
                    if isPresented == false {
                        Image(systemName: "hand.raised.fingers.spread.fill")
                            .foregroundStyle(symbolColor)
                            .transition(
                                .scale(2.0, anchor: .bottomTrailing)
                                    .combined(with: .blurReplace)
                            )
                    }
                }
                .contentShape(backgroundShape)
                .padding(isPresented ? 0.0 : Spacing.xs)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
        .animation(.default, value: instrument)
        .onTapGesture {
            isPresented.toggle()
        }
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
