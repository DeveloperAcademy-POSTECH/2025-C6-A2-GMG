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
            HomePalette.Background.root
                .padding(-Spacing.xxl)
                .ignoresSafeArea()

            VStack {
                ScrollView {
                    LazyVStack(spacing: Spacing.xl) {
                        RecentFilesSection(model: model, intent: intent, router: router)
                        AllFilesSection(model: model, intent: intent, router: router)
                    }
                    .safeAreaPadding(Spacing.md)
                }
                .scrollIndicators(.hidden)
            }
        }
        .task {
            intent.onAppear()
            if model.selectedScore == nil {
                selectLastScore()
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
                        dimmingTintColor: UIColor.Home.headerBlurTint,
                        dimmingAlpha: .constant(alpha: 0.8),
                        dimmingOvershoot: .relative(fraction: 0.5)
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
                    selectLastScore()
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

    private func selectLastScore() {
        guard let last = model.sortedScores.last else { return }
        intent.selectScore(last)
    }
}

// MARK: - Header Section

extension HomeView {
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

        struct Logo: View {
            private var reString: AttributedString {
                var string: AttributedString = AttributedString("Re:")
                string.foregroundColor = HomePalette.Header.logoRe
                return string
            }

            private var chordString: AttributedString {
                var string: AttributedString = AttributedString("chord")
                string.foregroundColor = HomePalette.Header.logoChord
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
                    .foregroundStyle(HomePalette.Header.songCountText)
            }
        }
    }
}

// MARK: - Recent Files Section

extension HomeView {
    struct RecentFilesSection: View {
        @Namespace private var namespace: Namespace.ID
        private let recordButtonID: String = "RecordButton"

        let model: HomeModelStateProtocol
        let intent: HomeIntentProtocol
        weak var router: Router?

        var body: some View {
            VStack(spacing: Spacing.md) {
                HStack {
                    Text(.recentFiles)
                        .font(
                            .english(Typography.WantedSansStd.R7),
                            .korean(Typography.Pretendard.SB7)
                        )
                        .foregroundStyle(HomePalette.Recent.title)

                    Spacer()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Spacing.md) {
                        AddScoreButton {
                            router?.push(.recording, id: recordButtonID, in: namespace)
                        }
                        .frame(width: model.songCount == 0 ? 156 : 124)
                        .matchedTransitionSource(id: recordButtonID, in: namespace)

                        ScoreList(model: model, intent: intent, router: router)
                    }
                }
                .scrollClipDisabled()
                .frame(minHeight: 128)
            }
        }

        struct AddScoreButton: View {
            let action: () -> Void

            var body: some View {
                Button {
                    action()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(HomePalette.Recent.addButtonIcon)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            HomePalette.Recent.addButtonBackground,
                            in: RoundedRectangle(cornerRadius: 32)
                        )
                }
                .buttonStyle(.bouncy)
            }
        }

        struct ScoreList: View {
            @Namespace private var namespace: Namespace.ID

            let model: HomeModelStateProtocol
            let intent: HomeIntentProtocol
            let router: Router?

            var body: some View {
                ForEach(
                    Array(model.recentScores.enumerated()),
                    id: \.element.id
                ) { (index, score) in
                    let isSelected: Bool = model.selectedScore?.id == score.id
                    let isPlaying: Bool = isSelected && model.playhead.isPlaying
                    let elapsedTime: TimeInterval =
                        isSelected ? model.playhead.elapsedTime : 0.0

                    ScoreCard(
                        score: score,
                        isPlaying: isPlaying,
                        elapsedTime: elapsedTime,
                        tapAction: { score in
                            intent.onTapScore(score)
                            router?.push(
                                .chordProgress(score: score),
                                id: score.id,
                                in: namespace
                            )
                        },
                        playAction: intent.onTapPlayButton,
                        stopAction: intent.onTapStopButton,
                        renameScoreAction: intent.renameScore,
                        exportScoreAction: { router?.push(.export(score: $0)) },
                        deleteScoreAction: intent.requestDeleteScoreConfirmation
                    )
                    .compactStyle()
                    .backgroundColor(HomePalette.ScoreCard.latestBackground(index: index))
                    .frame(width: 156)
                    .matchedTransitionSource(id: score.id, in: namespace)
                }
            }
        }
    }
}

// MARK: - All Files Section

extension HomeView {
    struct AllFilesSection: View {
        let model: HomeModelStateProtocol
        let intent: HomeIntentProtocol
        weak var router: Router?

