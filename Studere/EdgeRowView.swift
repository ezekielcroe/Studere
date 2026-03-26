import SwiftUI

// MARK: - EdgeRowView
// Displays a single edge (connection) between two nodes.

struct EdgeRowView: View {
    let edge: ResearchEdge
    
    var body: some View {
        HStack(spacing: 8) {
            Text(edge.sourceNode?.title ?? "???")
                .font(.callout)
                .lineLimit(1)
            
            Image(systemName: arrowIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(edge.targetNode?.title ?? "???")
                .font(.callout)
                .lineLimit(1)
            
            Spacer()
            
            Text(edge.relationshipType.displayName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.15))
                )
        }
    }
    
    private var arrowIcon: String {
        switch edge.relationshipType {
        case .temporal:      return "arrow.right"
        case .comparison:    return "arrow.left.arrow.right"
        case .observational: return "eye"
        case .causal:        return "arrow.right.circle"
        }
    }
}
