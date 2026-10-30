import SwiftUI
import MediaPlayer

/// The iOS 6 sound list (Alarm › Sound, Timer › When Timer Ends): "Pick a
/// song" for alarms, the ringtones with the blue check, "None" for alarms
/// and "Stop Playing" for the timer. A tap plays the sound.
struct SoundListView: View {
    @Environment(\.oldClockTheme) private var theme
    @Binding var selection: ClockSound
    var allowsSong = true
    var allowsNone = true
    var allowsStopPlaying = false
    var bottomInset: CGFloat = 0

    @State private var pickingSong = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if allowsSong {
                    ClockSectionTitle(text: "Songs")
                    ClockCard {
                        if selection.kind == .song {
                            ClockCardRow(title: selection.name, checked: true, action: {
                                ClockSoundPlayer.shared.play(selection, loop: false)
                            })
                        }
                        ClockCardRow(title: "Pick a song", showsSeparator: false, action: {
                            ClockSoundPlayer.shared.stop()
                            MPMediaLibrary.requestAuthorization { status in
                                DispatchQueue.main.async {
                                    if status == .authorized { pickingSong = true }
                                }
                            }
                        })
                    }
                    .padding(.horizontal, 10)
                }

                ClockSectionTitle(text: "Ringtones")
                ClockCard {
                    ForEach(Array(ClockSound.ringtones.enumerated()), id: \.offset) { index, name in
                        let sound = ClockSound.tone(name)
                        ClockCardRow(
                            title: name,
                            showsSeparator: index < ClockSound.ringtones.count - 1,
                            checked: selection == sound,
                            disclosure: false,
                            action: { pick(sound) }
                        )
                    }
                }
                .padding(.horizontal, 10)

                if allowsNone || allowsStopPlaying {
                    ClockCard {
                        if allowsNone {
                            ClockCardRow(title: "None", showsSeparator: allowsStopPlaying, checked: selection == .none, disclosure: false, action: { pick(.none) })
                        }
                        if allowsStopPlaying {
                            ClockCardRow(title: "Stop Playing", showsSeparator: false, checked: selection == .stopPlaying, disclosure: false, action: { pick(.stopPlaying) })
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 20)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 20 + bottomInset)
        }
        .background(ClockGroupedBackground())
        .onDisappear { ClockSoundPlayer.shared.stop() }
        .sheet(isPresented: $pickingSong) {
            ClockSongPicker { item in
                pickingSong = false
                if let item {
                    let sound = ClockSound(kind: .song, name: item.title ?? "Song", songID: item.persistentID)
                    selection = sound
                    ClockSoundPlayer.shared.play(sound, loop: false)
                }
            }
            .ignoresSafeArea()
        }
    }

    private func pick(_ sound: ClockSound) {
        selection = sound
        ClockSoundPlayer.shared.play(sound, loop: false)
    }
}

/// `MPMediaPickerController` for "Pick a song".
struct ClockSongPicker: UIViewControllerRepresentable {
    let completion: (MPMediaItem?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = false
        picker.showsCloudItems = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

    final class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        let completion: (MPMediaItem?) -> Void

        init(completion: @escaping (MPMediaItem?) -> Void) {
            self.completion = completion
        }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            completion(mediaItemCollection.items.first)
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            completion(nil)
        }
    }
}
