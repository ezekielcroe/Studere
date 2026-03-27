import Foundation
import SwiftData

// MARK: - ScaffoldBuilder
// Takes a StudyDesignTemplate and the user's slot choices,
// then creates all ResearchNodes and ResearchEdges in one operation.
//
// This is the engine that makes the "choose a design → get a scaffold"
// flow work. The user never manually assembles the graph.

struct ScaffoldBuilder {
    
    /// The user's choices for any "choice" slots in the template.
    /// Key = SlotDefinition.id, Value = the chosen NodeType.
    typealias SlotChoices = [String: NodeType]
    
    /// Builds the complete scaffold for a project.
    /// - Parameters:
    ///   - template: The study design template
    ///   - choices: User's selections for choice slots
    ///   - project: The project to populate
    ///   - modelContext: SwiftData context for inserting objects
    /// - Returns: A mapping from slot IDs to created nodes (for UI reference)
    @discardableResult
    static func buildScaffold(
        from template: StudyDesignTemplate,
        choices: SlotChoices,
        for project: ResearchProject,
        in modelContext: ModelContext
    ) -> [String: ResearchNode] {
        
        var slotToNode: [String: ResearchNode] = [:]
        
        // Step 1: Create the design node itself
        let designNode = ResearchNode(
            nodeType: template.designType,
            title: template.designType.displayName
        )
        designNode.project = project
        designNode.slotID = "design"
        designNode.isScaffolded = true
        modelContext.insert(designNode)
        slotToNode["design"] = designNode
        
        // Step 2: Create a node for each slot
        for slot in template.slots {
            let nodeType: NodeType
            switch slot.blockType {
            case .fixed(let type):
                nodeType = type
            case .choice(let options, _):
                // Use the user's choice, or fall back to first option
                nodeType = choices[slot.id] ?? options[0]
            }
            
            let node = ResearchNode(
                nodeType: nodeType,
                title: slot.label
            )
            node.project = project
            node.slotID = slot.id
            node.isRequired = slot.isRequired
            node.isScaffolded = true
            modelContext.insert(node)
            slotToNode[slot.id] = node
        }
        
        // Step 3: Create edges for all connections
        for connection in template.connections {
            guard let source = slotToNode[connection.fromSlotID],
                  let target = slotToNode[connection.toSlotID] else {
                continue
            }
            
            let edge = ResearchEdge(
                source: source,
                target: target,
                relationshipType: connection.edgeType
            )
            edge.project = project
            edge.isScaffolded = true
            modelContext.insert(edge)
        }
        
        // Step 4: Update project metadata
        project.designTypeRaw = template.designType.rawValue
        project.touch()
        
        // FIX: Force an explicit save to solidify relationship inverses
        // and assign permanent PersistentIdentifiers to the newly created graph.
        do {
            try modelContext.save()
        } catch {
            print("Failed to save scaffolded project graph: \(error.localizedDescription)")
        }
        
        return slotToNode
    }
    
    /// Validates that all required choice slots have been filled.
    static func validateChoices(
        template: StudyDesignTemplate,
        choices: SlotChoices
    ) -> [String] {
        var missingSlots: [String] = []
        for slot in template.slots {
            if case .choice = slot.blockType, slot.isRequired {
                if choices[slot.id] == nil {
                    missingSlots.append(slot.label)
                }
            }
        }
        return missingSlots
    }
}
