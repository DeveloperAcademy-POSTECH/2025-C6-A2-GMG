//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftUI

struct SegmentsScrollView: View {
    let totalDuration: TimeInterval
    let segmentSlices: [[ChordSegmentSlice]]
    let currentChordCell: ChordCell?
    let selectedChordCell: ChordCell?
    let segmentHandlers: SegmentHandlers
    let waveformHandlers: WaveformHandlers
    let audioLevels: [Float]
    let elapsedTime: TimeInterval
    let isPlaying: Bool

    @State private var isUserScrolling = false
    @State private var isWaveformDragging = false

    private var resolvedWaveformHandlers: WaveformHandlers {
        WaveformHandlers(
            onTap: waveformHandlers.onTap,
            onDragStart: { time in
                isWaveformDragging = true
                waveformHandlers.onDragStart(time)
            },
            onDragChange: waveformHandlers.onDragChange,
            onDragEnd: { time in
                waveformHandlers.onDragEnd(time)
                isWaveformDragging = false
            }
        )
    }

    private var shouldAutoScroll: Bool {
        isPlaying && isUserScrolling == false && isWaveformDragging == false
    }

    private var currentSegmentIndex: Int? {
        guard segmentSlices.isEmpty == false else { return nil }
        let rawIndex = Int(elapsedTime / Constants.segmentDuration)
        let clampedIndex = min(
            max(0, rawIndex),
            segmentSlices.count - 1
        )
        return clampedIndex
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(Array(segmentSlices.enumerated()), id: \.offset) { index, slices in
                        Segment(
                            index: index,
                            totalDuration: totalDuration,
                            chordSlices: slices,
                            segmentDuration: Constants.segmentDuration,
                            currentChordCell: currentChordCell,
                            selectedChordCell: selectedChordCell,
                            audioLevels: audioLevels,
                            elapsedTime: elapsedTime,
                            segmentHandlers: segmentHandlers,
                            waveformHandlers: resolvedWaveformHandlers
                        )
                        .id(index)
                    }
                }
                .safeAreaPadding(Spacing.md)
                .safeAreaPadding(.bottom, 128)
            }
            .onScrollPhaseChange { _, newPhase in
                isUserScrolling = newPhase == .interacting
            }
            .onChange(of: isPlaying) { _, isPlaying in
                guard shouldAutoScroll else { return }
                guard let index = currentSegmentIndex else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
            .onChange(of: currentSegmentIndex) { _, newIndex in
                guard shouldAutoScroll else { return }
                guard let newIndex else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .mask {
                VStack(spacing: .zero) {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: .clear, location: 0.0),
                            Gradient.Stop(color: .white, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: Spacing.md)
                    Color.white
                }
                .ignoresSafeArea()
            }
        }
    }
}
