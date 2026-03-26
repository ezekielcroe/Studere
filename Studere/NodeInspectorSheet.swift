import SwiftUI

// MARK: - NodeInspectorSheet
// Socratic Inspector for a single research component.
// Presents the structured question sequence and persists answers.
// Mostly unchanged from v1 — the question bank drives it.

struct NodeInspectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var node: ResearchNode
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    Divider()
                    questionsSection
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
            HStack(spacing: 8) {
                Image(systemName: node.nodeType.iconName)
                    .font(.body)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(categoryColor(node.category))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.nodeType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    TextField("Block Title", text: $node.title)
                        .font(.title2.weight(.semibold))
                        .textFieldStyle(.plain)
                }
            }
            
            // Connection context
            if !node.relationshipSummary.isEmpty {
                Text(node.relationshipSummary)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Completion progress
            let progress = node.completionProgress
            if progress.total > 0 {
                HStack(spacing: 4) {
                    ProgressView(value: Double(progress.filled), total: Double(progress.total))
                        .tint(progress.filled == progress.total ? .green : .accentColor)
                    Text("\(progress.filled)/\(progress.total) required")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Questions
    
    private var questionsSection: some View {
        let questions = InspectorQuestionBank.questions(for: node.nodeType)
        
        return Group {
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
    
    private func categoryColor(_ category: NodeCategory) -> Color {
        switch category {
        case .design:       return .blue
        case .entity:       return .green
        case .method:       return .orange
        case .supporting:   return .purple
        }
    }
}

// MARK: - QuestionFieldView

struct QuestionFieldView: View {
    let question: InspectorQuestion
    let questionNumber: Int
    @Binding var answer: String
    
    @State private var showingHelp = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("\(questionNumber).")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .trailing)
                
                VStack(alignment: .leading, spacing: 6) {
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
                        
                        if question.helpText != nil {
                            Button {
                                withAnimation { showingHelp.toggle() }
                            } label: {
                                Image(systemName: showingHelp ? "questionmark.circle.fill" : "questionmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
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
                    
                    TextEditor(text: $answer)
                        .font(.body)
                        .frame(minHeight: 60)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.12))
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
