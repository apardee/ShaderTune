//
//  PreviewModeDetailView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 3/14/26.
//

import SwiftUI

struct PreviewModeDetailView: View {
    @Bindable var state: EditorState

    var body: some View {
        PreviewWindowContent()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
