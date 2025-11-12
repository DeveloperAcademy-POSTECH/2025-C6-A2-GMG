//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(Router.self) private var router: Router

    @State private var model: HomeModelStateProtocol
    @State private var intent: HomeIntentProtocol
    
    init() {
        let model: HomeModel = HomeModel()

        self.model = model
        self.intent = HomeIntent(model: model)
    }

    var body: some View {
        ZStack {
            Color.bg1.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: Spacing.xl) {
                    HeaderSection(count: model.songCount)
                    RecentFileSection(model: model, intent: intent)
                    AllFilesSection(model: model, intent: intent)
                }
                .safeAreaPadding()
            }
            .scrollIndicators(.hidden)
            .task {
                intent.loadScores(context)
            }
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
        let tapAction: () -> Void
        let renameScoreAction: (String) -> Void
        let exportScoreAction: (Score) -> Void
        let deleteScoreAction: (Score) -> Void
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: .zero) {
                    TextField(
                        "Enter Score Title",
                        text: isEditable ? $tempTitle : .constant(score.title)
                    )
                    .font(Typography.WantedSansStd.R4)
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
                    
                    Text("\(score.key.description) Key")
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(Color.white1)
                    
                    Spacer()
                    
                    Text(HomeView.dateConverter(score.createdAt))
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(Color.black6)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: .zero) {
                    
                    Menu {
                        Button("Rename", systemImage: "pencil") {
                            startRename()
                        }
                        
                        Button("Export", systemImage: "square.and.arrow.up") {
                            exportScoreAction(score)
                        }
                        
                        Button("Delete", systemImage: "trash") {
                            deleteScoreAction(score)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Color.white1)
                    }
                    .menuIndicator(.hidden)
                    
                    Spacer()
                    
                    Text(HomeView.formatDuration(score.totalDuration))
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(Color.white1)
                        .padding(.bottom, 9.5)
                        .padding(.trailing, 1)
                    
                    Button {
                        // TODO: 오디오 재생 기능
                    } label: {
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .padding(.leading, 2)
                            .foregroundStyle(Color.black1)
                            .padding(Spacing.xs)
                            .background(Color.white2, in: Circle())
                    }
                    .buttonStyle(.plain)
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
            let palette: [Color] = [.blue3, .blue4, .blue5, .blue1, .blue2]
            return palette[index % palette.count]
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
        @Environment(\.modelContext) private var context
        @Environment(Router.self) private var router: Router
        
        let model: HomeModelStateProtocol
        let intent: HomeIntentProtocol
        
        var body: some View {
            VStack(spacing: Spacing.md) {
                HStack {
                    Text("Recent Files")
                        .font(Typography.WantedSansStd.R7)
                        .foregroundStyle(Color.black1)
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Spacing.md) {
                        AddScoreButton(
                            action: {
                                router.push(.recording)
                            },
                            isExpanded: model.isScoresEmpty
                        )
                        
                        ForEach(
                            Array(model.recentScores.prefix(3).enumerated()),
                            id: \.element.persistentModelID
                        ) { (index, score) in
                            ScoreCard(
                                score: score,
                                index: index,
                                isSmall: true
                            ) {
                                router.push(
                                    .chordProgress(score: score)
                                )
                            } renameScoreAction: { newTitle in
                                intent.renameScore(score, newTitle: newTitle)
                            } exportScoreAction: { score in
                                router.push(.export)
                            } deleteScoreAction: { score in
                                intent.deleteScore(score, context: context)
                            }
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
                        in: RoundedRectangle(cornerRadius: 18)
                    )
            }
            .frame(width: isExpanded ? 156 : 77)
        }
    }
    
    struct AllFilesSection: View {
        @Environment(\.modelContext) private var context
        @Environment(Router.self) private var router: Router
        
        let model: HomeModelStateProtocol
        let intent: HomeIntentProtocol
        
        var body: some View {
            VStack(spacing: Spacing.md) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("All Files")
                        .font(Typography.WantedSansStd.R7)
                        .foregroundStyle(Color.black1)
                        .padding(.trailing, 20)

                    Text("Latest")
                        .font(Typography.WantedSansStd.R5)
                        .foregroundStyle(
                            model.isLatest ? Color.black5 : Color.black3
                        )
                        .padding(.trailing, 12)
                        .onTapGesture { if model.isLatest == false { intent.setIsLatest(true) } }

                    Text("Earliest")
                        .font(Typography.WantedSansStd.R5)
                        .foregroundStyle(
                            model.isLatest ? Color.black3 : Color.black5
                        )
                        .padding(.trailing, 12)
                        .onTapGesture { if model.isLatest == true { intent.setIsLatest(false) } }
                    
                    Spacer()
                }
                
                if model.songCount == 0 {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("An experience")
                            .foregroundStyle(Color.white3.opacity(0.6))
                        Text("where humming")
                            .foregroundStyle(Color.black8.opacity(0.4))
                        Text("becomes the")
                            .foregroundStyle(Color.black4.opacity(0.4))
                        Text("start of a song")
                            .foregroundStyle(Color.black4.opacity(0.55))
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
                    VStack(spacing: -82) {
                        ForEach(
                            Array(model.sortedScores.enumerated()),
                            id: \.element.persistentModelID
                        ) { (index, score) in
                            let isSelected: Bool =
                            model.selectedScore == score

                            ScoreCard(
                                score: score,
                                index: index,
                                isSmall: false
                            ) {
                                if isSelected {
                                    router.push(
                                        .chordProgress(score: score)
                                    )
                                } else {
                                    intent.selectScore(score)
                                }
                            } renameScoreAction: { newTitle in
                                intent.renameScore(score, newTitle: newTitle)
                            } exportScoreAction: { score in
                                router.push(.export)
                            } deleteScoreAction: { score in
                                intent.deleteScore(score, context: context)
                            }
                            .padding(.bottom, isSelected ? 60.0 : .zero)
                        }
                    }
                    .animation(.default, value: model.selectedScore)
                }
            }

        }
    }

}

// MARK: - 데이터 처리 function
extension HomeView {

    static func dateConverter(_ date: Date) -> String {
        let formatted = DateFormatter()
        formatted.dateFormat = "yy. MM. dd"
        return formatted.string(from: date)
    }

    static func formatDuration(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview(traits: .routerModifier) {
    HomeView()
}