        var body: some View {
            VStack(spacing: Spacing.md) {
                HStack(alignment: .lastTextBaseline, spacing: 20) {
                    Text(.allFiles)
                        .font(
                            .english(Typography.WantedSansStd.R7),
                            .korean(Typography.Pretendard.SB7)
                        )
                        .foregroundStyle(HomePalette.All.title)

                    HStack(alignment: .lastTextBaseline, spacing: Spacing.sm) {
                        SortButton(.latest) {
                            intent.setLatest(true)
                            if let lastScore = model.sortedScores.last {
                                intent.selectScore(lastScore)
                            }
                        }
                        .disabled(model.isLatest == true)

                        SortButton(.earliest) {
                            intent.setLatest(false)
                            if let lastScore = model.sortedScores.last {
                                intent.selectScore(lastScore)
                            }
                        }
                        .disabled(model.isLatest == false)
                    }

                    Spacer()
                }

                if model.songCount == 0 {
                    EmptyScoreBackground()
                } else {
                    ScoreList(model: model, intent: intent, router: router)
                }
            }
        }

        struct SortButton: View {
            @Environment(\.isEnabled) private var isEnabled: Bool

            let title: Text
            let action: () -> Void

            init<S: StringProtocol>(_ title: S, action: @escaping () -> Void) {
                self.title = Text(title)
                self.action = action
            }

            init(_ title: LocalizedStringResource, action: @escaping () -> Void) {
                self.title = Text(title)
                self.action = action
            }

            var body: some View {
                Button {
                    action()
                } label: {
                    title
                        .font(
                            .english(Typography.WantedSansStd.R5),
                            .korean(Typography.Pretendard.M5)
                        )
                        .foregroundStyle(
                            isEnabled == false
                                ? HomePalette.All.sortDisabled
                                : HomePalette.All.sortEnabled
                        )
                }
                .buttonStyle(.bouncy)
            }
        }

        struct EmptyScoreBackground: View {
            var body: some View {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("An experience")
                        .foregroundStyle(HomePalette.All.emptyLine1)
                    Text("where humming")
                        .foregroundStyle(HomePalette.All.emptyLine2)
                    Text("becomes the")
                        .foregroundStyle(HomePalette.All.emptyLine3)
                    Text("start of a song")
                        .foregroundStyle(HomePalette.All.emptyLine4)
                }
                .font(
                    .custom(Typography.WantedSansStd.Bold, size: 42)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 48)
            }
        }

        struct ScoreList: View {
            @Namespace private var namespace: Namespace.ID

            let model: HomeModelStateProtocol
            let intent: HomeIntentProtocol
            weak var router: Router?

            var body: some View {
                VStack(spacing: -60) {
                    ForEach(
                        Array(model.sortedScores.enumerated()),
                        id: \.element.id
                    ) { (index, score) in
                        let isSelected: Bool = model.selectedScore?.id == score.id
                        let isPlaying: Bool = isSelected && model.playhead.isPlaying
                        let elapsedTime: TimeInterval =
                            isSelected ? model.playhead.elapsedTime : 0.0

                        ScoreCard(
                            score: score,
                            isPlaying: isPlaying,
                            elapsedTime: elapsedTime,
                            tapAction: { score in
                                if isSelected {
                                    intent.onTapScore(score)
                                    router?.push(
                                        .chordProgress(score: score),
                                        id: score.id,
                                        in: namespace
                                    )
                                } else {
                                    intent.selectScore(score)
                                }
                            },
                            playAction: intent.onTapPlayButton,
                            stopAction: intent.onTapStopButton,
                            renameScoreAction: intent.renameScore,
                            exportScoreAction: { router?.push(.export(score: $0)) },
                            deleteScoreAction: intent.requestDeleteScoreConfirmation
                        )
                        .playButtonVisibility(isSelected ? .visible : .hidden)
                        .backgroundColor(
                            model.isLatest
                                ? HomePalette.ScoreCard.latestBackground(index: index)
                                : HomePalette.ScoreCard.earliestBackground(index: index)
                        )
                        .frame(height: 128)
                        .matchedTransitionSource(id: score.id, in: namespace)
                        .padding(.bottom, isSelected ? 60.0 : .zero)
                    }
                }
                .animation(.smooth, value: model.sortedScores)
                .animation(.default, value: model.selectedScore)
            }
        }
    }
}

// MARK: - ScoreCard

extension HomeView {
    struct ScoreCard: View {
        @State private var isTitleEditing: Bool = false
        @FocusState private var isTitleFocused: Bool
        @State private var titleDraft: String = ""

        let score: Score
        let isPlaying: Bool
        let elapsedTime: Double
        let tapAction: (Score) -> Void
        let playAction: (Score) -> Void
        let stopAction: () -> Void
        let renameScoreAction: (Score, String) -> Void
        let exportScoreAction: (Score) -> Void
        let deleteScoreAction: (Score) -> Void

        var isCompact: Bool = false
        var playButtonVisibility: Visibility = .visible
        var backgroundColor: Color = .black1

