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

// Enhanced protocol for cursor-aware text input
public protocol CursorAwareTextInput: SimpleKeyboardInput {
    var cursorPosition: Int { get set }
    mutating func insertText(_ text: String, at position: Int)
    mutating func deleteText(at position: Int, length: Int)
}

extension Binding: SimpleKeyboardInput where Value == String {
    public var currentText: String {
        self.wrappedValue
    }

    public mutating func replaceAll(with text: String) {
        self.wrappedValue = text
    }
}

// Create a cursor-aware wrapper for String bindings
public class CursorAwareStringInput: ObservableObject, CursorAwareTextInput {
    @Published public var text: String
    @Published public var cursorPosition: Int
    
    public var binding: Binding<String>
    
    public init(_ binding: Binding<String>, cursorPosition: Int = 0) {
        self.binding = binding
        self.text = binding.wrappedValue
        self.cursorPosition = min(cursorPosition, binding.wrappedValue.count)
    }
    
    public var currentText: String {
        text
    }
    
    public func replaceAll(with text: String) {
        self.text = text
        self.binding.wrappedValue = text
        self.cursorPosition = text.count
    }
    
    public func insertText(_ insertText: String, at position: Int) {
        let safePosition = max(0, min(position, text.count))
        let startIndex = text.index(text.startIndex, offsetBy: safePosition)
        text.insert(contentsOf: insertText, at: startIndex)
        binding.wrappedValue = text
        cursorPosition = safePosition + insertText.count
    }
    
    public func deleteText(at position: Int, length: Int) {
        let safePosition = max(0, min(position, text.count))
        let safeLength = max(0, min(length, text.count - safePosition))
        
        if safeLength > 0 {
            let startIndex = text.index(text.startIndex, offsetBy: safePosition)
            let endIndex = text.index(startIndex, offsetBy: safeLength)
            text.removeSubrange(startIndex..<endIndex)
            binding.wrappedValue = text
            cursorPosition = safePosition
        }
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
    public var text: String = "" {
        didSet {
            textInput?.replaceAll(with: text)
        }
    }

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
}
