//
//  PreviewInsetView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 3/14/26.
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

struct PreviewInsetView: View {
    @Environment(\.openWindow) private var openWindow
    var previewState: PreviewState

    @Binding var previewWidth: CGFloat
    @State private var isHovering = false
    @State private var dragStartWidth: CGFloat?
    @State private var dragStartLocation: CGPoint?

    private let minWidth: CGFloat = 160
    private let maxWidth: CGFloat = 640

    var body: some View {
        let previewHeight = previewWidth * 3 / 4
        PreviewWindowContent()
            .frame(width: previewWidth, height: previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                if isHovering {
                    detachButton
                }
            }
            .overlay(alignment: .leading) {
                resizeHandle(horizontal: true)
            }
            .overlay(alignment: .top) {
                resizeHandle(horizontal: false)
            }
            .overlay(alignment: .topLeading) {
                resizeCorner
            }
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
    }

    private var detachButton: some View {
        Button {
            previewState.isDetached = true
            openWindow(id: "shader-preview")
        } label: {
            Image(systemName: "macwindow.on.rectangle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(5)
                .background(.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .padding(6)
        .transition(.opacity)
    }

    private func resizeHandle(horizontal: Bool) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: horizontal ? 6 : nil, height: horizontal ? nil : 6)
            .contentShape(Rectangle())
            #if os(macOS)
        .cursor(horizontal ? .resizeLeftRight : .resizeUpDown)
            #endif
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        if dragStartWidth == nil {
                            dragStartWidth = previewWidth
                            dragStartLocation = value.startLocation
                        }
                        guard let startWidth = dragStartWidth,
                            let startLoc = dragStartLocation
                        else { return }
                        let delta =
                            horizontal
                            ? -(value.location.x - startLoc.x)
                            : -(value.location.y - startLoc.y)
                        let aspect: CGFloat = horizontal ? 1.0 : 4.0 / 3.0
                        previewWidth = (startWidth + delta * aspect)
                            .clamped(to: minWidth...maxWidth)
                    }
                    .onEnded { _ in
                        dragStartWidth = nil
                        dragStartLocation = nil
                    }
            )
    }

    private var resizeCorner: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 10, height: 10)
            .contentShape(Rectangle())
            #if os(macOS)
        .cursor(.crosshair)
            #endif
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        if dragStartWidth == nil {
                            dragStartWidth = previewWidth
                            dragStartLocation = value.startLocation
                        }
                        guard let startWidth = dragStartWidth,
                            let startLoc = dragStartLocation
                        else { return }
                        let dx = -(value.location.x - startLoc.x)
                        let dy = -(value.location.y - startLoc.y)
                        let delta = max(dx, dy)
                        previewWidth = (startWidth + delta)
                            .clamped(to: minWidth...maxWidth)
                    }
                    .onEnded { _ in
                        dragStartWidth = nil
                        dragStartLocation = nil
                    }
            )
    }
}
