//
//  PreviewState.swift
//  ShaderTune
//

import Metal
import SwiftUI

@Observable
class PreviewState {
    var mousePosition: CGPoint = .zero
    var compiledLibrary: MTLLibrary?
    var currentShader: Shader?
    var passLibraries: [String: MTLLibrary] = [:]
    var isDetached: Bool = false
    var selectedFileURL: URL?
}
