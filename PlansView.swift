import SwiftUI

struct PlansView: View {
    @EnvironmentObject var store: FastingStore
    @State private var showCustomPlan = false
    @State private var fastingHours: Int = 16
    @State private var eatingHours: Int = 8

    private var orderedPlans: [FastingPlan] {
        store.availablePlans.sorted { $0.fastingHours < $1.fastingHours }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Pick a plan that fits your day")
                        .font(.headline)
                        .padding(.horizontal)

                    if let selected = store.selectedPlan {
                        planCard(selected, subtitle: "Currently using", accent: Color(red: 0.99, green: 0.52, blue: 0.11))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Other options")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ForEach(orderedPlans.filter { $0.id != store.selectedPlan?.id }) { plan in
                            planCard(plan, subtitle: "\(plan.fastingHours)h fast · \(plan.eatingHours)h eat", accent: Color(red: 0.0, green: 0.7, blue: 0.86))
                        }
                    }
                    .padding(.horizontal)

                    Button {
                        showCustomPlan = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create custom plan")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Plans")
            .sheet(isPresented: $showCustomPlan) {
                customPlanSheet
            }
        }
    }

    @ViewBuilder
    private func planCard(_ plan: FastingPlan, subtitle: String, accent: Color) -> some View {
        Button {
            store.selectPlan(plan)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(plan.fastingHours)h")
                        .font(.title3.bold())
                        .foregroundStyle(accent)
                    Text("fast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if store.selectedPlan == plan {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(accent)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
            )
        }
    }

    private var customPlanSheet: some View {
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
                    Text("Aim for roughly 24 hours in total to keep a gentle rhythm.")
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

#Preview {
    PlansView()
        .environmentObject(FastingStore())
}
