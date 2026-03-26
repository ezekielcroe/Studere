import SwiftUI

// MARK: - NodeInspectorSheet
// Phase 1/2 preview of the Socratic Inspector (§4.3).
// Presents the structured question sequence for the selected node type
// and persists answers to the node's inspectorData dictionary.
//
// In the full app (Phase 2+), this becomes the right sidebar panel
// with richer interactions. For Phase 1, a sheet is sufficient to
// validate the data flow.

struct NodeInspectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var node: ResearchNode
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    Divider()
                    
                    // Questions
                    let questions = InspectorQuestionBank.questions(for: node.nodeType)
                    
                    if questions.isEmpty {
                        Text("No inspector questions defined for this block type yet.")
                            .foregroundStyle(.secondary)
                            .italic()
                            .padding()
                    } else {
                        ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                            QuestionFieldView(
                                question: question,
                                questionNumber: index + 1,
                                answer: bindingForQuestion(question)
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Inspector")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
        #endif
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(colorForCategory(node.category))
                    .frame(width: 12, height: 12)
                Text(node.nodeType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            
            TextField("Block Title", text: $node.title)
                .font(.title2.weight(.semibold))
                .textFieldStyle(.plain)
            
            // Completion progress
            let questions = InspectorQuestionBank.questions(for: node.nodeType)
            let required = questions.filter(\.isRequired)
            let filled = required.filter { q in
                !(node.inspectorData[q.key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            
            if !required.isEmpty {
                HStack(spacing: 4) {
                    ProgressView(value: Double(filled.count), total: Double(required.count))
                        .tint(filled.count == required.count ? .green : .accentColor)
                    Text("\(filled.count)/\(required.count) required")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func bindingForQuestion(_ question: InspectorQuestion) -> Binding<String> {
        Binding(
            get: { node.inspectorData[question.key] ?? "" },
            set: { newValue in
                node.inspectorData[question.key] = newValue
                node.project?.touch()
            }
        )
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

// MARK: - QuestionFieldView
// A single Socratic question with its text input area.

struct QuestionFieldView: View {
    let question: InspectorQuestion
    let questionNumber: Int
    @Binding var answer: String
    
    @State private var showingHelp = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Question prompt
            HStack(alignment: .top) {
                Text("\(questionNumber).")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .trailing)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(question.prompt)
                            .font(.subheadline.weight(.medium))
                        
                        if !question.isRequired {
                            Text("optional")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.15))
                                )
                        }
                        
                        if let _ = question.helpText {
                            Button {
                                withAnimation { showingHelp.toggle() }
                            } label: {
                                Image(systemName: "questionmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Help text (expandable)
                    if showingHelp, let helpText = question.helpText {
                        Text(helpText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accentColor.opacity(0.07))
                            )
                    }
                    
                    // Answer input
                    TextEditor(text: $answer)
                        .font(.body)
                        .frame(minHeight: 60)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray).opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    answer.isEmpty && question.isRequired
                                        ? Color.orange.opacity(0.4)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                }
            }
        }
    }
}
