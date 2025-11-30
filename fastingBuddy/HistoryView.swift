import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: FastingStore

    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.08, blue: 0.14),
            Color(red: 0.12, green: 0.09, blue: 0.26),
            Color(red: 0.21, green: 0.09, blue: 0.38)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let cardGradient = LinearGradient(
        colors: [
            Color(red: 0.63, green: 0.21, blue: 0.91),
            Color(red: 0.21, green: 0.78, blue: 0.93)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let accentGlow = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.58, blue: 1.0).opacity(0.9),
            Color(red: 0.37, green: 0.96, blue: 0.96).opacity(0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

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
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(Array(store.history.enumerated()), id: \.element.id) { _, fast in
                                historyRow(fast)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .navigationTitle("History")
            }
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your streak so far")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 16) {
                statPill(title: "Total", value: "\(store.totalFasts())")
                statPill(title: "Successful", value: "\(store.totalSuccessfulFasts())")
                statPill(title: "Streak", value: "\(store.currentStreak()) days")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25))
        )
        .shadow(color: Color.blue.opacity(0.35), radius: 20, x: 0, y: 12)
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(cardGradient)
        )
        .shadow(color: Color.cyan.opacity(0.35), radius: 10, x: 0, y: 8)
    }

    private func historyRow(_ fast: CompletedFast) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(fast.isSuccessful ? Color(hue: 0.34, saturation: 0.92, brightness: 0.86) : Color(red: 1.0, green: 0.25, blue: 0.45))
                .frame(width: 12, height: 12)
            VStack(alignment: .leading) {
                Text(dateString(from: fast.startDate))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(fast.planName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(format: "%.1fh", fast.durationHours))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(fast.isSuccessful ? "Reached goal" : "Stopped early")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentGlow.opacity(0.06))
                        .blur(radius: 18)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14))
        )
        .shadow(color: Color.cyan.opacity(0.4), radius: 14, x: 0, y: 10)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                delete(id: fast.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func delete(id: UUID) {
        withAnimation { store.deleteFast(id: id) }
    }

    private func delete(at offsets: IndexSet) {
        withAnimation { store.deleteFast(at: offsets) }
    }
}

#Preview {
    HistoryView()
        .environmentObject(FastingStore())
}
