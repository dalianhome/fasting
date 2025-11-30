import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: FastingStore

    @State private var lastUpdated = Date()

    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.06, blue: 0.12),
            Color(red: 0.11, green: 0.09, blue: 0.25),
            Color(red: 0.18, green: 0.12, blue: 0.34)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let cardGradient = LinearGradient(
        colors: [
            Color(red: 0.38, green: 0.17, blue: 0.66),
            Color(red: 0.16, green: 0.72, blue: 0.86)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let accentGlow = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.84, blue: 1.0).opacity(0.7),
            Color(red: 0.93, green: 0.52, blue: 0.98).opacity(0.65)
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
                        if let syncedAt = store.lastSyncedAt {
                            syncInfoRow(for: syncedAt)
                        }
                        if store.history.isEmpty {
                            Text("No fasts recorded yet")
                                .foregroundStyle(.white.opacity(0.75))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 12)
                        } else {
                            ForEach(store.history) { fast in
                                historyRow(fast)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
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
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15))
        )
        .shadow(color: Color.purple.opacity(0.28), radius: 18, x: 0, y: 12)
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
                .fill(cardGradient.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18))
        )
        .shadow(color: Color.cyan.opacity(0.32), radius: 14, x: 0, y: 10)
    }

    private func historyRow(_ fast: CompletedFast) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(fast.isSuccessful ? Color(hue: 0.34, saturation: 0.92, brightness: 0.86) : Color(red: 1.0, green: 0.25, blue: 0.45))
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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentGlow.opacity(0.18))
                        .blur(radius: 14)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15))
        )
        .shadow(color: Color.black.opacity(0.32), radius: 16, x: 0, y: 10)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                delete(id: fast.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func delete(id: UUID) {
        withAnimation {
            store.deleteFast(id: id)
            markUpdated()
        }
    }

    private func delete(at offsets: IndexSet) {
        guard !offsets.isEmpty else { return }
        withAnimation {
            store.deleteFast(at: offsets)
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

    private func syncInfoRow(for date: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.checkmark")
                .foregroundStyle(.green.opacity(0.85))
            Text("Saved \(timestampString(from: date))")
                .foregroundStyle(.white.opacity(0.8))
                .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func markUpdated() {
        lastUpdated = store.lastSyncedAt ?? Date()
    }
}

#Preview {
    HistoryView()
        .environmentObject(FastingStore())
}
