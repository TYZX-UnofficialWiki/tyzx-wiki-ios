import SwiftUI
import AVFoundation

actor TianyiBadAppleCache {
    static let shared = TianyiBadAppleCache()
    private var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("BadApple", isDirectory: true)
    }
    func assets() async throws -> (URL, String) {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let audio = directory.appendingPathComponent("sound.mp3")
        let frames = directory.appendingPathComponent("frames.json")
        for (file, remote) in [(frames, "https://zh-wiki.tyzx.org/extensions/TyzxBadApple/resources/frames-v1.json"), (audio, "https://zh-wiki.tyzx.org/r2_file.php/public/6/60/Tyzx_Bad_Apple_black_curtain_sound_v1.mp3")] {
            if !FileManager.default.fileExists(atPath: file.path) {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-TianyiOffline") { throw URLError(.notConnectedToInternet) }
                #endif
                let (data, response) = try await URLSession.shared.data(from: URL(string: remote)!)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
                if file == frames { _ = try JSONSerialization.jsonObject(with: data) }
                else { guard data.count > 100_000 else { throw URLError(.cannotDecodeContentData) } }
                try data.write(to: file, options: .atomic)
            }
        }
        return (audio, try String(contentsOf: frames, encoding: .utf8))
    }
    func clear() throws {
        if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
    }
}
@MainActor final class TianyiBadApplePlayer: ObservableObject {
    @Published var frames: String?
    @Published var time = 0.0
    @Published var playing = false
    @Published var error: String?
    @Published var ready = false
    let player = AVPlayer()
    func prepare() async {
        guard !ready else { return }
        do {
            let (url, json) = try await TianyiBadAppleCache.shared.assets()
            try Task.checkCancellation()
            frames = json
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
            ready = true
        } catch { if !Task.isCancelled { self.error = error.localizedDescription } }
    }
    func toggle() {
        if playing { pause() }
        else { player.play(); playing = true }
    }
    func pause() { player.pause(); playing = false }
    func stop() { pause(); player.seek(to: .zero); time = 0 }
    func tick() { time = max(0, player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0); if time >= 219.126 { stop() } }
}
