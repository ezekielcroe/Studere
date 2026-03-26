import SwiftUI

// MARK: - ConnectionRowView
// Displays a scaffolded edge in a read-only reference list.
// Replaces EdgeRowView from v1.
// These connections are auto-created and not user-editable.

struct ConnectionRowView: View {
    let edge: ResearchEdge
    
    var body: some View {
        HStack(spacing: 6) {
            Text(edge.sourceNode?.title ?? "—")
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            HStack(spacing: 3) {
                Image(systemName: edge.relationshipType.arrowIcon)
                    .font(.caption2)
                Text(edge.relationshipType.displayName)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.secondary.opacity(0.08))
            )
            
            Text(edge.targetNode?.title ?? "—")
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.secondary)
    }
}
