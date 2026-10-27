import Foundation

@MainActor
class SupabaseSync {
    static let shared = SupabaseSync()

    private weak var timerManager: TimerManager?
    private var pollTask: Task<Void, Never>?
    private var pushTask: Task<Void, Never>?
    private(set) var isActive = false

    func start(timerManager: TimerManager) {
        guard !isActive,
              !timerManager.supabaseUrl.isEmpty,
              !timerManager.supabaseKey.isEmpty else { return }
        self.timerManager = timerManager
        isActive = true

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollCommand()
                try? await Task.sleep(for: .seconds(2))
            }
        }

        pushTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pushStatus()
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pushTask?.cancel()
        pollTask = nil
        pushTask = nil
        isActive = false
        timerManager = nil
    }

    private func pushStatus() async {
        guard let tm = timerManager,
              !tm.supabaseUrl.isEmpty,
              !tm.supabaseKey.isEmpty else { return }

        guard let url = URL(string: "\(tm.supabaseUrl)/rest/v1/timer_state?id=eq.1") else { return }
        let status = tm.currentStatus()
        guard let body = try? JSONEncoder().encode(status) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(tm.supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(tm.supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = body

        _ = try? await URLSession.shared.data(for: request)
    }

    private func pollCommand() async {
        guard let tm = timerManager,
              !tm.supabaseUrl.isEmpty,
              !tm.supabaseKey.isEmpty else { return }

        guard var components = URLComponents(string: "\(tm.supabaseUrl)/rest/v1/timer_state") else { return }
        components.queryItems = [
            URLQueryItem(name: "select", value: "command"),
            URLQueryItem(name: "id", value: "eq.1")
        ]
        guard let url = components.url else { return }

        var request = URLRequest(url: url)
        request.setValue(tm.supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(tm.supabaseKey)", forHTTPHeaderField: "Authorization")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let rows = try? JSONDecoder().decode([CommandRow].self, from: data),
              let command = rows.first?.command else { return }

        switch command {
        case "start": tm.start()
        case "pause": tm.pause()
        case "stop":  tm.stop()
        case "skip":  tm.skip()
        default: break
        }

        await clearCommand(supabaseUrl: tm.supabaseUrl, supabaseKey: tm.supabaseKey)
    }

    private func clearCommand(supabaseUrl: String, supabaseKey: String) async {
        guard let url = URL(string: "\(supabaseUrl)/rest/v1/timer_state?id=eq.1") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["command": NSNull()])

        _ = try? await URLSession.shared.data(for: request)
    }
}

private struct CommandRow: Decodable {
    let command: String?
}
