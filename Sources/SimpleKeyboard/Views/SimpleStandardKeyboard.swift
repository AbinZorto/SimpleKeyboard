import SwiftUI

public struct SimpleStandardKeyboard: View, ThemeableView {
    var theme: KeyboardTheme { settings.theme }

    @ObservedObject var settings: KeyboardSettings

    // Optional overrides (backwards-compatible)
    private let onActionOverride: (() -> Void)?
    private let actionIconOverride: Icon?
    private let emojiSystemNameOverride: String?
    private let onEmojiTapOverride: (() -> Void)?

    public init(
        settings: KeyboardSettings,
        textInput textInputOverride: Binding<String>? = nil,
        onAction: (() -> Void)? = nil,
        actionIcon: Icon? = nil,
        emojiSystemName: String? = nil,
        onEmojiTap: (() -> Void)? = nil
    ) {
        // 1) Initialize all stored properties first
        self.settings = settings
        self.onActionOverride = onAction
        self.actionIconOverride = actionIcon
        self.emojiSystemNameOverride = emojiSystemName
        self.onEmojiTapOverride = onEmojiTap

        // 2) Now it's safe to use self / call methods
        if let textInputOverride {
            self.settings.changeTextInput(to: textInputOverride)
        }
        if let onAction {
            self.settings.action = onAction
        }
        if let actionIcon {
            self.settings.actionButton = actionIcon
        }
    }

    // Back-compat: expose old name used by tests, now mapped to the new bottom bar
    var spaceRow: some View { bottomBar }

    var bottomBar: some View {
        HStack(spacing: 6) {
            switch settings.mode {
            case .letters:
                ModeSwitchKeyButton(title: "123") { self.settings.mode = .numbers }
            case .numbers, .symbols:
                ModeSwitchKeyButton(title: "ABC") { self.settings.mode = .letters }
            }

            // Emoji button override if provided; otherwise the default
            if let name = emojiSystemNameOverride {
                CustomEmojiKeyButton(systemName: name, onTap: onEmojiTapOverride)
            } else {
                EmojiKeyButton(text: $settings.text)
            }

            if settings.showSpace {
                SpaceKeyButton(text: $settings.text)
                    .layoutPriority(2)
            }

            if let icon = (actionIconOverride ?? settings.actionButton) {
                ActionKeyButton(icon: icon) {
                    if let onActionOverride {
                        onActionOverride()
                    } else {
                        self.settings.action?()
                    }
                }
            }
        }
    }

    // Back-compat: old single numbers row used by tests only
    var numbersRow: some View {
        HStack(spacing: 10) {
            ForEach(Language.numbers(areUppercased: self.settings.isUpperCase ?? false), id: \.self) { key in
                KeyButton(text: self.$settings.text, letter: key)
            }
        }
    }

    var numbersGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(["1","2","3","4","5","6","7","8","9","0"], id: \.self) { key in
                    GridKeyButton(text: self.$settings.text, label: key)
                }
            }
            HStack(spacing: 6) {
                ForEach(["-","/",":",";","(",")","$","&","@","\""], id: \.self) { key in
                    GridKeyButton(text: self.$settings.text, label: key)
                }
            }
            HStack(spacing: 6) {
                ModeSwitchKeyButton(title: "#+=") { self.settings.mode = .symbols }
                ForEach([".", ",", "?", "!", "'"], id: \.self) { key in
                    GridKeyButton(text: self.$settings.text, label: key)
                }
                DeleteKeyButton(text: self.$settings.text)
            }
        }
    }

    var symbolsGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(["[", "]", "{", "}", "#", "%", "^", "*", "+", "="], id: \.self) { key in
                    GridKeyButton(text: self.$settings.text, label: key)
                }
            }
            HStack(spacing: 6) {
                ForEach(["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"], id: \.self) { key in
                    GridKeyButton(text: self.$settings.text, label: key)
                }
            }
            HStack(spacing: 6) {
                ModeSwitchKeyButton(title: "123") { self.settings.mode = .numbers }
                ForEach([".", ",", "?", "!", "'"], id: \.self) { key in
                    GridKeyButton(text: self.$settings.text, label: key)
                }
                DeleteKeyButton(text: self.$settings.text)
            }
        }
    }

    var keyboardRows: some View {
        ForEach(0..<settings.language.rows(areUppercased: settings.isUpperCase ?? false).count, id: \.self) { idx in
            HStack(spacing: 0) {
                if idx == 2 {
                    if self.settings.isUpperCase != nil {
                        ShiftKeyButton(isUpperCase: self.$settings.isUpperCase)
                        Spacer(minLength: 2)
                            .frame(maxWidth: 15)
                            .layoutPriority(2)
                    }
                } else if idx == 1 {
                    Spacer(minLength: 1)
                        .frame(maxWidth: 8)
                        .layoutPriority(11)
                }
                self.rowFor(idx)
                if idx == 2 {
                    Group {
                        Spacer(minLength: 2)
                            .frame(maxWidth: 15)
                            .layoutPriority(2)
                        if settings.language == .french {
                            FRAccentKeyButton(text: $settings.text)
                            Spacer()
                        }
                        DeleteKeyButton(text: self.$settings.text)
                    }
                } else if idx == 1 {
                    Spacer(minLength: 3)
                        .frame(maxWidth: 10)
                        .layoutPriority(11)
                }
            }
        }
    }

    fileprivate func rowFor(_ index: Int) -> some View {
        let rows = self.settings.language.rows(areUppercased: settings.isUpperCase ?? false)[index]
        return ForEach(rows, id: \.self) { key in
            Spacer(minLength: settings.language.spacing)
            KeyButton(text: self.$settings.text, letter: key)
            Spacer(minLength: settings.language.spacing)
        }
    }

    public var body: some View {
        if settings.isShown {
            VStack(spacing: 10) {
                switch settings.mode {
                case .letters:
                    keyboardRows
                case .numbers:
                    numbersGrid
                case .symbols:
                    symbolsGrid
                }
                bottomBar
            }
            .padding(.leading, 4)
            .padding(.trailing, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .modifier(OuterKeyboardThemingModifier(theme: theme, backroundColor: keyboardBackground))
            .environmentObject(settings)
        }
    }
}

struct CustomEmojiKeyButton: View, ClickableKey {
    var systemName: String
    var onTap: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: { didClick(); onTap?() }) {
            if #available(iOS 14, macOS 11, *) {
                AnyView(Image(systemName: systemName).font(.system(size: 20, weight: .medium)))
            } else {
                AnyView(Text(":)"))
            }
        }
        .padding(10)
        .foregroundColor(.primary)
        .frame(height: 40)
        .background(colorScheme.keyboardKeyColor)
        .cornerRadius(7)
        .shadow(color: .black, radius: 0, y: 1)
    }
}

struct SimpleStandardKeyboard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(colors: [.red, .green, .purple], startPoint: .bottomLeading, endPoint: .topTrailing)
            VStack {
                Spacer()
                SimpleStandardKeyboard(
                                        settings: KeyboardSettings(
                                            language: .english,
                                            textInput: nil,
                                            theme: .floating,
                                            actionButton: .go,
                                            showNumbers: false,
                                            showSpace: true,
                                            isUpperCase: false
                                        ),
                                        onAction: {
                                        },
                                        actionIcon: .go,
                                        emojiSystemName: "xmark.circle.fill",
                                        onEmojiTap: {
                                            // Optional: hook for custom emoji tap behavior
                                        }
                                    )
//                    .preferredColorScheme(.dark)
            }
        }
    }
}
