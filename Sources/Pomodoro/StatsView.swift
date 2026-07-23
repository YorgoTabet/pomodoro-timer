import Charts
import PomodoroCore
import PomodoroUI
import SwiftUI

/// Today, the week, and a fortnight of history.
///
/// A bar chart rather than a table: the only question worth asking of this data is
/// "am I keeping it up", and that's a shape question, not a lookup question. Exact
/// per-day numbers stay available on hover.
struct StatsView: View {

    let stats: StatsStore

    @State private var today = DayStats(day: "")
    @State private var week: (pomodoros: Int, focusSeconds: Int) = (0, 0)
    @State private var history: [DayStats] = []
    @State private var streak = 0
    @State private var confirmingReset = false
    @State private var appeared = false

    private let chartDays = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            tiles
            chart
            footer
        }
        .padding(22)
        .frame(width: 430)
        .background {
            Theme.backdrop(for: .focus)
                .opacity(0.5)
                .ignoresSafeArea()
        }
        .onAppear {
            reload()
            withAnimation(.smooth(duration: 0.5).delay(0.05)) { appeared = true }
        }
        .confirmationDialog(
            "Delete all recorded pomodoros?",
            isPresented: $confirmingReset,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                stats.reset()
                withAnimation(.smooth) { reload() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears the local history file. It can't be undone.")
        }
    }

    // MARK: - Tiles

    private var tiles: some View {
        HStack(spacing: 10) {
            tile("Today", value: "\(today.pomodoros)", caption: durationText(today.focusSeconds), phase: .focus)
            tile("7 days", value: "\(week.pomodoros)", caption: durationText(week.focusSeconds), phase: .shortBreak)
            tile("Streak", value: "\(streak)", caption: streak == 1 ? "day" : "days", phase: .longBreak)
        }
        .glassGroup(spacing: 10)
    }

    private func tile(_ title: String, value: String, caption: String, phase: Phase) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(Theme.tint(for: phase))

            Text(value)
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(caption)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(Theme.tint(for: phase).opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .glassPanel(in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    // MARK: - Chart

    @ViewBuilder
    private var chart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last \(chartDays) days")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            if history.allSatisfy({ $0.pomodoros == 0 }) {
                emptyState
            } else {
                Chart(history, id: \.day) { day in
                    BarMark(
                        x: .value("Day", shortLabel(day.day)),
                        // Bars grow in on appear — the one moment where motion
                        // carries meaning here, since it draws the eye along the trend.
                        y: .value("Pomodoros", appeared ? day.pomodoros : 0)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.highlight(for: .focus), Theme.tint(for: .focus)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                    .annotation(position: .top, spacing: 3) {
                        if day.pomodoros > 0 {
                            Text("\(day.pomodoros)")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.primary.opacity(0.08))
                        AxisValueLabel().font(.system(size: 9))
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.system(size: 8))
                    }
                }
                .frame(height: 124)
                .animation(.smooth(duration: 0.7), value: appeared)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Theme.tint(for: .focus).opacity(0.6))
            Text("No completed pomodoros yet")
                .font(.system(size: 12, weight: .medium))
            Text("Finish a focus session and it'll show up here.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 124)
        .glassPanel(in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("Stored locally in Application Support. Never leaves this Mac.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Reset…", role: .destructive) { confirmingReset = true }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
        }
    }

    // MARK: - Data

    private func shortLabel(_ day: String) -> String {
        // "2026-07-23" -> "07/23", which is short enough for 14 x-axis slots.
        String(day.dropFirst(5)).replacingOccurrences(of: "-", with: "/")
    }

    private func durationText(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m focused" : "\(minutes)m focused"
    }

    private func reload() {
        today = stats.stats()
        week = stats.rollingTotals(days: 7)

        // Oldest first, so the chart reads left-to-right as time passing, and
        // including empty days so gaps are visible rather than silently closed up.
        let calendar = Calendar.current
        history = (0..<chartDays).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return stats.stats(for: day)
        }

        streak = currentStreak(calendar: calendar)
    }

    /// Consecutive days ending today with at least one pomodoro. Today not counting
    /// yet doesn't break a streak — it just hasn't extended it, so the count starts
    /// from yesterday when today is still empty.
    private func currentStreak(calendar: Calendar) -> Int {
        var count = 0
        var offset = stats.stats().pomodoros > 0 ? 0 : 1
        while offset < 365 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()),
                  stats.stats(for: day).pomodoros > 0
            else { break }
            count += 1
            offset += 1
        }
        return count
    }
}
