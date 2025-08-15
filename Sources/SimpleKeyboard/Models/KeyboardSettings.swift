//
//  KeyboardSettings.swift
//  
//
//  Created by Henrik Storch on 12/25/19.
//

import Combine
import SwiftUI

public enum KeyboardMode {
    case letters
    case numbers
    case symbols
}

public protocol SimpleKeyboardInput {
    var currentText: String { get }
    mutating func replaceAll(with text: String)
}

extension Binding: SimpleKeyboardInput where Value == String {
    public var currentText: String {
        self.wrappedValue
    }

    public mutating func replaceAll(with text: String) {
        self.wrappedValue = text
    }
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
extension NSTextField: SimpleKeyboardInput {
    public var currentText: String {
        self.stringValue
    }

    public func replaceAll(with text: String) {
        stringValue = text
    }
}
#endif

#if canImport(UIKit)
import UIKit

extension UITextField: SimpleKeyboardInput {
    public var currentText: String {
        self.text ?? ""
    }

    public func replaceAll(with text: String) {
        self.text = text
    }
}
#endif

public class KeyboardSettings: ObservableObject {
    @Published public var text: String = "" {
        didSet {
            textInput?.replaceAll(with: text)
        }
    }
    
    /// Cursor position for cursor-aware text insertion
    @Published public var cursorPosition: Int = 0

    @Published public var language: Language

    public var theme: KeyboardTheme

        @Published public var mode: KeyboardMode = .letters

    /// `nil` mean there is no action icon
    var actionButton: Icon?

    public var textInput: SimpleKeyboardInput?
    public var action: (() -> Void)?

    @Published public var isShown = true

    @Published public var showNumbers: Bool
    @Published public var showSpace: Bool

    /// `nil` mean there is no need to switch, so there will be no shift-key
    @Published public var isUpperCase: Bool?

    /// When enabled via double-tapping shift, letters remain uppercased until disabled
    @Published public var isCapsLocked: Bool = false

    /// `textInput` should be `nil` when working directly with SwiftUI,
    /// in that case you would bind your input directly to the `textInput` of the Keyboard
    public init(
        language: Language,
        textInput: SimpleKeyboardInput?,
        theme: KeyboardTheme = .system,
        actionButton: Icon? = .done,
        showNumbers: Bool = false,
        showSpace: Bool = true,
        isUpperCase: Bool? = nil,
        action: (() -> Void)? = nil) {
            self.textInput = textInput
            self.theme = theme
            self.language = language
            self.action = action
            self.showNumbers = showNumbers
            self.showSpace = showSpace
            self.isUpperCase = isUpperCase
            self.actionButton = actionButton
            self.mode = .letters
        }

    func changeTextInput(to newInput: SimpleKeyboardInput) {
        self.textInput = newInput
        self.text = newInput.currentText
    }
    
    /// Insert text at the current cursor position
    public func insertTextAtCursor(_ newText: String) {
        let position = min(cursorPosition, text.count)
        let startIndex = text.index(text.startIndex, offsetBy: position)
        text.insert(contentsOf: newText, at: startIndex)
        cursorPosition = position + newText.count
    }
    
    /// Delete character before cursor position
    public func deleteBackward() {
        guard cursorPosition > 0 else { return }
        let position = cursorPosition - 1
        let index = text.index(text.startIndex, offsetBy: position)
        text.remove(at: index)
        cursorPosition = position
    }
}
