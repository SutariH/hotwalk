import SwiftUI

struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HotGirlStepsViewModel
    @State private var tempGoal: String
    @State private var selectedPreset: Int?
    @State private var isEditing = false
    
    private let presets = [5000, 7500, 10000, 12500, 15000]
    
    init(viewModel: HotGirlStepsViewModel) {
        self.viewModel = viewModel
        _tempGoal = State(initialValue: String(viewModel.dailyGoal))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 44/255, green: 8/255, blue: 52/255),
                    Color(red: 0.4, green: 0.2, blue: 0.4),
                    Color(hue: 0.83, saturation: 0.4, brightness: 0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Close Button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)

                // Header
                VStack(spacing: 12) {
                    Text("Pick your power walk number")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Daily Step Goal")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 8)

                // Quick Presets
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Presets")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ForEach(presets[0...2], id: \.self) { preset in
                                presetButton(preset: preset)
                            }
                        }
                        HStack(spacing: 12) {
                            ForEach(presets[3...4], id: \.self) { preset in
                                presetButton(preset: preset)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal)

                // Custom Goal Input
                VStack(alignment: .leading, spacing: 16) {
                    Text("Manifest Your Steps")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    HStack {
                        TextField("Type your fierce number here...", text: $tempGoal)
                            .keyboardType(.numberPad)
                            .font(.system(size: 18))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(Color(red: 44/255, green: 8/255, blue: 52/255))
                            .onChange(of: tempGoal) { newValue in
                                if let value = Int(newValue), presets.contains(value) {
                                    selectedPreset = value
                                } else {
                                    selectedPreset = nil
                                }
                                isEditing = true
                            }
                        Text("steps")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                // Save Button
                VStack(spacing: 12) {
                    Button(action: saveGoal) {
                        Text("SAVE GOAL")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(tempGoal.isEmpty || Int(tempGoal) == nil)
                    .opacity(tempGoal.isEmpty || Int(tempGoal) == nil ? 0.6 : 1)
                    Text("Your future self is already proud")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 24)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func saveGoal() {
        if let newGoal = Int(tempGoal), newGoal > 0 {
            viewModel.dailyGoal = newGoal
            dismiss()
        }
    }
    
    private func presetLabel(for preset: Int) -> String {
        switch preset {
        case 5000: return "Soft Girl Mode"
        case 7500: return "Casual Queen"
        case 10000: return "Hot Girl Classic"
        case 12500: return "Overachiever Alert"
        case 15000: return "Certified Legend"
        default: return ""
        }
    }
    
    private func presetButton(preset: Int) -> some View {
        Button(action: {
            withAnimation {
                selectedPreset = preset
                tempGoal = String(preset)
                isEditing = false
            }
        }) {
            VStack(spacing: 6) {
                Text("\(preset)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(selectedPreset == preset ? .white : .white.opacity(0.8))
                
                Text(presetLabel(for: preset))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedPreset == preset ? Color.purple : Color.white.opacity(0.1))
            )
        }
    }
}

#Preview {
    GoalEditorView(viewModel: HotGirlStepsViewModel())
} 