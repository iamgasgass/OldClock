import Foundation
import AVFoundation
import MediaPlayer
import Combine

/// Plays the alarm / timer sounds: the preview when a sound is picked, and
/// the looping ring while the iOS 6 alert is on screen. Like iOS 6, the ring
/// plays through the speaker even with the ring / silent switch on silent.
final class ClockSoundPlayer {
    static let shared = ClockSoundPlayer()

    private var player: AVAudioPlayer?
    private var musicPlayer: MPMusicPlayerController?

    private init() {}

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    /// Preview (once) or ring (looping).
    func play(_ sound: ClockSound, loop: Bool) {
        stop()
        switch sound.kind {
        case .none, .stopPlaying:
            return
        case .song:
            if let songID = sound.songID, playSong(songID) { return }
            fallthrough
        case .tone:
            guard let file = sound.fileName,
                  let url = Bundle.main.url(forResource: (file as NSString).deletingPathExtension, withExtension: "caf") else { return }
            activateSession()
            player = try? AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loop ? -1 : 0
            player?.prepareToPlay()
            player?.play()
        }
    }

    private func playSong(_ id: UInt64) -> Bool {
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(value: id), forProperty: MPMediaItemPropertyPersistentID))
        guard let items = query.items, !items.isEmpty else { return false }
        let music = MPMusicPlayerController.applicationMusicPlayer
        music.setQueue(with: MPMediaItemCollection(items: items))
        music.repeatMode = .one
        music.play()
        musicPlayer = music
        return true
    }

    func stop() {
        player?.stop()
        player = nil
        musicPlayer?.stop()
        musicPlayer = nil
    }
}

/// The iOS 6 alarm / timer alert ("Alarm" … Snooze / OK, "Timer Done" … OK)
/// shown while the sound rings.
final class ClockRinger: ObservableObject {
    static let shared = ClockRinger()

    struct Ring: Identifiable, Equatable {
        enum Kind: Equatable {
            case alarm(UUID)
            case timer
        }

        let id = UUID()
        let kind: Kind
        let title: String
        let message: String
        let canSnooze: Bool
    }

    @Published private(set) var ring: Ring?

    private init() {}

    func ringAlarm(_ alarm: ClockAlarm) {
        if case .alarm(let id) = ring?.kind, id == alarm.id { return }
        ring = Ring(kind: .alarm(alarm.id), title: "Alarm", message: alarm.label.isEmpty ? "Alarm" : alarm.label, canSnooze: alarm.snooze)
        ClockSoundPlayer.shared.play(alarm.sound, loop: true)
    }

    func ringTimer(sound: ClockSound) {
        if sound.kind == .stopPlaying {
            // iOS 6 sleep timer: stop the music instead of ringing.
            MPMusicPlayerController.systemMusicPlayer.pause()
            return
        }
        ring = Ring(kind: .timer, title: "Clock", message: "Timer Done", canSnooze: false)
        ClockSoundPlayer.shared.play(sound, loop: true)
    }

    func snooze() {
        if case .alarm(let id) = ring?.kind, let alarm = AlarmStore.shared.alarm(id) {
            ClockNotifications.scheduleSnooze(alarm)
        }
        dismiss()
    }

    func dismiss() {
        ClockSoundPlayer.shared.stop()
        ring = nil
    }
}
