import SwiftUI
import AppKit

// MARK: - Main compact view

struct ContentView: View {
    @EnvironmentObject var model: TimerModel
    @State private var showStats = false
    @State private var showSettings = false
    var onClose: () -> Void = {}

    private var timeString: String {
        String(format: "%02d:%02d", model.remaining / 60, model.remaining % 60)
    }

    var body: some View {
        VStack(spacing: 10) {
            ring
            dots
            controls
        }
        .padding(14)
        .frame(width: 184)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .background(.quaternary, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(6)
            .help("창 닫기 (Dock 아이콘으로 다시 열기)")
        }
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 7)
            Circle()
                .trim(from: 0, to: model.progress())
                .stroke(model.mode.color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: model.remaining)
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(model.mode.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 104, height: 104)
    }

    private var dots: some View {
        HStack(spacing: 5) {
            ForEach(0..<max(model.roundsBeforeLongBreak, 1), id: \.self) { i in
                Circle()
                    .fill(i < model.dotsFilled ? model.mode.color : Color.secondary.opacity(0.25))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            iconButton(model.isRunning ? "pause.fill" : "play.fill", size: 18) {
                model.toggle()
            }
            iconButton("arrow.counterclockwise", size: 15) { model.reset() }
            iconButton("chart.bar.fill", size: 15) { showStats.toggle() }
                .popover(isPresented: $showStats, arrowEdge: .bottom) {
                    StatsView().environmentObject(model)
                }
            iconButton("gearshape.fill", size: 15) { showSettings.toggle() }
                .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                    SettingsView().environmentObject(model)
                }
        }
    }

    private func iconButton(_ name: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: size))
                .foregroundStyle(.primary)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stats popover

struct StatsView: View {
    @EnvironmentObject var model: TimerModel
    private var stats: StatsStore { model.stats }

    private func hm(_ minutes: Int) -> String {
        minutes >= 60 ? "\(minutes / 60)시간 \(minutes % 60)분" : "\(minutes)분"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("통계").font(.headline)

            HStack(spacing: 18) {
                stat("오늘", hm(stats.todayMinutes), "\(stats.todaySessions)세션")
                stat("이번 주", hm(stats.weekMinutes), "총 \(stats.totalSessions)세션")
            }

            Divider()

            Text("최근 7일").font(.caption).foregroundStyle(.secondary)
            chart
        }
        .padding(16)
        .frame(width: 240)
    }

    private func stat(_ title: String, _ value: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.system(.title3, design: .rounded)).fontWeight(.semibold)
            Text(sub).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chart: some View {
        let data = stats.last7Days
        let maxMin = max(data.map(\.minutes).max() ?? 0, 1)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(day.minutes > 0 ? Color.orange : Color.secondary.opacity(0.2))
                        .frame(height: max(4, CGFloat(day.minutes) / CGFloat(maxMin) * 52))
                    Text(day.label).font(.system(size: 9)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 70)
    }
}

// MARK: - Settings popover

struct SettingsView: View {
    @EnvironmentObject var model: TimerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("설정").font(.headline)

            stepperRow("집중 시간", value: $model.focusMinutes, range: 1...120, unit: "분")
            stepperRow("휴식 시간", value: $model.shortBreakMinutes, range: 1...60, unit: "분")
            stepperRow("긴 휴식", value: $model.longBreakMinutes, range: 1...60, unit: "분")
            stepperRow("긴 휴식까지", value: $model.roundsBeforeLongBreak, range: 1...10, unit: "회")

            Divider()

            HStack(spacing: 8) {
                Button {
                    model.skip()
                } label: {
                    Label("건너뛰기", systemImage: "forward.end.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .help("현재 단계를 끝내고 다음 단계로")

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("종료", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .controlSize(.large)
        }
        .padding(16)
        .frame(width: 240)
    }

    private func stepperRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        func set(_ v: Int) {
            let next = min(max(v, range.lowerBound), range.upperBound)
            if next != value.wrappedValue { value.wrappedValue = next }
        }
        return HStack {
            Text(title).font(.callout)
            Spacer()
            HStack(spacing: 6) {
                Text("\(value.wrappedValue)\(unit)")
                    .font(.callout.monospacedDigit())
                    .frame(minWidth: 36, alignment: .trailing)
                    .overlay(ScrollAdjust { step in set(value.wrappedValue + step) })
                Divider().frame(height: 18)
                VStack(spacing: 0) {
                    chevron("chevron.up") { set(value.wrappedValue + 1) }
                    chevron("chevron.down") { set(value.wrappedValue - 1) }
                }
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            .help("스크롤하거나 ▲▼ 버튼으로 조절")
        }
    }

    private func chevron(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scroll-to-adjust

/// Transparent overlay that turns scroll-wheel / two-finger scroll into ±1 steps.
private struct ScrollAdjust: NSViewRepresentable {
    let onStep: (Int) -> Void

    func makeNSView(context: Context) -> NSView { Catcher(onStep) }
    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? Catcher)?.onStep = onStep
    }

    final class Catcher: NSView {
        var onStep: (Int) -> Void
        private var accumulated: CGFloat = 0

        init(_ onStep: @escaping (Int) -> Void) {
            self.onStep = onStep
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) unused") }

        override func scrollWheel(with event: NSEvent) {
            // Normalize so physical "scroll up" always increases, regardless of
            // the system's natural-scrolling setting.
            var delta = event.scrollingDeltaY
            if event.isDirectionInvertedFromDevice { delta = -delta }

            // Higher threshold = lower sensitivity. Trackpad deltas are in points,
            // mouse-wheel deltas are in lines (~1 per notch), so scale accordingly.
            let threshold: CGFloat = event.hasPreciseScrollingDeltas ? 30 : 2
            accumulated += delta
            while abs(accumulated) >= threshold {
                onStep(accumulated > 0 ? 1 : -1)
                accumulated += accumulated > 0 ? -threshold : threshold
            }
        }
    }
}
