//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI
import SwiftData

struct ScoreListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Score.updatedAt, order: .reverse) private var scores: [Score]
    
    var body: some View {
        VStack{
            Text("hi")
            List {
                ForEach(scores) { score in
                    VStack(alignment: .leading) {
                        Text(score.title)
                        Text(score.key.description + " - " + String(Int(score.totalDuration)) + "s")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: delete)
            }
            Button("Add") { addScore() }
            .toolbar {
                Button("Add") { addScore() }
            }
        }
    }
    
    private func addScore() {
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        let new = Score(
            title: "New Score",
            key: Key(root: .C),
            audioUrl: tmpURL,
            totalDuration: 0,
            createdAt: .now,
            updatedAt: .now,
            notes: [],
            chordCells: []
        )
        
        context.insert(new)
        try? context.save()
    }
    
    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(scores[i]) }
        try? context.save()
    }
}
