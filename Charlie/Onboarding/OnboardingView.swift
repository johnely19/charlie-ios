import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case inviteCode = 1
    case setup = 2
    case complete = 3
}

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentStep: OnboardingStep = .welcome
    @State private var inviteCode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Setup step state
    @State private var selectedCity: String = ""
    @State private var selectedInterests: Set<String> = []
    @State private var showCityPicker: Bool = false

    private let cities = ["New York", "Los Angeles", "Chicago", "San Francisco", "Miami", "Seattle", "Austin", "Boston", "Denver", "Portland"]
    private let interests = ["Trip", "Date nights", "Local radar", "Groceries"]

    var body: some View {
        ZStack {
            Color(red: 30/255, green: 27/255, blue: 75/255) // #1e1b4b
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                stepContent
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

                Spacer()

                bottomContent
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
        .sheet(isPresented: $showCityPicker) {
            CityPickerView(selectedCity: $selectedCity, cities: cities)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            WelcomeStepView()
        case .inviteCode:
            InviteCodeStepView(
                code: $inviteCode,
                isLoading: isLoading,
                errorMessage: errorMessage
            )
        case .setup:
            SetupStepView(
                selectedCity: $selectedCity,
                selectedInterests: $selectedInterests,
                interests: interests,
                showCityPicker: $showCityPicker
            )
        case .complete:
            CompleteStepView()
        }
    }

    @ViewBuilder
    private var bottomContent: some View {
        switch currentStep {
        case .welcome:
            Button(action: goToNextStep) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 99/255, green: 102/255, blue: 241/255)) // Indigo
                    .cornerRadius(12)
            }
        case .inviteCode:
            VStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Button(action: submitInviteCode) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(inviteCode.isEmpty ? Color.gray.opacity(0.5) : Color(red: 99/255, green: 102/255, blue: 241/255))
                            .cornerRadius(12)
                    }
                    .disabled(inviteCode.isEmpty)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        case .setup:
            Button(action: completeSetup) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedCity.isEmpty ? Color.gray.opacity(0.5) : Color(red: 99/255, green: 102/255, blue: 241/255))
                    .cornerRadius(12)
            }
            .disabled(selectedCity.isEmpty)
        case .complete:
            EmptyView()
        }
    }

    private func goToNextStep() {
        withAnimation {
            currentStep = .inviteCode
        }
    }

    private func submitInviteCode() {
        guard !inviteCode.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await APIClient.shared.authenticate(code: inviteCode)
                AuthManager.shared.saveToken(response.token)
                APIClient.shared.setToken(response.token)

                // Check if user has a manifest
                do {
                    _ = try await APIClient.shared.manifest()
                    // User has manifest, go to complete
                    withAnimation {
                        currentStep = .complete
                    }
                    // After a delay, complete onboarding
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        onComplete()
                    }
                } catch {
                    // No manifest, go to setup
                    withAnimation {
                        currentStep = .setup
                    }
                }
            } catch {
                errorMessage = "Invalid invite code. Please try again."
            }
            isLoading = false
        }
    }

    private func completeSetup() {
        // Create manifest for new user
        let contextType: ContextType = selectedInterests.contains("Trip") ? .trip :
            selectedInterests.contains("Local radar") ? .radar : .outing

        // For now, just proceed - manifest creation would be handled via API
        withAnimation {
            currentStep = .complete
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            onComplete()
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Charlie")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.white)

            Text("Your AI Travel Agent")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Invite Code Step

struct InviteCodeStepView: View {
    @Binding var code: String
    let isLoading: Bool
    let errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Enter Invite Code")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Enter your invite code to continue")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))

            TextField("Invite Code", text: $code)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            Spacer()
        }
    }
}

// MARK: - Setup Step

struct SetupStepView: View {
    @Binding var selectedCity: String
    @Binding var selectedInterests: Set<String>
    let interests: [String]
    @Binding var showCityPicker: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                Text("Set Up Your Experience")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // City Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your City")
                        .font(.headline)
                        .foregroundColor(.white)

                    Button(action: { showCityPicker = true }) {
                        HStack {
                            Text(selectedCity.isEmpty ? "Select your city" : selectedCity)
                                .foregroundColor(selectedCity.isEmpty ? .white.opacity(0.5) : .white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Interest Chips
                VStack(alignment: .leading, spacing: 12) {
                    Text("What are you interested in?")
                        .font(.headline)
                        .foregroundColor(.white)

                    FlowLayout(spacing: 12) {
                        ForEach(interests, id: \.self) { interest in
                            InterestChip(
                                title: interest,
                                isSelected: selectedInterests.contains(interest),
                                action: {
                                    if selectedInterests.contains(interest) {
                                        selectedInterests.remove(interest)
                                    } else {
                                        selectedInterests.insert(interest)
                                    }
                                }
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
        }
    }
}

// MARK: - Complete Step

struct CompleteStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Charlie is scanning for you...")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct InterestChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color(red: 99/255, green: 102/255, blue: 241/255) : Color.white.opacity(0.1))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct CityPickerView: View {
    @Binding var selectedCity: String
    let cities: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(cities, id: \.self) { city in
                Button(action: {
                    selectedCity = city
                    dismiss()
                }) {
                    HStack {
                        Text(city)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCity == city {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Flow Layout for Chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}