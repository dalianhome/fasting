import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: FastingStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statsCard
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                Section("Past fasts") {
                    if store.history.isEmpty {
                        Text("No fasts recorded yet")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(store.history) { fast in
                            historyRow(fast)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        store.deleteFast(fast)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("History")
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your streak so far")
                .font(.headline)
            HStack(spacing: 16) {
                statPill(title: "Total", value: "\(store.totalFasts())")
                statPill(title: "Successful", value: "\(store.totalSuccessfulFasts())")
                statPill(title: "Streak", value: "\(store.currentStreak()) days")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6))
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(red: 0.94, green: 0.97, blue: 1.0)))
    }

    private func historyRow(_ fast: CompletedFast) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(fast.isSuccessful ? Color.green : Color.red.opacity(0.7))
                .frame(width: 12, height: 12)
            VStack(alignment: .leading) {
                Text(dateString(from: fast.startDate))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(fast.planName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(format: "%.1fh", fast.durationHours))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(fast.isSuccessful ? "Reached goal" : "Stopped early")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 5))
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
