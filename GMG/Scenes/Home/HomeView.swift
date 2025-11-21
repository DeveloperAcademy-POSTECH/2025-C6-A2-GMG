//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import BlurUIKit
import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var model: HomeModelStateProtocol
    @State private var intent: HomeIntentProtocol
    private weak var router: Router?

    init(
        model: HomeModelStateProtocol,
        intent: HomeIntentProtocol,
        router: Router? = nil
    ) {
        self.model = model
        self.intent = intent
        self.router = router
    }

    var body: some View {
        ZStack {
            Color.bg1.ignoresSafeArea()
            VStack {
                ScrollView {
                    LazyVStack(spacing: Spacing.xl) {
                        RecentFileSection(model: model, intent: intent, router: router)
                        AllFilesSection(model: model, intent: intent, router: router)
                    }
                    .safeAreaPadding(Spacing.md)
                }
                .scrollIndicators(.hidden)
                .task {
                    intent.onAppear()
                    if let lastScore = model.sortedScores.last {
                        intent.selectScore(lastScore)
                    }
                }
            }
        }
        .onDisappear {
            intent.onDisappear()
        }
        .safeAreaInset(edge: .top) {
            HeaderSection(count: model.songCount)
                .padding(Spacing.md)
                .padding(.top, Spacing.xs)
                .background {
                    BlurUIKitView(
                        maximumBlurRadius: 4,
                        dimmingTintColor: UIColor.bg1,
                        dimmingAlpha: .constant(alpha: 1)
                    )
                    .ignoresSafeArea()
                }
        }
        .alert(
            .deleteScoreAlertTitle(title: model.scoreToDelete?.title ?? ""),
            isPresented: .constant(model.scoreToDelete != nil)
        ) {
            Button(.delete, role: .destructive) {
                if let scoreToDelete = model.scoreToDelete {
                    intent.deleteScore(scoreToDelete)
                }
                intent.requestDeleteScoreConfirmation(nil)
            }
            Button(.cancel, role: .cancel) {
                intent.requestDeleteScoreConfirmation(nil)
            }
        } message: {
            Text(.deleteScoreAlertDescription)
        }
        .alert(
            .deleteScoreAlertTitle(title: model.scoreToDelete?.title ?? ""),
            isPresented: .constant(model.scoreToDelete != nil)
        ) {
            Button(.delete, role: .destructive) {
                if let scoreToDelete = model.scoreToDelete {
                    intent.deleteScore(scoreToDelete)
                }
                intent.requestDeleteScoreConfirmation(nil)
            }
            Button(.cancel, role: .cancel) {
                intent.requestDeleteScoreConfirmation(nil)
            }
        } message: {
            Text(.deleteScoreAlertDescription)
        }
    }
}

extension HomeView {

    //MARK: - ScoreCard
    struct ScoreCard: View {
        @State private var isEditable: Bool = false
        @FocusState private var isTitleFocused: Bool
        @State private var tempTitle: String = ""

