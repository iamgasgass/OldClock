# OldClock

> A standalone iOS 6 **Clock** app (World Clock, Alarm, Stopwatch, Timer) in the style of **The OldOS Project**. It keeps the iOS 6 look and runs full screen on current iPhones and iPads with iOS 16 or later.

[![iOS](https://img.shields.io/badge/iOS-16.0%2B-0A84FF?logo=apple&logoColor=white)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-SwiftUI-F05138?logo=swift&logoColor=white)](#architecture)
[![Build](https://img.shields.io/github/actions/workflow/status/iamgasgass/OldClock/build.yml?branch=main&label=build)](https://github.com/iamgasgass/OldClock/actions)
[![License](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey)](#license-and-attribution)

The OldOS Project shows the Clock icon on its home screen but has no Clock app: `HomeScreen.swift` explicitly skips it (`if !["Clock", "Calculator"].contains(app_name)`). OldClock is therefore written from the iOS 6 iPhone Clock app. It is built entirely from OldOS components and values:

- the blue-grey navigation bar and bar buttons;
- the black tab bar with the glossy blue selected icon;
- the ON / OFF switch (`toggle` from `Common.swift`);
- the pinstriped grouped tables, the red minus delete and the reorder grabber.

## Features

### World Clock

- **Rows:** one black glass row per city, with:
  - the analog face (white by day, black by night, red second hand);
  - the city name;
  - **Today / Yesterday / Tomorrow**.
- **+** opens **"Choose a city."**: the search bar with Cancel and the keyboard up. There are 500+ cities ("Cupertino, U.S.A.") from the time zone database plus the main cities that share a time zone (Milan, San Francisco, Mumbai, …).
- **Edit / Done:** delete with the red minus and **Delete**, and reorder with the grabbers.
- **Default:** the list starts with Cupertino, as on iOS 6.

### Alarm

- **List:** alarms sorted by time ("7:00 AM", "Alarm, Weekdays"), each with the **ON / OFF** switch.
- **+ → Add Alarm** (Cancel / Save) contains:
  - **Repeat**: Every Sunday … Every Saturday, summarised as Never / Every day / Weekdays / Weekends / "Mon Wed";
  - **Sound**: the 25 iOS 6 ringtone names, *Pick a song* from your library, or *None*;
  - **Snooze** switch;
  - **Label**;
  - the iOS 6 time wheel (12 or 24 hour, as set on the device).
- **Edit → Edit Alarm**, with **Delete Alarm**.
- **Ringing:**
  - alarms ring through local notifications when OldClock is closed, with a **Snooze** action (9 minutes);
  - with OldClock open, they show the iOS 6 alert (**Snooze** / **OK**) and loop the sound.
  - One-time alarms switch themselves off after ringing.

### Stopwatch

- Big **00:00.0** display on the silver panel.
- **Start / Stop** (green / red) and **Reset / Lap**.
- The lap list (current lap first).
- It keeps running when the app is closed.

### Timer

- **hours / mins** wheel (default 15 min).
- **When Timer Ends** (Cancel / Set): the ringtones or **Stop Playing**, which pauses the music, like the iOS 6 sleep timer.
- **Start / Cancel**, with the countdown display.
- It rings through a notification when the app is closed, and with the "Timer Done" alert when it is open.

### Appearance and full screen

- **Aspect UI** in Settings › OldClock: *Sistema*, *Chiaro* or *Scuro*. Scuro uses OldSafari's Private graphite palette; the night faces and black rows are the same in both.
- **Full screen** like OldSafari: the bars extend behind the status bar / Dynamic Island, and the tab bar behind the home indicator.
- Portrait only, as on iOS 6.

## Notes

- **Ringtones:** Apple's iOS 6 ringtone audio cannot be redistributed. The 25 sounds bundled with the iOS 6 names are original synthesised tones in the same spirit (`Resources/Sounds`, IMA4 CAF, 20 s each).
- **Notifications:** alarms and the timer need notification permission, which is asked for on the first alarm or timer. A notification plays its sound once (up to 30 s); the looping ring happens when OldClock is open.

## Requirements

- iOS / iPadOS 16.0 or later.
- Xcode 16 and [XcodeGen](https://github.com/yonaskolb/XcodeGen) to build.

## Build

```sh
brew install xcodegen
xcodegen generate --spec project.yml
open OldClock.xcodeproj
```

The GitHub Actions workflow (`.github/workflows/build.yml`) generates the project, builds it without signing and uploads an unsigned IPA (`OldClock-Unsigned-IPA`).

## Architecture

| File | Role |
| --- | --- |
| `OldClockApp.swift` | App / scene delegate, notification handling (ring in app, Snooze action) |
| `Models/ClockModels.swift` | Tabs, cities, sounds, alarms, repeat summary, time formats |
| `Store/WorldClockStore.swift` | World clocks and city search |
| `Store/AlarmStore.swift` | Alarms (saved, sorted, scheduled) |
| `Store/ClockNotifications.swift` | Local notifications for alarms, snooze and timer |
| `Store/ClockAudio.swift` | Sound preview / looping ring, the iOS 6 alert state |
| `Store/StopwatchModel.swift`, `Store/TimerModel.swift` | Stopwatch and timer (survive closing the app) |
| `Store/ClockNavigator.swift` | Tab, Edit mode, modal screens |
| `Store/ClockSettings.swift`, `Settings.bundle` | Aspect UI, status bar, keyboard |
| `Views/OldClockRootView.swift` | Bars, tabs, modals, alert |
| `Views/WorldClockView.swift`, `Views/AnalogClockFace.swift`, `Views/CitySearchView.swift` | World Clock |
| `Views/AlarmListView.swift`, `Views/AlarmEditorView.swift`, `Views/SoundListView.swift` | Alarm |
| `Views/StopwatchView.swift`, `Views/TimerView.swift` | Stopwatch, Timer |
| `Views/ClockWheelPicker.swift` | iOS 6 picker (real `UIPickerView` wheels in the iOS 6 frame) |
| `Views/ClockToggle.swift` | OldOS ON / OFF switch |
| `Views/ClockChrome.swift`, `Views/ClockGrouped.swift`, `Views/ClockAlertView.swift` | Bars, tab bar, grouped tables, big buttons, iOS 6 alert |
| `Support/OldOSKit.swift` | Shared OldOS look (same file as OldSafari) |
| `Support/OldClockPalette.swift` | Light / Dark palette (OldSafari Private in Dark) |

There are no third-party dependencies.

## License and attribution

The UI components and artwork come from [The OldOS Project](https://github.com/zzanehip/The-OldOS-Project) by Zane Kleinberg, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The city list comes from the IANA time zone database (public domain). See `LICENSE` and `EXTRACTION.json`.
