//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI
internal import UniformTypeIdentifiers

struct DevView: View {
    let scoreRepository: ScoreRepository

    @State private var scores: [Score] = []

    var body: some View {
        List {
            Section("서비스") {
                ResetAllDataButton {
                    resetAllData()

                    fetchScores()
                }
                ImportAudioFileButton { score in
                    do {
                        try scoreRepository.insert(score)

                        fetchScores()
                    } catch {
                        Logger.error(String(describing: error))
                    }
                }
            }
            Section("모든 파일") {
                ScoreList(scores: scores) { score in
                    do {
                        try scoreRepository.delete(score)

                        fetchScores()
                    } catch {
                        Logger.error(String(describing: error))
                    }
                }
            }
        }
        .refreshable {
            fetchScores()
        }
        .navigationTitle("Dev")
        .task {
            fetchScores()
        }
    }

    private func resetAllData() {
        try? FileManager.default.removeItem(at: Score.recordingFolder)

        guard let scores: [Score] = try? scoreRepository.fetch() else { return }

        scores.forEach { score in
            try? scoreRepository.delete(score)
        }
    }

    private func fetchScores() {
        do {
            scores =
                try scoreRepository
                .fetch()
                .sorted(by: { $0.createdAt < $1.createdAt })
        } catch {
            Logger.error(String(describing: error))
        }
    }
}

extension DevView {
    struct ResetAllDataButton: View {
        let deleteAction: () -> Void

        @State private var isConfirmationAlertPresented: Bool = false

        var body: some View {
            Button("모든 데이터 초기화") {
                isConfirmationAlertPresented = true
            }
            .alert("정말 초기화하시겠습니까?", isPresented: $isConfirmationAlertPresented) {
                Button("초기화", role: .destructive) {
                    deleteAction()
                }
                Button("취소", role: .cancel) {}
            }
        }
    }

    struct ImportAudioFileButton: View {
        let insertAction: (Score) -> Void

        @State private var isFileImporterPresented: Bool = false
        @State private var importTask: Task<Void, Never>? = nil

        var body: some View {
            HStack {
                Button("오디오 파일 불러오기") {
                    isFileImporterPresented = true
                }
                .disabled(importTask != nil)

                Spacer()

                if importTask != nil {
                    ProgressView()
                }
            }
            .fileImporter(
                isPresented: $isFileImporterPresented, allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) {
                result in
                switch result {
                case .success(let urls):
                    importTask = Task {
                        defer {
                            importTask = nil
                        }

                        for url in urls {
                            await loadAudioFile(url)
                        }
                    }
                case .failure(let error):
                    Logger.error(String(describing: error))
                }
            }
        }

        private func loadAudioFile(_ url: URL) async {
            guard url.startAccessingSecurityScopedResource() else { return }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            do {
                let copiedURL: URL = URL.temporaryDirectory.appending(
                    component: "recording-\(Date().ISO8601Format()).m4a")

                try FileManager.default.copyItem(at: url, to: copiedURL)

                let scoreFactory: ScoreFactory = ScoreFactory()
                let score: Score = try await scoreFactory.createScore(
                    audioURL: copiedURL)

                score.updateTitle(url.deletingPathExtension().lastPathComponent)

                insertAction(score)
            } catch {
                Logger.error(String(describing: error))
            }
        }
    }

    struct ScoreList: View {
        let scores: [Score]
        let removeAction: (Score) -> Void

        var body: some View {
            ForEach(scores, id: \.id) { score in
                HStack {
                    Text(score.title)

                    Spacer()

                    ShareLink(item: score.audioURL)
                        .labelStyle(.iconOnly)
                }
                .swipeActions {
                    Button("삭제", role: .destructive) {
                        removeAction(score)
                    }
                }
            }
        }
    }
}

#Preview {
    PreviewContainer { router in
        router.view(.dev)
    }
}
