//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var allScores: [Score]

    @State private var expandedAll: Int? = nil
    @State private var isLatest: Bool = true

    private var songCount: Int { allScores.count }

    private var sortedScores: [Score] {
        allScores.sorted {
            if isLatest {
                if $0.updatedAt != $1.updatedAt {
                    return $0.updatedAt > $1.updatedAt
                } else {
                    return $0.createdAt > $1.createdAt
                }
            } else {
                if $0.createdAt != $1.createdAt {
                    return $0.createdAt < $1.createdAt
                } else {
                    return $0.updatedAt < $1.updatedAt
                }
            }
        }
    }

    private var recentScores: [Score] {
        Array(sortedScores.prefix(10))
    }

    var body: some View {
        ZStack {
            Color.Background.bg1.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: Spacing.xl) {
                    HStack {
                        Logo()
                        Spacer()
                        SongCount(count: songCount)
                            .padding(.top, 60)
                    }
                    
                    VStack(spacing: Spacing.md) {
                        HStack {
                            Text("Recent Files")
                                .font(Typography.WantedSansStd.R7)
                                .foregroundStyle(Color.Text.black)
                            Spacer()
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: Spacing.md) {
                                AddScoreButton {}

                                ForEach(Array(recentScores.enumerated()), id: \.element.persistentModelID) { (idx, score) in
                                    ScoreCard(
                                        score: score,
                                        minWidth: 160,
                                        minHeight: nil,
                                        index: idx + 1,
                                        isMove: false,
                                        isSelected: bindingForRecent(index: idx + 1)
                                    )
                                }
                            }
                        }
                        .frame(minHeight: 128)
                    }

                    VStack(spacing: Spacing.md) {
                        HStack(alignment: .lastTextBaseline, spacing: 0) {
                            Text("All Files")
                                .font(Typography.WantedSansStd.R7)
                                .foregroundStyle(Color.Text.black)
                                .padding(.trailing, 20)

                            Text("Latest")
                                .font(Typography.WantedSansStd.R5)
                                .foregroundStyle(isLatest ? Color.black5 : Color.black3)
                                .padding(.trailing, 12)
                                .onTapGesture { isLatest = true }

                            Text("Earliest")
                                .font(Typography.WantedSansStd.R5)
                                .foregroundStyle(isLatest ? Color.black3 : Color.black5)
                                .padding(.trailing, 12)
                                .onTapGesture { isLatest = false }

                            Spacer()
                        }
                        
                        if songCount == 0 {

                            VStack(alignment: .leading) {
                                Text("An experience")
                                    .font(Typography.WantedSansStd.Empty)
                                    .foregroundStyle(Color.black1.opacity(0.1))
                                Text("where humming")
                                    .font(Typography.WantedSansStd.Empty)
                                    .foregroundStyle(Color.black1.opacity(0.3))
                                Text("becomes the")
                                    .font(Typography.WantedSansStd.Empty)
                                    .foregroundStyle(Color.black1.opacity(0.5))
                                Text("start of a song")
                                    .font(Typography.WantedSansStd.Empty)
                                    .foregroundStyle(Color.black1.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 48)
                        } else {
                            
                            VStack(spacing: -82) {
                                ForEach(Array(sortedScores.enumerated()), id: \.element.persistentModelID) { (idx, score) in
                                    ScoreCard(
                                        score: score,
                                        minWidth: nil,
                                        minHeight: 128,
                                        index: idx + 1,
                                        isMove: true,
                                        isSelected: bindingForAll(index: idx + 1)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .safeAreaPadding()
        }
    }
}

extension HomeView {
    struct ScoreCard: View {
        let score: Score
        let minWidth: CGFloat?
        let minHeight: CGFloat?
        let index: Int
        let isMove: Bool
        @Binding var isSelected: Bool
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: .zero) {
                    Text(score.title)
                        .font(Typography.WantedSansStd.R4)
                        .foregroundStyle(Color.Text.white)
                        .padding(.bottom, 4)
                    
                    Text("\(score.key.description) Key")
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(Color.Text.white)
                    
                    Spacer()
                    
                    Text(HomeView.dateConverter(score.createdAt))
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(Color.black6)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: .zero) {
                    Button(action: {
                        //TODO: 삭제 등 미트볼버튼 기능 추가
                    }, label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Color.Text.white)
                    })
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text(score.totalDuration.description)
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(Color.Text.white)
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
                            .foregroundStyle(Color.Text.black)
                            .padding(Spacing.xs)
                            .background(Color.white2, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.lg)
            .frame(
                minWidth: minWidth,
                maxWidth: .infinity,
                minHeight: minHeight,
                maxHeight: .infinity
            )
            .background(
                colorForIndex(index),
                in: RoundedRectangle(cornerRadius: 32)
            )
            .contentShape(RoundedRectangle(cornerRadius: 32))
            .onTapGesture {
                isSelected.toggle()
            }
            .padding(.bottom, isSelected && isMove ? 60 : 0)
        }
        
        private func colorForIndex(_ i: Int) -> Color {
            let palette: [Color] = [
                Color.blue3,
                Color.blue4,
                Color.blue5,
                Color.blue1,
                Color.blue2
            ]
            // 1 미만이 들어와도 안전하게 처리
            let safe = max(i, 1)
            return palette[(safe - 1) % palette.count]
        }
    }
    
    struct AddScoreButton: View {
        let action: () -> Void

        var body: some View {
            Button {

            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.black1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        Color.white,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
            }
            .frame(width: 80)
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
            ViewThatFits {
                Text("\(reString)\n\(chordString)")
                    .font(Typography.WantedSansStd.B16)
                    .transition(.blurReplace)
                Text("\(reString)\(chordString)")
                    .font(Typography.WantedSansStd.B16)
                    .transition(.blurReplace)
            }
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
    
}

// MARK: - 데이터 처리 function
extension HomeView {

    static func dateConverter(_ date: Date) -> String {
        let formatted = DateFormatter()
        formatted.dateFormat = "yy. MM. dd"
        return formatted.string(from: date)
    }

    private func bindingForRecent(index i: Int) -> Binding<Bool> {
        Binding(get: { false }, set: { _ in })
    }

    private func bindingForAll(index i: Int) -> Binding<Bool> {
        Binding(
            get: { expandedAll == i },
            set: { newValue in
                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.85)) {
                    expandedAll = newValue ? i : nil
                }
            }
        )
    }
}

#Preview {
    HomeView()
}