        var body: some View {
            VStack(spacing: Spacing.xxs) {
                HStack {
                    TextField(
                        LocalizedStringKey(LocalizedStringResource.enterTitle.key),
                        text: isTitleEditing ? $titleDraft : .constant(score.title)
                    )
                    .multilineTextAlignment(.leading)
                    .font(
                        isCompact ? Typography.WantedSansStd.R4 : Typography.WantedSansStd.R5
                    )
                    .foregroundStyle(HomePalette.ScoreCard.title)
                    .autocorrectionDisabled()
                    .focused($isTitleFocused)
                    .onSubmit { endRename() }
                    .submitLabel(.done)
                    .disabled(isTitleEditing == false)
                    .onChange(of: titleDraft) {
                        if titleDraft.count > Constants.scoreTitleMaxLength {
                            titleDraft = String(
                                titleDraft.prefix(Constants.scoreTitleMaxLength))
                        }
                    }

                    Spacer()

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
                            .foregroundStyle(HomePalette.ScoreCard.menuIcon)
                            .frame(maxWidth: 20, maxHeight: 30)
                    }
                    .menuIndicator(.hidden)
                }

                HStack {
                    Text(score.createdAt.formattedDate())
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(HomePalette.ScoreCard.meta)

                    Spacer()

                    Text(score.totalDuration.formattedTime())
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(HomePalette.ScoreCard.meta)
                }

                Spacer(minLength: 0.0)

                HStack(alignment: .bottom) {
                    Text("\(score.key.description) Key")
                        .font(
                            isCompact
                                ? Typography.WantedSansStd.R2 : Typography.WantedSansStd.R4
                        )
                        .foregroundStyle(HomePalette.ScoreCard.key)

                    Spacer()

                    let progress: Double =
                        score.totalDuration > 0.0 ? elapsedTime / score.totalDuration : 0.0

                    PlaybackButton(
                        isPlaying: isPlaying,
                        progress: progress,
                        playAction: { playAction(score) },
                        stopAction: stopAction
                    )
                    .opacity(playButtonVisibility != .hidden ? 1.0 : 0.0)
                    .blur(radius: playButtonVisibility != .hidden ? 0.0 : 8.0)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                backgroundColor,
                in: RoundedRectangle(cornerRadius: 32)
            )
            .onTapGesture {
                if isTitleEditing {
                    endRename()
                } else {
                    tapAction(score)
                }
            }
        }

        func compactStyle() -> Self {
            var card = self
            card.isCompact = true
            return card
        }

        func playButtonVisibility(_ visibility: Visibility) -> Self {
            var card = self
            card.playButtonVisibility = visibility
            return card
        }

        func backgroundColor(_ color: Color) -> Self {
            var card = self
            card.backgroundColor = color
            return card
        }

        // MARK: - Rename Actions

        private func startRename() {
            titleDraft = score.title

            isTitleEditing = true
            Task { @MainActor in
                isTitleFocused = true
            }
        }

        private func endRename() {
            renameScoreAction(score, titleDraft)

            isTitleFocused = false
            isTitleEditing = false
        }

        struct PlaybackButton: View {
            let isPlaying: Bool
            let progress: Double
            let playAction: () -> Void
            let stopAction: () -> Void

            var body: some View {
                Button {
                    if isPlaying {
                        stopAction()
                    } else {
                        playAction()
                    }
                } label: {
                    Image(isPlaying ? .pause : .smallPlay)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: isPlaying ? 12 : 10, height: isPlaying ? 12 : 10)
                        .padding(.leading, isPlaying ? 0 : 2)
                        .foregroundStyle(HomePalette.Playback.icon)
                        .frame(width: 30, height: 30)
                        .background {
                            let lineWidth: CGFloat = 3
                            let isProgressPresented: Bool = isPlaying || progress > 0

                            Circle()
                                .inset(by: lineWidth / 2 + 0.2)
                                .fill(HomePalette.Playback.circleFill)
                                .stroke(
                                    isProgressPresented
                                        ? HomePalette.Playback.circleBaseStroke
                                        : HomePalette.Playback.circleBaseStrokeIdle,
                                    lineWidth: lineWidth
                                )
                                .drawingGroup()

                            Circle()
                                .inset(by: lineWidth / 2)
                                .trim(from: 0, to: progress)
                                .stroke(
                                    HomePalette.Playback.progress,
                                    style: StrokeStyle(
                                        lineWidth: lineWidth, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .opacity(isProgressPresented ? 1 : 0)
                        }
                }
                .buttonStyle(.bouncy)
            }
        }
    }
}

#Preview {
    PreviewContainer { router in
        router.view(.home)
    }
    .environment(\.locale, .init(languageCode: .english))
}

extension Date {
    fileprivate func formattedDate() -> String {
        return
            self
            .formatted(
                .dateTime
                    .year(.twoDigits)
                    .month(.twoDigits)
                    .day(.twoDigits)
            )
    }
}

extension TimeInterval {
    fileprivate func formattedTime() -> String {
        let duration: Duration = Duration.seconds(self)
        return duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }
}
