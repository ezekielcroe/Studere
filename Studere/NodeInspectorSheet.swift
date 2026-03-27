import SwiftUI

// MARK: - NodeInspectorSheet
// Socratic Inspector for a single research component.
//
// Keyboard:
//   Tab       — Move between question fields (native macOS behavior)
//   ⌘S        — Save and close
//   Escape    — Close (native sheet behavior)
//   ⌘]        — Next component
//   ⌘[        — Previous component

struct NodeInspectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var node: ResearchNode
    
    /// All nodes in template order, for prev/next navigation.
    var allNodes: [ResearchNode] = []
    /// Callback to switch to a different node.
    var onNavigate: ((ResearchNode) -> Void)?
    /// Callback to trigger an explicit save.
    var onSave: (() -> Void)?
    
    private var questions: [InspectorQuestion] {
        InspectorQuestionBank.questions(for: node.nodeType)
    }
    
    private var currentIndex: Int? {
        allNodes.firstIndex(where: { $0.id == node.id })
    }
    
    private var previousNode: ResearchNode? {
        guard let idx = currentIndex, idx > 0 else { return nil }
        return allNodes[idx - 1]
    }
    
    private var nextNode: ResearchNode? {
        guard let idx = currentIndex, idx < allNodes.count - 1 else { return nil }
        return allNodes[idx + 1]
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        Divider()
                        questionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Inspector")
            .toolbar { toolbarContent }
            // Keyboard shortcuts via hidden buttons
            .background { hiddenShortcuts }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 620)
        #endif
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .cancellationAction) {
            componentNavigator
        }
        ToolbarItemGroup(placement: .confirmationAction) {
            Button("Save & Close") { saveAndClose() }
                .help("Save and close (⌘S)")
        }
    }
    
    private var componentNavigator: some View {
        HStack(spacing: 4) {
            Button { navigatePrevious() } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(previousNode == nil)
            .help("Previous component (⌘[)")
            
            Button { navigateNext() } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(nextNode == nil)
            .help("Next component (⌘])")
            
            if let idx = currentIndex {
                Text("\(idx + 1)/\(allNodes.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
    
    @ViewBuilder
    private var hiddenShortcuts: some View {
        Button("", action: saveAndClose)
            .keyboardShortcut("s", modifiers: .command)
            .hidden()
        Button("", action: navigateNext)
            .keyboardShortcut("]", modifiers: .command)
            .hidden()
        Button("", action: navigatePrevious)
            .keyboardShortcut("[", modifiers: .command)
            .hidden()
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
            
            if !node.relationshipSummary.isEmpty {
                Text(node.relationshipSummary)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
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
            
            #if os(macOS)
            Text("Tab between fields · ⌘S save & close · ⌘[ ⌘] switch components")
                .font(.caption2)
                .foregroundStyle(.quaternary)
            #endif
        }
    }
    
    // MARK: - Questions
    
    @ViewBuilder
    private var questionsSection: some View {
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
                .id(question.key)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveAndClose() {
        onSave?()
        dismiss()
    }
    
    private func navigateNext() {
        guard let next = nextNode else { return }
        onNavigate?(next)
    }
    
    private func navigatePrevious() {
        guard let prev = previousNode else { return }
        onNavigate?(prev)
    }
    
    // MARK: - Helpers
    
    private func bindingForQuestion(_ question: InspectorQuestion) -> Binding<String> {
        Binding(
            get: { node.inspectorData[question.key] ?? "" },
            set: { newValue in
                // CRITICAL FIX: Copy, update, and reassign to avoid SwiftData dictionary crashes
                var updatedData = node.inspectorData
                updatedData[question.key] = newValue
                node.inspectorData = updatedData
                
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
// Each field tracks its own focus state for the highlight ring.
// Tab navigation between TextFields is handled natively by macOS.

struct QuestionFieldView: View {
    let question: InspectorQuestion
    let questionNumber: Int
    @Binding var answer: String
    
    @FocusState private var isFieldFocused: Bool
    @State private var showingHelp = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("\(questionNumber).")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    questionHeader
                    
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
                    
                    // REPLACED TextEditor WITH TextField FOR NATIVE TAB/RETURN SUPPORT
                    TextField("Enter your answer...", text: $answer, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...10)
                        .font(.body)
                        .padding(10)
                        .focused($isFieldFocused)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(fieldStrokeColor, lineWidth: isFieldFocused ? 1.5 : 1)
                        )
                }
            }
        }
    }
    
    private var questionHeader: some View {
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
    }
    
    private var fieldStrokeColor: Color {
        if isFieldFocused {
            return Color.accentColor.opacity(0.6)
        }
        if answer.isEmpty && question.isRequired {
            return Color.orange.opacity(0.4)
        }
        return Color.clear
    }
}
