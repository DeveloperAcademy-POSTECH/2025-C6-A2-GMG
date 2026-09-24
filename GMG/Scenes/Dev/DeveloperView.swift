//  Copyright © 2026 ADA 4th GMG. All rights reserved.

#if DEBUG

    import SwiftUI
    import UniformTypeIdentifiers

    struct DeveloperView: View {
        let scoreRepository: ScoreRepository

        @State private var scoreFactory: ScoreFactory = .init()
        @State private var scores: [Score] = []
        @State private var deletedScores: [Score] = []
        @State private var isFileImporterPresented: Bool = false
        @State private var deleteAllScoresAlertPresented: Bool = false
        @State private var importTask: Task<Void, Never>? = nil
        @State private var error: Error? = nil

        var body: some View {
            List {
                Section("Scores") {
                    ForEach(scores, id: \.id) { score in
                        ScoreListItem(score: score)
                    }
                    .onDelete { offsets in
                        do {
                            try deleteScore(at: offsets, in: scores)
                        } catch {
                            print(error)
                            self.error = error
                        }
                    }
                }

                Section("Deleted Scores") {
                    ForEach(deletedScores, id: \.id) { score in
                        ScoreListItem(score: score)
                    }
                    .onDelete { offsets in
                        do {
                            try deleteScore(at: offsets, in: deletedScores)
                        } catch {
                            print(error)
                            self.error = error
                        }
                    }
                }
            }
            .navigationTitle("Developer")
            .toolbar {
                ToolbarItemGroup {
                    Button(
                        "Delete All Scores",
                        systemImage: "trash",
                        role: .destructive
                    ) {
                        deleteAllScoresAlertPresented = true
                    }

                    Button("Upload a Audio", systemImage: "plus") {
                        isFileImporterPresented = true
                    }
                    .disabled(importTask != nil)
                }
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button(
                    "Cancel",
                    role: .cancel
                ) { error = nil }
            }
            .alert(
                "Delete All Scores?",
                isPresented: $deleteAllScoresAlertPresented,
            ) {
                Button("Delete", role: .destructive) {
                    do {
                        try deletedScores.forEach { score in
                            try deleteScore(score)
                        }
                        try fetchScores()
                    } catch {
                        self.error = error
                    }
                }
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.audio]
            ) { result in
                switch result {
                case .success(let url):
                    importTask = Task {
                        let gotAccess = url.startAccessingSecurityScopedResource()

                        defer {
                            self.importTask = nil

                            if gotAccess {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }

                        do {
                            try await importAudio(audioURL: url)
                            try fetchScores()
                        } catch {
                            print(error)
                            self.error = error
                        }
                    }
                case .failure(let failure):
                    print(failure)
                }
            }
            .task {
                do {
                    try fetchScores()
                } catch {
                    self.error = error
                }
            }
            .refreshable {
                do {
                    try fetchScores()
                } catch {
                    self.error = error
                }
            }
        }
    }

    extension DeveloperView {
        struct ScoreListItem: View {
            let score: Score

            var body: some View {
                VStack(alignment: .leading) {
                    Text(score.title)
                    Text(
                        score.createdAt,
                        format: .dateTime
                            .year()
                            .month()
                            .day()
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    extension DeveloperView {
        private func fetchScores() throws {
            self.scores =
                try scoreRepository
                .fetch()
                .sorted(by: { $0.createdAt > $1.createdAt })
            self.deletedScores =
                try scoreRepository
                .fetchDeleted()
                .sorted(by: { $0.createdAt > $1.createdAt })
        }

        private func deleteScore(
            at offsets: IndexSet,
            in scores: [Score]
        ) throws {
            try offsets.forEach { offset in
                let score = scores[offset]

                try deleteScore(score)
            }
        }

        private func deleteScore(_ score: Score) throws {
            try scoreRepository.delete(score)
            try fetchScores()
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

#endif
