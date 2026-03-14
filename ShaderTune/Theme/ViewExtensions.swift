//
//  ViewExtensions.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 3/14/26.
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#if os(macOS)
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
#endif
