import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: FastingStore
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.black, Color(.systemGray6)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header
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
                        .foregroundStyle(.white)
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
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Plan")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(store.selectedPlan?.name ?? "None")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            if let plan = store.selectedPlan {
                Text("Target: \(plan.fastingHours)h fasting, \(plan.eatingHours)h eating")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                        .foregroundStyle(.secondary)
                }
                progressView
                Text(countdownString())
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            } else {
                Text("Ready to fast")
                    .font(.headline)
                    .foregroundStyle(.white)
                if let plan = store.selectedPlan {
                    Text("Target: \(plan.fastingHours) hours")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var progressView: some View {
        let progress = store.fastProgress()
        return ZStack {
            Circle()
                .stroke(Color(.systemGray2), lineWidth: 12)
                .frame(width: 220, height: 220)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(AngularGradient(gradient: Gradient(colors: [.purple, .teal]), center: .center), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 220, height: 220)
                .animation(.easeInOut(duration: 0.3), value: progress)
            VStack {
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.title)
                    .foregroundStyle(.white)
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
                .tint(.purple)
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
