//  Copyright © 2026 ADA 4th GMG. All rights reserved.

import SwiftUI
import UniformTypeIdentifiers

struct DeveloperView: View {
    let scoreRepository: ScoreRepository

    @State private var scoreFactory: ScoreFactory = .init()
    @State private var scores: [Score] = []
    @State private var isFileImporterPresented: Bool = false
    @State private var importTask: Task<Void, Never>? = nil

    var body: some View {
        List {
            Section("Audio") {
                Button("Upload a Audio") {
                    isFileImporterPresented = true
                }
                .disabled(importTask != nil)
                .fileImporter(
                    isPresented: $isFileImporterPresented,
                    allowedContentTypes: [.audio]
                ) { result in
                    switch result {
                    case .success(let success):
                        importTask = Task {
                            defer {
                                self.importTask = nil
                            }

                            do {
                                try await importAudio(audioURL: success)
                                try? fetchScores()
                            } catch {
                                print(error)
                            }
                        }
                    case .failure(let failure):
                        print(failure)
                    }
                }
            }

            Section("Scores") {
                ForEach(scores, id: \.id) { score in
                    Text(score.title)
                }
            }
        }
        .navigationTitle("Developer")
        .task {
            try? fetchScores()
        }
        .refreshable {
            try? fetchScores()
        }
    }
}

extension DeveloperView {
    private func fetchScores() throws {
        self.scores = try scoreRepository.fetch()
    }

    private func importAudio(audioURL: URL) async throws {
        let access = audioURL.startAccessingSecurityScopedResource()

        defer {
            if access { audioURL.stopAccessingSecurityScopedResource() }
        }

        let temporaryURL = URL.temporaryDirectory
            .appending(component: UUID().uuidString)
            .appendingPathExtension(audioURL.pathExtension)

        try FileManager.default.copyItem(at: audioURL, to: temporaryURL)

        let score = try await scoreFactory.createScore(audioURL: temporaryURL)
        score.updateTitle(audioURL.deletingPathExtension().lastPathComponent)
        try scoreRepository.insert(score)
    }
}

#Preview {
    DeveloperView(
        scoreRepository: SwiftDataScoreRepository(
            storage: try! .init(isStoredInMemoryOnly: true)
        )
    )
}
