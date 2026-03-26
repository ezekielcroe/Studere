import SwiftUI

// MARK: - ComponentRowView
// Displays a single scaffolded study component in the ordered list.
// Shows: icon, name, completion progress, and connection context.
// Replaces NodeRowView from v1.

struct ComponentRowView: View {
    let node: ResearchNode
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon with category color
            Image(systemName: node.nodeType.iconName)
                .font(.body)
                .frame(width: 28, height: 28)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(categoryColor(node.category))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(node.title)
                        .font(.body.weight(.medium))
                    
                    if node.isRequired {
                        // No badge for required — it's the default
                    } else {
                        Text("optional")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.12))
                            )
                    }
                }
                
                // Connection context: what this component relates to
                if !node.relationshipSummary.isEmpty {
                    Text(node.relationshipSummary)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Completion indicator
            completionBadge
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private var completionBadge: some View {
        let progress = node.completionProgress
        
        if progress.total == 0 {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else if progress.filled == progress.total {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else if progress.filled > 0 {
            // Partially filled
            Text("\(progress.filled)/\(progress.total)")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
                .foregroundStyle(.orange)
        } else {
            // Not started
            Text("Start")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.12))
                )
                .foregroundStyle(Color.accentColor)
        }
    }
    
    private func categoryColor(_ category: NodeCategory) -> Color {
        switch category {
        case .design:       return .blue
        case .entity:       return .green
        case .method:       return .orange
        case .supporting:   return .purple
        }
    }
}
