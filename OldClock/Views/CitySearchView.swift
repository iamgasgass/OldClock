import SwiftUI

/// "Choose a city.": the iOS 6 search bar with its prompt, the keyboard up,
/// and the matching cities ("Cupertino, U.S.A."). Tapping one adds it.
struct CitySearchView: View {
    @Environment(\.oldClockTheme) private var theme
    @EnvironmentObject private var navigator: ClockNavigator
    @ObservedObject private var keyboard = ClockKeyboard.shared
    let topInset: CGFloat
    let bottomInset: CGFloat

    @State private var query = ""
    @FocusState private var focused: Bool

    var body: some View {
        let results = WorldClockStore.shared.search(query)
        VStack(spacing: 0) {
            searchBar
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results) { city in
                        Button {
                            OldClockHaptics.tap()
                            WorldClockStore.shared.add(city)
                            navigator.dismissModal()
                        } label: {
                            VStack(spacing: 0) {
                                HStack {
                                    Text(city.displayName)
                                        .font(OldOSFont.bold(18))
                                        .foregroundColor(theme.listRowText)
                                        .lineLimit(1)
                                        .padding(.leading, 12)
                                    Spacer()
                                }
                                .frame(height: 43)
                                Rectangle().fill(theme.listSeparator).frame(height: 1)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ClockRowButtonStyle())
                    }
                }
                .padding(.bottom, max(keyboard.height, bottomInset))
            }
            .scrollDismissesKeyboard(.interactively)
            .background(theme.listBackground)
        }
        .background(theme.listBackground)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
        }
    }

    private var searchBar: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)
            Text("Choose a city.")
                .font(OldOSFont.regular(14))
                .foregroundColor(theme.isDark ? theme.pageTitle : .oldOS(47, 62, 88))
                .shadow(color: theme.isDark ? Color.black.opacity(0.65) : Color.white.opacity(0.65), radius: 0, x: 0, y: theme.isDark ? -2.0 / 3.0 : 2.0 / 3.0)
                .padding(.top, 10)
            HStack(spacing: 6) {
                ClockSearchField(text: $query, focused: $focused)
                OldOSRectangleButton(title: "Cancel", type: theme.neutralButton) {
                    navigator.dismissModal()
                }
            }
            .padding(.horizontal, 6)
            .frame(height: 50)
        }
        .background(LinearGradient(oldOS: theme.barGradient))
        .oldOSBorder(width: 1, edges: [.bottom], color: theme.barHairline)
    }
}

/// The iOS 6 rounded search field (magnifier, text, clear button).
struct ClockSearchField: View {
    @Environment(\.oldClockTheme) private var theme
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 6) {
            Image("SearchGlass")
                .padding(.leading, 9)
            TextField("", text: $text)
                .font(OldOSFont.regular(16))
                .foregroundColor(theme.fieldTextActive)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .focused(focused)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image("TextFieldClear")
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
        }
        .frame(height: 31)
        .background(
            Capsule().fill(theme.fieldPlain)
        )
        .overlay(
            Capsule().stroke(theme.searchFieldStroke, lineWidth: 0.5)
        )
        .overlay(
            Capsule()
                .stroke(Color.black.opacity(0.35), lineWidth: 1.5)
                .blur(radius: 1)
                .offset(y: 1)
                .clipShape(Capsule())
        )
    }
}

/// iOS 6 blue table selection.
struct ClockRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(oldOS: [
                    OldOSStop(.oldOS(5, 140, 245), 0),
                    OldOSStop(.oldOS(1, 93, 230), 1)
                ])
                .opacity(configuration.isPressed ? 1 : 0)
            )
    }
}
