import PomodoroCore
import SwiftUI

/// Today / this week totals plus a short history. Read-only apart from Reset.
struct StatsView: View {

    let stats: StatsStore

    @State private var today = DayStats(day: "")
    @State private var week: (pomodoros: Int, focusSeconds: Int) = (0, 0)
    @State private var history: [DayStats] = []
    @State private var confirmingReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                tile("Today", pomodoros: today.pomodoros, seconds: today.focusSeconds)
                tile("Last 7 days", pomodoros: week.pomodoros, seconds: week.focusSeconds)
            }

            if history.isEmpty {
                Text("No completed pomodoros yet. Finish a focus session and it will show up here.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("History")
                    .font(.headline)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(history, id: \.day) { day in
                            HStack {
                                Text(day.day)
                                    .monospacedDigit()
                                Spacer()
                                Text("\(day.pomodoros) 🍅")
                                Text(durationText(day.focusSeconds))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 72, alignment: .trailing)
                            }
                            .padding(.vertical, 5)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 180)
            }

            HStack {
                Spacer()
                Button("Reset stats…", role: .destructive) { confirmingReset = true }
            }
        }
        .padding(20)
        .frame(width: 380)
        .onAppear(perform: reload)
        .confirmationDialog(
            "Delete all recorded pomodoros?",
            isPresented: $confirmingReset,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                stats.reset()
                reload()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears the local history file. It can't be undone.")
        }
    }

    private func tile(_ title: String, pomodoros: Int, seconds: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(pomodoros)")
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .monospacedDigit()
            Text("\(durationText(seconds)) focused")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private func durationText(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    private func reload() {
        today = stats.stats()
        week = stats.rollingTotals(days: 7)
        history = stats.recentDays(limit: 30)
    }
}
