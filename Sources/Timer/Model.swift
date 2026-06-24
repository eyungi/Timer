import Foundation
import AppKit
import SwiftUI
import UserNotifications

// MARK: - Timer mode

enum TimerMode {
    case focus, shortBreak, longBreak

    var title: String {
        switch self {
        case .focus: return "집중"
        case .shortBreak: return "휴식"
        case .longBreak: return "긴 휴식"
        }
    }

    var color: Color {
        switch self {
        case .focus: return .orange
        case .shortBreak: return .green
        case .longBreak: return .teal
        }
    }
}

// MARK: - Stats persistence

struct SessionRecord: Codable {
    let date: Date
    let minutes: Int
    /// 완료한 세션이면 true. 되돌리기로 합산한 부분 시간은 false (세션 수엔 안 들어감).
    /// 옛 데이터는 이 키가 없으므로 nil → 세션으로 간주.
    var isSession: Bool? = nil
}

final class StatsStore: ObservableObject {
    @Published private(set) var records: [SessionRecord] = []
    private let key = "completedSessions"

    init() { load() }

    func record(minutes: Int) {
        records.append(SessionRecord(date: Date(), minutes: minutes, isSession: true))
        save()
    }

    /// 되돌리기로 흘려보낸 부분 시간을 합산한다. 시간만 더하고 세션 수엔 넣지 않는다.
    func recordPartial(minutes: Int) {
        guard minutes > 0 else { return }
        records.append(SessionRecord(date: Date(), minutes: minutes, isSession: false))
        save()
    }

    private func countsAsSession(_ r: SessionRecord) -> Bool { r.isSession ?? true }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data) else { return }
        records = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: Derived stats

    var todayMinutes: Int {
        let cal = Calendar.current
        return records.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.minutes }
    }

    var todaySessions: Int {
        let cal = Calendar.current
        return records.filter { cal.isDateInToday($0.date) && countsAsSession($0) }.count
    }

    var weekMinutes: Int {
        let cal = Calendar.current
        return records.filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.minutes }
    }

    var totalSessions: Int { records.filter { countsAsSession($0) }.count }

    /// Minutes per day for the last 7 days, oldest first (today last).
    var last7Days: [(label: String, minutes: Int)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "E"
        let today = cal.startOfDay(for: Date())
        // 가장 오래된 날(6일 전)이 왼쪽, 오늘이 오른쪽 끝에 오도록 시간순 정렬.
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let minutes = records
                .filter { cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.minutes }
            return (fmt.string(from: day), minutes)
        }
    }
}

// MARK: - Timer model

final class TimerModel: ObservableObject {
    let stats = StatsStore()

    @Published var mode: TimerMode = .focus
    @Published var remaining: Int           // seconds left in current phase
    @Published var isRunning = false
    @Published private(set) var completedFocusCount = 0  // toward the next long break

    // Custom durations (minutes), persisted.
    @Published var focusMinutes: Int      { didSet { persist(); syncIfIdle(.focus, oldValue) } }
    @Published var shortBreakMinutes: Int { didSet { persist(); syncIfIdle(.shortBreak, oldValue) } }
    @Published var longBreakMinutes: Int  { didSet { persist(); syncIfIdle(.longBreak, oldValue) } }
    @Published var roundsBeforeLongBreak: Int { didSet { persist() } }

    private var timer: Timer?

    init() {
        let d = UserDefaults.standard
        focusMinutes = d.object(forKey: "focusMinutes") as? Int ?? 25
        shortBreakMinutes = d.object(forKey: "shortBreakMinutes") as? Int ?? 5
        longBreakMinutes = d.object(forKey: "longBreakMinutes") as? Int ?? 15
        roundsBeforeLongBreak = d.object(forKey: "roundsBeforeLongBreak") as? Int ?? 4
        remaining = (d.object(forKey: "focusMinutes") as? Int ?? 25) * 60
    }

    // MARK: Controls

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        // 집중 단계에서 흘러간 시간(전체-남은)을 분 단위로 내림해 오늘 작업에 합산.
        if mode == .focus {
            let elapsedMinutes = (duration(for: .focus) - remaining) / 60
            stats.recordPartial(minutes: elapsedMinutes)
        }
        pause()
        remaining = duration(for: mode)
    }

    /// Move to the next phase without recording or auto-starting (manual skip).
    func skip() {
        pause()
        advance(recordFocus: false)
    }

    func progress() -> Double {
        let total = duration(for: mode)
        guard total > 0 else { return 0 }
        return 1 - Double(remaining) / Double(total)
    }

    var dotsFilled: Int {
        roundsBeforeLongBreak > 0 ? completedFocusCount % roundsBeforeLongBreak : 0
    }

    // MARK: Internals

    private func tick() {
        if remaining > 0 { remaining -= 1 }
        if remaining == 0 { complete() }
    }

    private func complete() {
        pause()
        NSSound(named: "Glass")?.play()
        let finished = mode
        advance(recordFocus: true)
        // 자동으로 다음 단계를 시작하지 않는다. 알림을 보내고 멈춰서 대기하며,
        // 사용자가 직접 재생 버튼을 눌러야 다음 단계가 시작된다.
        notifyPhaseChange(finished: finished, next: mode)
    }

    /// 한 단계가 끝났을 때 시스템 알림을 띄운다.
    private func notifyPhaseChange(finished: TimerMode, next: TimerMode) {
        // .app 번들로 실행할 때만 알림 사용 (bare executable 에선 크래시 방지).
        guard Bundle.main.bundleIdentifier != nil else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(finished.title) 완료"
        content.body = "\(next.title) 시간이에요. 시작하려면 재생 버튼을 누르세요."
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func advance(recordFocus: Bool) {
        if mode == .focus {
            if recordFocus {
                stats.record(minutes: focusMinutes)
                completedFocusCount += 1
            }
            let needsLong = completedFocusCount > 0
                && roundsBeforeLongBreak > 0
                && completedFocusCount % roundsBeforeLongBreak == 0
            mode = needsLong ? .longBreak : .shortBreak
        } else {
            mode = .focus
        }
        remaining = duration(for: mode)
    }

    private func duration(for mode: TimerMode) -> Int {
        switch mode {
        case .focus: return focusMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }

    /// If the edited duration belongs to the current idle phase, reflect it live.
    private func syncIfIdle(_ edited: TimerMode, _ oldValue: Int) {
        if mode == edited && !isRunning {
            remaining = duration(for: mode)
        }
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(focusMinutes, forKey: "focusMinutes")
        d.set(shortBreakMinutes, forKey: "shortBreakMinutes")
        d.set(longBreakMinutes, forKey: "longBreakMinutes")
        d.set(roundsBeforeLongBreak, forKey: "roundsBeforeLongBreak")
    }
}
