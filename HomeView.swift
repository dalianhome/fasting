import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: FastingStore
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showSettings = false
    @State private var now = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                store.theme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        highlightCard
                        timerCard
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("Cyberism Fasting App")
            .toolbar {
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .sheet(isPresented: $showSettings) {
                settingsSheet
            }
            .onReceive(timer) { _ in
                now = Date()
                if !store.isFasting {
                    timer.upstream.connect().cancel()
                }
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(store.theme.cardGradient)
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.screen)
                )
                .shadow(color: Color.cyan.opacity(0.35), radius: 18, x: 0, y: 12)

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Plan")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(store.selectedPlan?.name ?? "None")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    if let plan = store.selectedPlan {
                        Text("Target: \(plan.fastingHours)h fast · \(plan.eatingHours)h eat")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                Spacer()
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                    )
            }
            .padding()
        }
    }

    private var highlightCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Keep the momentum ✨")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(store.currentStreak())-day streak • \(store.totalSuccessfulFasts()) goals met")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white)
                .padding(10)
                .background(Circle().fill(store.theme.highlightAccent))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(store.theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(store.theme.surfaceStroke))
                .shadow(color: Color.cyan.opacity(0.35), radius: 16, x: 0, y: 12)
        )
    }

    private var timerCard: some View {
        VStack(spacing: 16) {
            if store.isFasting {
                Text("Fasting in progress")
                    .font(.headline)
                    .foregroundStyle(.white)
                if let start = store.fastStartDate, let end = store.fastEndDate {
                    Text("Started \(timeString(from: start)) • Ends \(timeString(from: end))")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                progressView
                Text(countdownString())
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(store.theme.actionTint)
            } else {
                Text("Ready to fast")
                    .font(.headline)
                    .foregroundStyle(.white)
                if let plan = store.selectedPlan {
                    Text("Target: \(plan.fastingHours) hours")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(store.theme.actionTint)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(store.theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(store.theme.surfaceStroke)
                )
                .shadow(color: Color.purple.opacity(0.4), radius: 20, x: 0, y: 14)
        )
    }

    private var progressView: some View {
        let progress = store.fastProgress(asOf: now)
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 12)
                .frame(width: 220, height: 220)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    store.theme.progressGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 220, height: 220)
                .animation(.easeInOut(duration: 0.3), value: progress)
            VStack {
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.title)
                    .foregroundStyle(.white)
                Text("complete")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.vertical)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if store.isFasting {
                Button(role: .destructive) {
                    store.stopFast()
                } label: {
                    Text("Stop Fasting")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.9))
            } else {
                Button {
                    store.startFast()
                    timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                } label: {
                    Text("Start Fasting")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(store.theme.actionTint)
                .disabled(store.selectedPlan == nil)
            }
        }
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: Binding(get: { store.theme }, set: { store.setTheme($0) })) {
                        ForEach(AppTheme.allCases) { theme in
                            HStack {
                                Circle()
                                    .fill(theme.cardGradient)
                                    .frame(width: 18, height: 18)
                                Text(theme.displayName)
                            }
                            .tag(theme)
                        }
                    }
                }

                Section(header: Text("Preferences")) {
                    Toggle("Auto start after eating window", isOn: $store.autoStartAfterEating)
                    Toggle("Daily reminder at 8PM", isOn: $store.dailyReminderEnabled)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showSettings = false }
                }
            }
        }
    }

    private func countdownString() -> String {
        let remaining = store.remainingTime(asOf: now)
        if remaining <= 0 { return "Goal reached" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
        .environmentObject(FastingStore())
}
