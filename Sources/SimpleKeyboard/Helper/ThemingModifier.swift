//
//  ThemingModifier.swift
//  
//
//  Created by Henrik Storch on 24.04.22.
//

import SwiftUI

struct OuterKeyboardThemingModifier<Background: View>: ViewModifier {
    var theme: KeyboardTheme
    var backroundColor: Background

    func body(content: Content) -> some View {
        switch theme {
        case .system:
            content
                .padding(10)
                .background(backroundColor)

        case .floating:
            content
                .cornerRadius(25, corners: [.bottomLeft, .bottomRight])
                .padding(10)
                .background(backroundColor)
                .cornerRadius(25)
                .padding(10)

        default:
            // For themes like .transparent, .color(_), .material(_)
            content
        }
    }
}
