import SwiftUI
import UIKit
import Combine
import UserNotifications

@main
final class OldClockAppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        _ = ClockSettings.shared
        _ = ClockKeyboard.shared
        let center = UNUserNotificationCenter.current()
        center.delegate = ClockNotificationHandler.shared
        ClockNotifications.registerCategories()
        // Bring the stores up: the timer resumes its countdown, alarms that
        // went off while closed switch off, notifications are re-armed.
        _ = TimerModel.shared
        _ = StopwatchModel.shared
        AlarmStore.shared.refreshExpired()
        AlarmStore.shared.rescheduleAll()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = OldClockSceneDelegate.self
        return configuration
    }

    /// The iOS 6 Clock app is portrait only.
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}

final class OldClockSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = OldClockHostingController(root: OldClockRootView())
        window.backgroundColor = .black
        self.window = window
        window.makeKeyAndVisible()
        ClockSettings.shared.apply()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        ClockSettings.shared.apply()
    }
}

/// Hosts the SwiftUI app and applies the status bar style requested by the
/// visible chrome (dark text on the light bar, light text on the graphite bars).
final class OldClockHostingController: UIHostingController<OldClockRootView> {
    private var cancellables = Set<AnyCancellable>()

    init(root: OldClockRootView) {
        super.init(rootView: root)
        ClockStatusBar.shared.$style
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                UIView.animate(withDuration: 0.2) {
                    self?.setNeedsStatusBarAppearanceUpdate()
                }
            }
            .store(in: &cancellables)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        ClockStatusBar.shared.style
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

/// Alarms and the timer while OldClock is open: instead of a banner, the
/// iOS 6 alert rings in the app. Snooze from a notification re-arms the
/// alarm 9 minutes later.
final class ClockNotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ClockNotificationHandler()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let info = notification.request.content.userInfo
        DispatchQueue.main.async {
            switch info["kind"] as? String {
            case "alarm":
                if let raw = info["alarmID"] as? String, let id = UUID(uuidString: raw), let alarm = AlarmStore.shared.alarm(id) {
                    ClockRinger.shared.ringAlarm(alarm)
                    AlarmStore.shared.didFire(id)
                }
            case "timer":
                TimerModel.shared.finish()
            default:
                break
            }
        }
        completionHandler([])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        DispatchQueue.main.async {
            if info["kind"] as? String == "alarm",
               let raw = info["alarmID"] as? String, let id = UUID(uuidString: raw) {
                if response.actionIdentifier == ClockNotifications.snoozeAction, let alarm = AlarmStore.shared.alarm(id) {
                    ClockNotifications.scheduleSnooze(alarm)
                }
                AlarmStore.shared.didFire(id)
            }
            completionHandler()
        }
    }
}
