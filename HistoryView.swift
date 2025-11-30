import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: FastingStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List {
                    statsSection

                    Section(header: Text("Past Fasts")) {
                        if store.history.isEmpty {
                            Text("No fasts recorded yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(store.history) { fast in
                                historyRow(fast)
                                    .listRowBackground(Color(.secondarySystemBackground).opacity(0.45))
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("History")
        }
        .preferredColorScheme(.dark)
    }

    private var statsSection: some View {
        Section(header: Text("Overview")) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(store.totalFasts())")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Successful")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(store.totalSuccessfulFasts())")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(store.currentStreak()) days")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func historyRow(_ fast: CompletedFast) -> some View {
        HStack {
            Circle()
                .fill(fast.isSuccessful ? Color.green : Color.red.opacity(0.7))
                .frame(width: 12, height: 12)
            VStack(alignment: .leading) {
                Text(dateString(from: fast.startDate))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(fast.planName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(format: "%.1fh", fast.durationHours))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(fast.isSuccessful ? "Reached goal" : "Stopped early")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
        .environmentObject(FastingStore())
}
