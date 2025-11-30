import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: FastingStore
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(red: 0.92, green: 0.97, blue: 1.0), Color.white]), startPoint: .top, endPoint: .bottom)
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
            .navigationTitle("Fasting Buddy")
            .toolbar {
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.primary)
                }
            }
            .sheet(isPresented: $showSettings) {
                settingsSheet
            }
            .onReceive(timer) { _ in
                if !store.isFasting {
                    timer.upstream.connect().cancel()
                }
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 0.73, green: 0.89, blue: 1.0), Color(red: 0.61, green: 0.82, blue: 1.0)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Plan")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.8))
                    Text(store.selectedPlan?.name ?? "None")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    if let plan = store.selectedPlan {
                        Text("Target: \(plan.fastingHours)h fast · \(plan.eatingHours)h eat")
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.75))
                    }
                }
                Spacer()
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(Color(red: 0.08, green: 0.45, blue: 0.82)))
            }
            .padding()
        }
    }

    private var highlightCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Keep the momentum ✨")
                    .font(.headline)
                Text("\(store.currentStreak())-day streak • \(store.totalSuccessfulFasts()) goals met")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white)
                .padding(10)
                .background(Circle().fill(Color.orange))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6))
    }

    private var timerCard: some View {
        VStack(spacing: 16) {
            if store.isFasting {
                Text("Fasting in progress")
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let start = store.fastStartDate, let end = store.fastEndDate {
                    Text("Started \(timeString(from: start)) • Ends \(timeString(from: end))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                progressView
                Text(countdownString())
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.55))
            } else {
                Text("Ready to fast")
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let plan = store.selectedPlan {
                    Text("Target: \(plan.fastingHours) hours")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.12, green: 0.3, blue: 0.55))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
    }

    private var progressView: some View {
        let progress = store.fastProgress()
        return ZStack {
            Circle()
                .stroke(Color(red: 0.9, green: 0.93, blue: 0.96), lineWidth: 12)
                .frame(width: 220, height: 220)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(AngularGradient(gradient: Gradient(colors: [Color(red: 0.0, green: 0.7, blue: 0.86), Color(red: 0.99, green: 0.52, blue: 0.11)]), center: .center), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 220, height: 220)
                .animation(.easeInOut(duration: 0.3), value: progress)
            VStack {
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.title)
                    .foregroundStyle(.primary)
                Text("complete")
                    .foregroundStyle(.secondary)
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
                .tint(.red)
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
                .tint(Color(red: 0.99, green: 0.52, blue: 0.11))
                .disabled(store.selectedPlan == nil)
            }
        }
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
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
        let remaining = store.remainingTime()
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
