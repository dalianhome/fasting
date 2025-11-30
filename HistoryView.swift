import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: FastingStore

    @State private var lastUpdated = Date()

    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.09, blue: 0.18),
            Color(red: 0.08, green: 0.09, blue: 0.29),
            Color(red: 0.10, green: 0.16, blue: 0.42),
            Color(red: 0.06, green: 0.22, blue: 0.46)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let cardGradient = LinearGradient(
        colors: [
            Color(red: 0.24, green: 0.75, blue: 0.96),
            Color(red: 0.47, green: 0.34, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let accentGlow = LinearGradient(
        colors: [
            Color(red: 0.43, green: 1.0, blue: 0.87).opacity(0.85),
            Color(red: 0.39, green: 0.74, blue: 1.0).opacity(0.85)
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
                        } else {
                            ForEach(Array(store.history.enumerated()), id: \.element.id) { _, fast in
                                historyRow(fast)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteFast(fast)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .navigationTitle("History")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        timestampBadge
                    }
                }
            }
            .onAppear { markUpdated() }
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
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardGradient.opacity(0.95))
        )
        .shadow(color: Color.cyan.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    private func historyRow(_ fast: CompletedFast) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(fast.isSuccessful ? Color.green.opacity(0.9) : Color.red.opacity(0.8))
                .frame(width: 12, height: 12)
            VStack(alignment: .leading) {
                Text(dateString(from: fast.startDate))
                    .font(.headline.weight(.semibold))
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentGlow.opacity(0.06))
                        .blur(radius: 16)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08))
        )
        .shadow(color: Color.cyan.opacity(0.4), radius: 14, x: 0, y: 10)
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.compactMap { offset in
            store.history.indices.contains(offset) ? store.history[offset].id : nil
        }

        guard !ids.isEmpty else { return }

        withAnimation {
            ids.forEach { store.deleteFast(id: $0) }
            markUpdated()
        }
    }

    private func deleteFast(_ fast: CompletedFast) {
        withAnimation {
            store.deleteFast(fast)
            markUpdated()
        }
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private var timestampBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.arrow.circlepath")
            Text(timestampString(from: lastUpdated))
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThickMaterial.opacity(0.35))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.25))
        )
    }

    private func timestampString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func markUpdated() {
        lastUpdated = Date()
    }
}

#Preview {
    HistoryView()
        .environmentObject(FastingStore())
}
