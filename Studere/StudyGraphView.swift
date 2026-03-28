import SwiftUI

// MARK: - StudyGraphView
// Visual graph representation of the study design.
// Nodes are auto-laid out in category tiers (design → entity → method → supporting).
// Edges are drawn as curved paths between connected nodes.
// Tapping a node fires the onSelectNode callback to open the inspector.
//
// This is a read-only visualization — not a drag-and-drop canvas (yet).
// The node positionX/positionY properties on ResearchNode are reserved
// for a future free-form canvas phase.

struct StudyGraphView: View {
    @Environment(\.dismiss) private var dismiss
    
    let project: ResearchProject
    var onSelectNode: ((ResearchNode) -> Void)?
    
    // Layout constants
    private let nodeWidth: CGFloat = 150
    private let nodeHeight: CGFloat = 64
    private let tierSpacing: CGFloat = 100
    private let nodeSpacing: CGFloat = 24
    private let topPadding: CGFloat = 40
    private let leftPadding: CGFloat = 40
    
    // Computed layout
    private var layoutResult: GraphLayout {
        computeLayout()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    // Draw edges first (behind nodes)
                    edgeLayer
                    
                    // Draw nodes on top
                    nodeLayer
                }
                .frame(
                    width: max(layoutResult.canvasWidth, 600),
                    height: max(layoutResult.canvasHeight, 400)
                )
                .padding()
            }
            .background(Color(NSColor.textBackgroundColor))
            .navigationTitle("Study Graph: \(project.title)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .automatic) {
                    legendView
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 500)
        #endif
    }
    
    // MARK: - Edge Layer
    
    private var edgeLayer: some View {
        let positions = layoutResult.nodePositions
        let edges = project.edges ?? []
        
        return ForEach(edges) { edge in
            if let sourceNode = edge.sourceNode,
               let targetNode = edge.targetNode,
               let sourcePos = positions[sourceNode.id],
               let targetPos = positions[targetNode.id] {
                
                EdgePathView(
                    from: CGPoint(
                        x: sourcePos.x + nodeWidth / 2,
                        y: sourcePos.y + nodeHeight
                    ),
                    to: CGPoint(
                        x: targetPos.x + nodeWidth / 2,
                        y: targetPos.y
                    ),
                    label: edge.relationshipType.displayName
                )
            }
        }
    }
    
    // MARK: - Node Layer
    
    private var nodeLayer: some View {
        let positions = layoutResult.nodePositions
        
        return ForEach(project.scaffoldedNodes) { node in
            if let position = positions[node.id] {
                GraphNodeView(node: node)
                    .frame(width: nodeWidth, height: nodeHeight)
                    .position(
                        x: position.x + nodeWidth / 2,
                        y: position.y + nodeHeight / 2
                    )
                    .onTapGesture {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSelectNode?(node)
                        }
                    }
            }
        }
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: 16) {
            legendDot(color: .blue, label: "Design")
            legendDot(color: .green, label: "Entity")
            legendDot(color: .orange, label: "Method")
            legendDot(color: .purple, label: "Supporting")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
    
    // MARK: - Layout Engine
    
    /// Groups nodes into category tiers and computes positions.
    private func computeLayout() -> GraphLayout {
        let nodes = project.scaffoldedNodes
        
        // Group into tiers by category (ordered: design → entity → supporting → method)
        // Supporting goes between entity and method because it connects them conceptually
        let tierOrder: [NodeCategory] = [.design, .entity, .supporting, .method]
        var tiers: [[ResearchNode]] = tierOrder.map { category in
            nodes.filter { $0.category == category }
        }
        // Remove empty tiers
        tiers = tiers.filter { !$0.isEmpty }
        
        var positions: [UUID: CGPoint] = [:]
        var currentY = topPadding
        var maxRowWidth: CGFloat = 0
        
        for tier in tiers {
            let tierWidth = CGFloat(tier.count) * nodeWidth + CGFloat(tier.count - 1) * nodeSpacing
            let startX = leftPadding + max(0, (600 - tierWidth) / 2) // Center each tier
            maxRowWidth = max(maxRowWidth, tierWidth + leftPadding * 2)
            
            for (index, node) in tier.enumerated() {
                let x = startX + CGFloat(index) * (nodeWidth + nodeSpacing)
                positions[node.id] = CGPoint(x: x, y: currentY)
            }
            
            currentY += nodeHeight + tierSpacing
        }
        
        return GraphLayout(
            nodePositions: positions,
            canvasWidth: max(maxRowWidth, 600),
            canvasHeight: currentY + topPadding
        )
    }
}

// MARK: - GraphLayout

private struct GraphLayout {
    let nodePositions: [UUID: CGPoint]
    let canvasWidth: CGFloat
    let canvasHeight: CGFloat
}

// MARK: - GraphNodeView
// A single node rendered on the graph canvas.

private struct GraphNodeView: View {
    let node: ResearchNode
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: node.nodeType.iconName)
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(categoryColor(node.category))
                )
            
            Text(node.title)
                .font(.caption2.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Completion indicator
            completionIndicator
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: node.isComplete ? 1.5 : 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var completionIndicator: some View {
        let progress = node.completionProgress
        if progress.total == 0 || progress.filled == progress.total {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.green)
        } else if progress.filled > 0 {
            Text("\(progress.filled)/\(progress.total)")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.orange)
        } else {
            Text("Empty")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
    
    private var borderColor: Color {
        node.isComplete ? .green.opacity(0.5) : Color.secondary.opacity(0.2)
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

// MARK: - EdgePathView
// Draws a curved path between two points with an optional label.

private struct EdgePathView: View {
    let from: CGPoint
    let to: CGPoint
    let label: String
    
    var body: some View {
        ZStack {
            // The curved path
            EdgeShape(from: from, to: to)
                .stroke(
                    Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
            
            // Arrowhead at the target
            arrowhead
            
            // Edge label at midpoint
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(NSColor.textBackgroundColor))
                    )
                    .position(midpoint)
            }
        }
    }
    
    private var midpoint: CGPoint {
        CGPoint(
            x: (from.x + to.x) / 2,
            y: (from.y + to.y) / 2
        )
    }
    
    private var arrowhead: some View {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowSize: CGFloat = 6
        
        return Path { path in
            path.move(to: to)
            path.addLine(to: CGPoint(
                x: to.x - arrowSize * cos(angle - .pi / 6),
                y: to.y - arrowSize * sin(angle - .pi / 6)
            ))
            path.move(to: to)
            path.addLine(to: CGPoint(
                x: to.x - arrowSize * cos(angle + .pi / 6),
                y: to.y - arrowSize * sin(angle + .pi / 6)
            ))
        }
        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
    }
}

// MARK: - EdgeShape
// A custom Shape that draws a smooth cubic Bézier curve between two points.

private struct EdgeShape: Shape {
    let from: CGPoint
    let to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: from)
            
            // Use a vertical cubic Bézier for clean tiered connections
            let controlOffset = abs(to.y - from.y) * 0.4
            let cp1 = CGPoint(x: from.x, y: from.y + controlOffset)
            let cp2 = CGPoint(x: to.x, y: to.y - controlOffset)
            
            path.addCurve(to: to, control1: cp1, control2: cp2)
        }
    }
}
