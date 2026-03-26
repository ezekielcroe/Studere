import SwiftUI
import SwiftData

// MARK: - StudySetupView
// Guided study creation flow. The user:
//   1. Names their study
//   2. Picks a study design type (with descriptions)
//   3. Makes any required choices (e.g., data collection method)
//   4. The scaffold is built automatically

struct StudySetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let project: ResearchProject
    var onComplete: () -> Void
    
    @State private var studyTitle: String = ""
    @State private var selectedDesign: NodeType?
    @State private var slotChoices: ScaffoldBuilder.SlotChoices = [:]
    @State private var currentStep: SetupStep = .nameAndDesign
    
    enum SetupStep {
        case nameAndDesign
        case choices
        case review
    }
    
    private var selectedTemplate: StudyDesignTemplate? {
        guard let design = selectedDesign else { return nil }
        return StudyDesignTemplate.template(for: design)
    }
    
    private var choiceSlots: [SlotDefinition] {
        selectedTemplate?.slots.filter { slot in
            if case .choice = slot.blockType { return true }
            return false
        } ?? []
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .nameAndDesign:
                    nameAndDesignStep
                case .choices:
                    choicesStep
                case .review:
                    reviewStep
                }
            }
            .navigationTitle("New Study")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 620)
        #endif
    }
    
    // MARK: - Step 1: Name & Design Selection
    
    private var nameAndDesignStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What is your study about?")
                        .font(.headline)
                    TextField("e.g., Effect of mindfulness on anxiety in university students", text: $studyTitle)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose a study design")
                        .font(.headline)
                    Text("This determines what components your study needs. The app will set up the structure for you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ForEach(StudyDesignTemplate.allDesignTypes) { designType in
                        designCard(for: designType)
                    }
                }
                
                Button {
                    if choiceSlots.isEmpty {
                        currentStep = .review
                    } else {
                        currentStep = .choices
                    }
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedDesign == nil || studyTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.top, 8)
            }
            .padding()
        }
    }
    
    private func designCard(for designType: NodeType) -> some View {
        let template = StudyDesignTemplate.template(for: designType)
        let isSelected = selectedDesign == designType
        let bgColor: Color = isSelected ? Color.accentColor.opacity(0.08) : Color.gray.opacity(0.12)
        let strokeColor: Color = isSelected ? Color.accentColor : Color.clear
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDesign = designType
                slotChoices = [:]
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                designCardHeader(designType: designType, template: template, isSelected: isSelected)
                
                if let t = template {
                    Text(t.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if isSelected, let t = template {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Components:")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(t.slots) { slot in
                                slotPill(slot)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(bgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(strokeColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func designCardHeader(designType: NodeType, template: StudyDesignTemplate?, isSelected: Bool) -> some View {
        HStack {
            Image(systemName: designType.iconName)
                .font(.title3)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(designType.displayName)
                    .font(.body.weight(.semibold))
                if let t = template {
                    Text(t.componentSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
    
    private func slotPill(_ slot: SlotDefinition) -> some View {
        HStack(spacing: 4) {
            if let type = slot.resolvedType {
                Image(systemName: type.iconName)
                    .font(.caption2)
            }
            Text(slot.label)
                .font(.caption2)
            if !slot.isRequired {
                Text("optional")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(categoryColor(for: slot).opacity(0.15))
        )
        .foregroundStyle(categoryColor(for: slot))
    }
    
    // MARK: - Step 2: Choices
    // Broken into extracted sub-views so the compiler can type-check each piece.
    
    private var choicesStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("A few decisions before we set up your study")
                    .font(.headline)
                
                ForEach(choiceSlots) { slot in
                    choiceSection(for: slot)
                }
                
                choicesNavButtons
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func choiceSection(for slot: SlotDefinition) -> some View {
        if case .choice(let options, let prompt) = slot.blockType {
            VStack(alignment: .leading, spacing: 8) {
                Text(prompt)
                    .font(.subheadline.weight(.medium))
                
                if let help = slot.helpText {
                    Text(help)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                ForEach(options) { option in
                    choiceOptionButton(option: option, slotID: slot.id)
                }
            }
        }
    }
    
    private func choiceOptionButton(option: NodeType, slotID: String) -> some View {
        let isChosen = slotChoices[slotID] == option
        let bgColor: Color = isChosen ? Color.accentColor.opacity(0.08) : Color.gray.opacity(0.12)
        
        return Button {
            slotChoices[slotID] = option
        } label: {
            HStack {
                Image(systemName: option.iconName)
                    .frame(width: 24)
                VStack(alignment: .leading) {
                    Text(option.displayName)
                        .font(.body)
                    Text(option.shortDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isChosen {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(bgColor)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var choicesNavButtons: some View {
        HStack {
            Button("Back") {
                currentStep = .nameAndDesign
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button {
                currentStep = .review
            } label: {
                Text("Continue")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!allChoicesMade)
        }
        .padding(.top, 8)
    }
    
    private var allChoicesMade: Bool {
        choiceSlots.allSatisfy { slot in
            !slot.isRequired || slotChoices[slot.id] != nil
        }
    }
    
    // MARK: - Step 3: Review & Build
    // Also extracted into sub-views for compiler performance.
    
    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ready to set up your study")
                        .font(.headline)
                    Text("The app will create all required components and wire them together. Your job will be to fill in the details for each component.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let template = selectedTemplate {
                    reviewCard(template: template)
                }
                
                reviewNavButtons
            }
            .padding()
        }
    }
    
    private func reviewCard(template: StudyDesignTemplate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(studyTitle, systemImage: selectedDesign?.iconName ?? "doc")
                .font(.body.weight(.semibold))
            
            Text("\(template.designType.displayName) design")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
            
            Text("Components to be created:")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            
            ForEach(template.slots) { slot in
                reviewSlotRow(slot: slot)
            }
            
            Divider()
            
            let connectionCount = template.connections.count
            Text("\(connectionCount) connections will be created automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.12))
        )
    }
    
    private func reviewSlotRow(slot: SlotDefinition) -> some View {
        let resolvedType = resolveSlotType(slot)
        return HStack(spacing: 8) {
            Image(systemName: resolvedType.iconName)
                .font(.caption)
                .frame(width: 20)
                .foregroundStyle(categoryColor(for: slot))
            Text(slot.label)
                .font(.subheadline)
            if !slot.isRequired {
                Text("optional")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text(resolvedType.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var reviewNavButtons: some View {
        HStack {
            Button("Back") {
                currentStep = choiceSlots.isEmpty ? .nameAndDesign : .choices
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button {
                buildScaffold()
            } label: {
                Label("Create Study", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    
    private func resolveSlotType(_ slot: SlotDefinition) -> NodeType {
        switch slot.blockType {
        case .fixed(let type): return type
        case .choice(let options, _): return slotChoices[slot.id] ?? options[0]
        }
    }
    
    private func categoryColor(for slot: SlotDefinition) -> Color {
        let type = resolveSlotType(slot)
        switch type.category {
        case .design:       return .blue
        case .entity:       return .green
        case .method:       return .orange
        case .supporting:   return .purple
        }
    }
    
    private func buildScaffold() {
        guard let template = selectedTemplate else { return }
        
        project.title = studyTitle
        
        ScaffoldBuilder.buildScaffold(
            from: template,
            choices: slotChoices,
            for: project,
            in: modelContext
        )
        
        project.status = .draft
        onComplete()
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }
        
        return (CGSize(width: maxX, height: currentY + rowHeight), positions)
    }
}
