//
//  KeyButton.swift
//  
//
//  Created by Henrik Storch on 12/24/19.
//

import SwiftUI

protocol ClickableKey {
    func didClick()
}

extension ClickableKey {
    func didClick() {
        #if canImport(UIKit)
        UIDevice.current.playInputClick()
        #endif
    }
}

struct ShiftKeyButton: View {
    @Binding var isUpperCase: Bool!
    @EnvironmentObject var settings: KeyboardSettings
    @State private var lastTapDate: Date? = nil

    var body: some View {
        Button(action: {
            let now = Date()
            if let last = lastTapDate, now.timeIntervalSince(last) < 0.3 {
                settings.isCapsLocked.toggle()
                self.isUpperCase = settings.isCapsLocked
                lastTapDate = nil
            } else {
                if settings.isCapsLocked {
                    settings.isCapsLocked = false
                    self.isUpperCase = false
                } else {
                    self.isUpperCase?.toggle()
                }
                lastTapDate = now
            }
        }) {
            if #available(iOS 15, macOS 12, *) {
                AnyView(Image(systemName: settings.isCapsLocked ? "capslock.fill" : (isUpperCase ? "shift.fill" : "shift"))
                    .dynamicTypeSize(.large))
            } else if #available(iOS 14, macOS 11, *) {
                AnyView(Image(systemName: settings.isCapsLocked ? "capslock.fill" : (isUpperCase ? "shift.fill" : "shift")))
            } else {
                AnyView(Text(isUpperCase! ? "Up": "lw", bundle: .module))
            }
        }
        .padding(10)
        .foregroundColor(.primary)
        .font(.headline.weight(.semibold))
        .frame(width: 40, height: 40)
        .background(Color.black.opacity(0.4))
        .cornerRadius(5)
    }
}

struct KeyButton: View, ClickableKey {
    @Binding var text: String
    var letter: String
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var settings: KeyboardSettings

    var body: some View {
        Button(action: {
            insertTextAtCursor(self.letter)
            didClick()
            if (self.settings.isUpperCase ?? false) && !self.settings.isCapsLocked {
                self.settings.isUpperCase = false
            }
        }) {
            Text(letter)
                .font(.system(size: 25))
                .fixedSize()
                .scaledToFit()
                .scaleEffect(0.75)
                .frame(height: 40)
                .frame(minWidth: 32, maxWidth: .infinity)
                .foregroundColor(.primary)
                .background(colorScheme.keyboardKeyColor)
                .cornerRadius(5)
                .shadow(color: .black, radius: 0, y: 1)
        }
    }
    
    private func insertTextAtCursor(_ newText: String) {
        settings.insertTextAtCursor(newText)
    }
}

struct FRAccentKeyButton: View {
    @Binding var text: String
    @EnvironmentObject var settings: KeyboardSettings

    var body: some View {
        Button(action: {
            self.action()
        }) {
            Text("´")
                .foregroundColor(.primary)
                .font(.system(size: 25))
                .padding(5)
                .frame(height: 40)
                .frame(minWidth: 20, idealWidth: 25, maxWidth: 25)
                .background(Color.black.opacity(0.4))
                .cornerRadius(5)
                .layoutPriority(10)
                .shadow(color: .black, radius: 0, y: 1)
        }
    }

    internal func action() {
        var modified = ""
        let suffix = self.text.popLast()
        switch suffix {
        case "a": modified = "à"
        case "e": modified = "é"
        case "i": modified = "î"
        case "u": modified = "û"
        case "o": modified = "ô"
        case "c": modified = "ç"
        default:
            modified = "’"
            if let suffix = suffix {
                insertTextAtCursor(String(suffix))
            }
        }

        insertTextAtCursor(modified)
    }
    
    private func insertTextAtCursor(_ newText: String) {
        settings.insertTextAtCursor(newText)
    }
}

struct SpaceKeyButton: View, ClickableKey {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var settings: KeyboardSettings

