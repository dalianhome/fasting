import SwiftUI

struct PlansView: View {
    @EnvironmentObject var store: FastingStore
    @State private var showCustomPlan = false
    @State private var fastingHours: Int = 16
    @State private var eatingHours: Int = 8

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List {
                    Section(header: Text("Presets")) {
                        ForEach(store.availablePlans) { plan in
                            planRow(plan)
                                .listRowBackground(Color(.secondarySystemBackground).opacity(0.5))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showCustomPlan = true
                    } label: {
                        Label("Create Custom Plan", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                }
            }
            .sheet(isPresented: $showCustomPlan) {
                NavigationStack {
                    Form {
                        Section(header: Text("Fasting window")) {
                            Stepper(value: $fastingHours, in: 10...22) {
                                Text("Fasting: \(fastingHours) hours")
                            }
                        }
                        Section(header: Text("Eating window")) {
                            Stepper(value: $eatingHours, in: 2...14) {
                                Text("Eating: \(eatingHours) hours")
                            }
                        }
                        Section {
                            Text("Total day: \(fastingHours + eatingHours) hours")
                                .foregroundStyle((fastingHours + eatingHours) == 24 ? .green : .secondary)
                            Text("We recommend keeping around 24 hours total.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("Custom Plan")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showCustomPlan = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                store.addCustomPlan(fastingHours: fastingHours, eatingHours: eatingHours)
                                showCustomPlan = false
                            }
                            .disabled(fastingHours <= 0 || eatingHours <= 0 || (fastingHours + eatingHours) < 20 || (fastingHours + eatingHours) > 28)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func planRow(_ plan: FastingPlan) -> some View {
        Button {
            store.selectPlan(plan)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(plan.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(plan.fastingHours)h fasting, \(plan.eatingHours)h eating")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if store.selectedPlan == plan {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.purple)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    PlansView()
        .environmentObject(FastingStore())
}