        let score: Score
        let index: Int
        let isSmall: Bool
        let isLatest: Bool
        let isSelected: Bool
        let isPlaying: Bool
        let progress: Double
        let tapAction: () -> Void
        let playButtonAction: () -> Void
        let stopButtonAction: () -> Void
        let renameScoreAction: (String) -> Void
        let exportScoreAction: (Score) -> Void
        let deleteScoreAction: (Score) -> Void
        let latestPalette: [Color]
        let earliestPalette: [Color]

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: .zero) {
                    TextField(
                        String(localized: .enterTitle),
                        text: isEditable ? $tempTitle : .constant(score.title)
                    )
                    .font(isSmall ? Typography.WantedSansStd.R4 : Typography.WantedSansStd.R5)
                    .foregroundStyle(Color.white1)
                    .autocorrectionDisabled()
                    .focused($isTitleFocused)
                    .onSubmit { endRename(commit: true) }
                    .submitLabel(.done)
                    .disabled(isEditable == false)
                    .onChange(of: tempTitle) {
                        if tempTitle.count > 15 {
                            tempTitle = String(tempTitle.prefix(15))
                        }
                    }

                    Text(Self.dateConverter(score.createdAt))
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(Color.white2)

                    Spacer()

                    Text("\(score.key.description) Key")
                        .font(Typography.WantedSansStd.R4)
                        .foregroundStyle(Color.white2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: .zero) {

                    Menu {
                        Button(.rename, systemImage: "pencil") {
                            startRename()
                        }

                        Button(.export, systemImage: "square.and.arrow.up") {
                            exportScoreAction(score)
                        }

                        Button(.delete, systemImage: "trash", role: .destructive) {
                            deleteScoreAction(score)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Color.white1)
                            .frame(width: 30, height: 30, alignment: .top)
                            .contentShape(Rectangle())
                    }
                    .menuIndicator(.hidden)

                    Text(Self.formatDuration(score.totalDuration))
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(Color.white1)
                        .padding(.bottom, 9.5)
                        .padding(.trailing, 1)
                        .padding(.top, -6)

                    Button {
                        if isPlaying {
                            stopButtonAction()
                        } else {
                            playButtonAction()
                        }
                    } label: {
                        Image(isPlaying ? .pause : .playButton)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: isPlaying ? 13 : 10,
                                height: isPlaying ? 13 : 10
                            )
                            .foregroundStyle(Color.black1)
                            .padding(.all, isPlaying ? 7.5 : 9)
                            .padding(.leading, isPlaying ? 0 : 2)
                            .background {
                                let lineWidth: CGFloat = 3
                                let isProgressPresented: Bool =
                                    isSelected && (isPlaying || progress > 0)
                                Circle()
                                    .inset(by: lineWidth / 2 + 0.2)
                                    .fill(Color.white2)
                                    .stroke(
                                        isProgressPresented ? Color.bg1 : Color.white2,
                                        lineWidth: lineWidth
                                    )
                                    .drawingGroup()
                                Circle()
                                    .inset(by: lineWidth / 2)
                                    .trim(from: 0, to: progress)
                                    .stroke(
                                        Color.bg2,
                                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .opacity(isProgressPresented ? 1 : 0)
                            }
                    }
                    .buttonStyle(.bouncy)
                    .opacity(isSelected ? 1 : 0)
                }
            }
            .padding(Spacing.lg)
            .frame(
                minWidth: isSmall ? 156 : nil,
                maxWidth: isSmall ? 156 : .infinity,
                minHeight: 128,
                maxHeight: 128
            )
            .background(
                backgroundColor,
                in: RoundedRectangle(cornerRadius: 32)
            )
            .contentShape(RoundedRectangle(cornerRadius: 32))
            .onTapGesture {
                if isEditable {
                    endRename(commit: true)
                } else {
                    tapAction()
                }
            }
        }

        // MARK: - Rename Helpers
        private func startRename() {
            tempTitle = score.title
            isEditable = true
            Task { @MainActor in
                isTitleFocused = true
            }
        }

        private func endRename(commit: Bool) {
            if commit {
                let newTitle = tempTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                // 빈 문자열로 저장되는 것 방지 + 변경 시에만 저장
                if !newTitle.isEmpty, newTitle != score.title {
                    renameScoreAction(newTitle)
                }
            }
            isTitleFocused = false
            isEditable = false
        }

        // MARK: - Color Helpers
        private var backgroundColor: Color {
            if isSmall {
                return latestPalette[index % latestPalette.count]
            } else {
                return isLatest
                    ? latestPalette[index % latestPalette.count]
                    : earliestPalette[index % earliestPalette.count]
            }
        }

        // MARK: - data Helpers
        private static func dateConverter(_ date: Date) -> String {
            let formatted = DateFormatter()
            formatted.dateFormat = "yy. MM. dd"
            return formatted.string(from: date)
        }

        private static func formatDuration(_ seconds: Double) -> String {
            let totalSeconds = Int(seconds.rounded())
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    //MARK: - HeaderSection
    struct HeaderSection: View {
        var count: Int

        var body: some View {
            HStack {
                Logo()
                Spacer()
                SongCount(count: count)
                    .padding(.top, 60)
            }
        }
    }

    struct Logo: View {
        private var reString: AttributedString {
            var string: AttributedString = AttributedString("Re:")
            string.foregroundColor = Color.black3
            return string
        }

        private var chordString: AttributedString {
            var string: AttributedString = AttributedString("chord")
            string.foregroundColor = Color.black1
            return string
        }

        var body: some View {
            Text("\(reString)\n\(chordString)")
                .font(Typography.WantedSansStd.B16)
        }
    }

    struct SongCount: View {
        let count: Int

        private var countString: AttributedString {
            var string: AttributedString = AttributedString("\(count)")
            string.font = Typography.WantedSansStd.R10.font
            return string
        }

        private var unitString: AttributedString {
            var string: AttributedString = AttributedString("songs")
            string.font = Typography.WantedSansStd.R7.font
            return string
        }

        var body: some View {
            Text("\(countString) \(unitString)")
                .foregroundStyle(Color.black1)
        }
    }

    //MARK: - recentFileSection
    struct RecentFileSection: View {
        let model: HomeModelStateProtocol
        let intent: HomeIntentProtocol
        let router: Router?

        var body: some View {
            VStack(spacing: Spacing.md) {
                HStack {
                    Text(.recentFiles)
                        .font(
                            .english(Typography.WantedSansStd.R7),
                            .korean(Typography.Pretendard.SB7)
                        )
                        .foregroundStyle(Color.black1)
                    Spacer()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Spacing.md) {
                        AddScoreButton(
                            action: {
                                router?.push(.recording)
                            },
                            isExpanded: model.isScoresEmpty
                        )

                        ForEach(
                            Array(model.recentScores.prefix(3).enumerated()),
                            id: \.element.id
                        ) { (index, score) in
                            let isSelected = model.selectedScore == score
                            let isPlayingForThisScore = isSelected && model.playhead.isPlaying
                            let progressForThisScore =
                                (isSelected && score.totalDuration > 0)
                                ? model.playhead.elapsedTime / score.totalDuration
                                : 0
                            ScoreCard(
                                score: score,
                                index: index,
                                isSmall: true,
                                isLatest: model.isLatest,
                                isSelected: true,
                                isPlaying: isPlayingForThisScore,
                                progress: progressForThisScore,
                                tapAction: {
                                    intent.onTapScore(score)
                                    router?.push(
                                        .chordProgress(score: score)
                                    )
                                },
                                playButtonAction: {
                                    intent.onTapPlayButton(
                                        score: score,
                                        selectedScore: model.selectedScore
                                    )
                                },
                                stopButtonAction: {
                                    intent.onTapStopButton()
                                },
                                renameScoreAction: { newTitle in
                                    intent.renameScore(score, newTitle: newTitle)
                                },
                                exportScoreAction: { score in
                                    router?.push(.export(score: score))
                                },
                                deleteScoreAction: { score in
                                    intent.requestDeleteScoreConfirmation(score)
                                },
                                latestPalette: latestPalette,
                                earliestPalette: earliestPalette)
                        }
                    }
                }
                .frame(minHeight: 128)
            }
        }
    }

    struct AddScoreButton: View {
        let action: () -> Void
        let isExpanded: Bool

        var body: some View {
            Button {
                action()
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.black1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        Color.white,
                        in: RoundedRectangle(cornerRadius: 32)
                    )
            }
            .frame(width: isExpanded ? 156 : 124)
        }
    }

    //MARK: - AllFilesSection
    struct AllFilesSection: View {
        let model: HomeModelStateProtocol
        let intent: HomeIntentProtocol
        let router: Router?

        var body: some View {
            VStack(spacing: Spacing.md) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text(.allFiles)
                        .font(
                            .english(Typography.WantedSansStd.R7),
                            .korean(Typography.Pretendard.SB7)
                        )
                        .foregroundStyle(Color.black1)
                        .padding(.trailing, 20)

                    Text(.latest)
                        .font(
                            .english(Typography.WantedSansStd.R5),
                            .korean(Typography.Pretendard.M5)
                        )
                        .foregroundStyle(
                            model.isLatest ? Color.black5 : Color.black3
                        )
                        .padding(.trailing, 12)
                        .onTapGesture {
                            if model.isLatest == false {
                                intent.setIsLatest(true)
                                if let last = model.sortedScores.last {
                                    intent.selectScore(last)
                                }
                            }
                        }

                    Text(.earliest)
                        .font(
                            .english(Typography.WantedSansStd.R5),
                            .korean(Typography.Pretendard.M5)
                        )
                        .foregroundStyle(
                            model.isLatest ? Color.black3 : Color.black5
                        )
                        .padding(.trailing, 12)
                        .onTapGesture {
                            if model.isLatest == true {
                                intent.setIsLatest(false)
                                if let last = model.sortedScores.last {
                                    intent.selectScore(last)
                                }
                            }
                        }

                    Spacer()
                }

                if model.songCount == 0 {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("An experience")
                            .foregroundStyle(Color.white3.opacity(0.55))
                        Text("where humming")
                            .foregroundStyle(Color.black8.opacity(0.3))
                        Text("becomes the")
                            .foregroundStyle(Color.black4.opacity(0.3))
                        Text("start of a song")
                            .foregroundStyle(Color.black4.opacity(0.35))
                    }
                    .font(
                        .custom(
                            Typography.WantedSansStd.Bold,
                            size: 42
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)
                } else {
                    VStack(spacing: -60) {
                        ForEach(
                            Array(model.sortedScores.enumerated()),
                            id: \.element.id
                        ) { (index, score) in
                            let isSelected: Bool =
                                model.selectedScore?.id == score.id
                            let isPlayingForThisScore = isSelected && model.playhead.isPlaying
                            let progressForThisScore =
                                (isSelected && score.totalDuration > 0)
                                ? model.playhead.elapsedTime / score.totalDuration
                                : 0

                            ScoreCard(
                                score: score,
                                index: index,
                                isSmall: false,
                                isLatest: model.isLatest,
                                isSelected: isSelected,
                                isPlaying: isPlayingForThisScore,
                                progress: progressForThisScore,
                                tapAction: {
                                    if isSelected {
                                        intent.onTapScore(score)
                                        router?.push(
                                            .chordProgress(score: score)
                                        )
                                    } else {
                                        intent.selectScore(score)
                                    }
                                },
                                playButtonAction: {
                                    intent.onTapPlayButton(
                                        score: score,
                                        selectedScore: model.selectedScore
                                    )
                                },
                                stopButtonAction: {
                                    intent.onTapStopButton()
                                },
                                renameScoreAction: { newTitle in
                                    intent.renameScore(score, newTitle: newTitle)
                                },
                                exportScoreAction: { score in
                                    router?.push(.export(score: score))
                                },
                                deleteScoreAction: { score in
                                    intent.requestDeleteScoreConfirmation(score)
                                    if let last = model.sortedScores.last {
                                        intent.selectScore(last)
                                    }
                                },
                                latestPalette: latestPalette,
                                earliestPalette: earliestPalette
                            )
                            .padding(.bottom, isSelected ? 60.0 : .zero)
                        }
                    }
                    .animation(.smooth, value: model.sortedScores)
                    .animation(.default, value: model.selectedScore)
                }
            }

        }
    }

    static let latestPalette: [Color] = [.blue3, .blue4, .blue5, .blue1, .blue2]
    static let earliestPalette: [Color] = [.blue2, .blue1, .blue5, .blue4, .blue3]
}

#Preview {
    PreviewContainer { router in
        router.view(.home)
    }
    .environment(\.locale, .init(languageCode: .english))
}
