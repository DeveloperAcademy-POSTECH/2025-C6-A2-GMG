//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct HomeView: View {
    @State private var songCount: Int = 4
    
    var body: some View {
        ZStack {
            Color.Background.light
                .ignoresSafeArea()

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
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: Spacing.md) {
                                AddScoreButton {

                                }
                                ScoreCard(
                                    score: sampleScore,
                                    minWidth: 160,
                                    minHeight: nil
                                )
                            }
                        }
                        .frame(minHeight: 128)
                    }

                    VStack(spacing: Spacing.md) {
                        HStack(alignment: .lastTextBaseline) {
                            Text("All Files")
                                .font(Typography.WantedSansStd.R7)
                                .foregroundStyle(Color.Text.black)

                            Text("Latest")
                                .font(Typography.WantedSansStd.R4)
                                .foregroundStyle(Color.Text.black)
                            Text("Earlist")
                                .font(Typography.WantedSansStd.R4)
                                .foregroundStyle(Color.Text.black)
                            Spacer()
                        }

                        VStack(spacing: -82) {
                            ScoreCard(
                                score: sampleScore,
                                minWidth: nil,
                                minHeight: 128
                            )
                        }
                    }
                }
            }
            .safeAreaPadding()
        }
    }

    var sampleScore: Score {
        Score(
            title: "Sample",
            key: Key(root: .C),
            audioUrl: FileManager.default.temporaryDirectory,
            totalDuration: 30,
            createdAt: Date(),
            updatedAt: Date(),
            notes: [],
            chordCells: []
        )
    }
}

extension HomeView {
    
    struct ScoreCard: View {
        let score: Score
        let minWidth: CGFloat?
        let minHeight: CGFloat?

        var body: some View {
            Button(action: {}, label: {
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

                        Text(
                            score.createdAt.formatted(
                                date: .numeric,
                                time: .omitted
                            )
                        )
                        .font(Typography.WantedSansStd.R2)
                        .foregroundStyle(Color.Text.white)
                    }

                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: .zero) {
                        Button(action: {
                            
                        }, label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(Color.Text.white)
                        })
                        Spacer()
                        
                        Text(score.totalDuration.description)
                            .font(Typography.WantedSansStd.R2)
                            .foregroundStyle(Color.Text.white)
                        
                        Spacer()

                        Button {

                        } label: {
                            Image(systemName: "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 8, height: 8)
                                .padding(.leading, 2)
                                .foregroundStyle(Color.Text.black)
                                .padding(Spacing.xs)
                                .background(Color.gray, in: Circle())
                        }
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
                    Color.Tile.blue100,
                    in: RoundedRectangle(cornerRadius: 32)
                )
            })
        }
    }
    
    struct AddScoreButton: View {
        let action: () -> Void

        var body: some View {
            Button {

            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.Text.black)
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
            string.foregroundColor = Color.Text.gray
            return string
        }

        private var chordString: AttributedString {
            var string: AttributedString = AttributedString("chord")
            string.foregroundColor = Color.Text.black
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
                .foregroundStyle(Color.Text.black)
        }
    }
    
}

#Preview {
    HomeView()
}