    var content: some View {
        let spaceText = Text("space", bundle: .module)
        if #available(iOS 15.0, macOS 12, *) {
            return AnyView(spaceText.dynamicTypeSize(.large))
        } else {
            return AnyView(spaceText)
        }
    }

    var body: some View {
        Button(action: { insertTextAtCursor(" "); didClick() }) {
            content
                .padding()
                .frame(minWidth: 190)
                .frame(height: 40)
                .foregroundColor(.primary)
                .background(colorScheme.keyboardKeyColor)
                .cornerRadius(5)
                .shadow(color: .black, radius: 1, y: 1)
        }
    }
    
    private func insertTextAtCursor(_ newText: String) {
        settings.insertTextAtCursor(newText)
    }
}

struct DeleteKeyButton: View {
    @Binding var text: String
    @State private var deleteTimer: Timer? = nil
    @EnvironmentObject var settings: KeyboardSettings

    var body: some View {
        Button(action: {
            settings.deleteBackward()
        }) {
            if #available(iOS 15, macOS 12, *) {
                AnyView(Image(systemName: "delete.left").dynamicTypeSize(.large))
            } else if #available(iOS 14, macOS 11, *) {
                AnyView(Image(systemName: "delete.left"))
            } else {
                AnyView(Text("⌫"))
            }
        }
        .padding(10)
        .foregroundColor(.primary)
        .font(.headline.weight(.light))
        .frame(width: 40, height: 40)
        .background(Color.black.opacity(0.4))
        .cornerRadius(5)
        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50, pressing: { pressing in
            if pressing {
                startDeleteTimer()
            } else {
                stopDeleteTimer()
            }
        }, perform: {})
    }

    private func startDeleteTimer() {
        stopDeleteTimer()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { _ in
            self.settings.deleteBackward()
        }
        RunLoop.current.add(deleteTimer!, forMode: .common)
    }

    private func stopDeleteTimer() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }
}

struct EmojiKeyButton: View, ClickableKey {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: { didClick() }) {
            if #available(iOS 14, macOS 11, *) {
                AnyView(Image(systemName: "face.smiling").font(.system(size: 20, weight: .medium)))
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

struct ModeSwitchKeyButton: View, ClickableKey {
    var title: String
    var action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: { action(); didClick() }) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .padding(2)
                .frame(width: 40)
                .frame(height: 40)
                .foregroundColor(.primary)
                .background(colorScheme.keyboardKeyColor)
                .cornerRadius(5)
                .shadow(color: .black, radius: 0, y: 1)
        }
    }
}

struct GridKeyButton: View, ClickableKey {
    @Binding var text: String
    var label: String
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var settings: KeyboardSettings

    var body: some View {
        Button(action: { insertTextAtCursor(self.label); didClick() }) {
            Text(label)
                .font(.system(size: 25))
                .fixedSize()
                .scaledToFit()
                .scaleEffect(0.75)
                .frame(height: 40)
                .frame(minWidth: 32, maxWidth: .infinity)
                .foregroundColor(.primary)
                .background(colorScheme.keyboardKeyColor)
                .cornerRadius(5)
                .shadow(color: .black, radius: 0, y: 1)
        }
    }
    
    private func insertTextAtCursor(_ newText: String) {
        settings.insertTextAtCursor(newText)
    }
}

struct ActionKeyButton: View {
    @State var icon: Icon
    var action: () -> Void

    var iconView: some View {
        if #available(iOS 15.0, macOS 12, *) {
            return AnyView(icon.view.dynamicTypeSize(.large))
        } else {
            return icon.view
        }
    }

    var body: some View {
        Button(action: self.action) {
            iconView
                .padding()
                .frame(minWidth: 30, maxWidth: 100)
                .frame(height: 40)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(7)
                .shadow(color: .black, radius: 2, y: 2)
        }
    }
}

public enum Icon {
    case done, search, go

    var view: some View {
        switch self {
        case .done: return AnyView(Text("Done!", bundle: .module))
        case .search:
            if #available(iOS 14, macOS 11, *) {
                return AnyView(Image(systemName: "magnifyingglass"))
            }else {
                return AnyView(Text("Search", bundle: .module))
            }
        case .go: return AnyView(Text("Go!", bundle: .module))
        }
    }
}

