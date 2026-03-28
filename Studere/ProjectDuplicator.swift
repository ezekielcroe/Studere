import Foundation
import SwiftData

// MARK: - ProjectDuplicator
// Creates a deep copy of a ResearchProject, including all nodes,
// edges, and inspector data. The duplicate gets a new UUID and
// "Copy of ..." title.

struct ProjectDuplicator {
    
    /// Creates a full deep copy of the given project.
    /// - Parameters:
    ///   - source: The project to duplicate.
    ///   - modelContext: The SwiftData context to insert the new objects into.
    /// - Returns: The newly created duplicate project.
    @discardableResult
    static func duplicate(
        _ source: ResearchProject,
        in modelContext: ModelContext
    ) -> ResearchProject {
        
        // 1. Create the new project with copied metadata
        let newProject = ResearchProject(title: "Copy of \(source.title)")
        newProject.designTypeRaw = source.designTypeRaw
        newProject.statusRaw = source.statusRaw
        modelContext.insert(newProject)
        
        // 2. Deep-copy all nodes, tracking old→new mapping for edge rewiring
        var nodeMap: [UUID: ResearchNode] = [:]
        
        for oldNode in (source.nodes ?? []) {
            let newNode = ResearchNode(
                nodeType: oldNode.nodeType,
                title: oldNode.title,
                positionX: oldNode.positionX,
                positionY: oldNode.positionY
            )
            // Copy all inspector answers
            newNode.inspectorData = oldNode.inspectorData
            // Copy scaffold metadata
            newNode.slotID = oldNode.slotID
            newNode.isScaffolded = oldNode.isScaffolded
            newNode.isRequired = oldNode.isRequired
            // Assign to new project
            newNode.project = newProject
            modelContext.insert(newNode)
            
            nodeMap[oldNode.id] = newNode
        }
        
        // 3. Deep-copy all edges, rewiring to the new nodes
        for oldEdge in (source.edges ?? []) {
            guard let oldSource = oldEdge.sourceNode,
                  let oldTarget = oldEdge.targetNode,
                  let newSource = nodeMap[oldSource.id],
                  let newTarget = nodeMap[oldTarget.id] else {
                continue
            }
            
            let newEdge = ResearchEdge(
                source: newSource,
                target: newTarget,
                relationshipType: oldEdge.relationshipType
            )
            newEdge.isScaffolded = oldEdge.isScaffolded
            newEdge.project = newProject
            modelContext.insert(newEdge)
        }
        
        // 4. Save to solidify the new graph
        do {
            try modelContext.save()
        } catch {
            print("Failed to save duplicated project: \(error.localizedDescription)")
        }
        
        return newProject
    }
}
