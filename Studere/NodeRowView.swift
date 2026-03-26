import SwiftUI

// MARK: - NodeRowView
// Displays a single research node in the project detail list.

struct NodeRowView: View {
    let node: ResearchNode
    
    var body: some View {
        HStack {
            Circle()
                .fill(colorForCategory(node.category))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(node.title)
                    .font(.body)
                Text(node.nodeType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Completion indicator
            let required = InspectorQuestionBank.requiredKeys(for: node.nodeType)
            let filled = required.filter { !(node.inspectorData[$0] ?? "").isEmpty }.count
            
            if required.isEmpty {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.green)
            } else {
                Text("\(filled)/\(required.count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(filled == required.count ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    )
                    .foregroundStyle(filled == required.count ? .green : .orange)
            }
        }
    }
    
    private func colorForCategory(_ category: NodeCategory) -> Color {
        switch category {
        case .design:       return .blue
        case .entity:       return .green
        case .method:       return .orange
        case .supporting:   return .purple
        }
    }
}
