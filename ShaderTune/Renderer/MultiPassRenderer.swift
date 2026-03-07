//
//  MultiPassRenderer.swift
//  ShaderTune
//
//  Renderer for multi-pass shader projects with buffer support.
//

import Foundation
import MetalKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Manages rendering for multi-pass shader projects
class MultiPassRenderer: NSObject {
    let device: MTLDevice
    let queue: MTLCommandQueue
    private let defaultLibrary: MTLLibrary

    /// Current project being rendered
    var project: Shader?

    /// Compiled libraries for each pass (keyed by pass name)
    var passLibraries: [String: MTLLibrary] = [:]

    /// Pipeline states for each pass
    private var pipelineStates: [String: MTLRenderPipelineState] = [:]

    /// Offscreen textures for buffer passes (double-buffered for feedback)
    private var bufferTextures: [String: (current: MTLTexture, previous: MTLTexture)] = [:]

    /// Render pass descriptor for offscreen rendering
    private var offscreenDescriptor: MTLRenderPassDescriptor?

    /// Mouse position for uniforms
    var mousePosition: CGPoint = .zero

    /// Start time for animation
    let startTime: TimeInterval = CACurrentMediaTime()

    /// Current texture size
    private var textureSize: CGSize = .zero

    override init() {
        device = MTLCreateSystemDefaultDevice()!
        queue = device.makeCommandQueue()!
        defaultLibrary = device.makeDefaultLibrary()!
        super.init()
    }

    /// Updates the project and rebuilds pipelines
    func setShader(_ project: Shader?, libraries: [String: MTLLibrary]) {
        self.project = project
        self.passLibraries = libraries

        // Rebuild all pipeline states
        rebuildPipelineStates()
    }

    /// Updates the library for a single pass
    func updatePassLibrary(_ library: MTLLibrary, forPass passName: String) {
        passLibraries[passName] = library

        // Rebuild pipeline for this pass
        if let project = project,
            let pass = project.pass(named: passName)
        {
            if let pipeline = makePipelineState(for: pass) {
                pipelineStates[passName] = pipeline
            }
        }
    }

    /// Rebuilds all pipeline states from current libraries
    private func rebuildPipelineStates() {
        pipelineStates.removeAll()

        guard let project = project else { return }

        for pass in project.allPasses {
            if let pipeline = makePipelineState(for: pass) {
                pipelineStates[pass.name] = pipeline
            }
        }
    }

    /// Creates a pipeline state for a shader pass
    private func makePipelineState(for pass: ShaderPass) -> MTLRenderPipelineState? {
        let descriptor = MTLRenderPipelineDescriptor()

        // Always use vertex from default library
        guard let vertexFunc = defaultLibrary.makeFunction(name: "vertexFunc") else {
            return nil
        }
        descriptor.vertexFunction = vertexFunc

        // Use custom fragment if available, otherwise default
        let fragmentFunc: MTLFunction
        if let customLib = passLibraries[pass.name],
            let customFragment = customLib.makeFunction(name: pass.function)
        {
            fragmentFunc = customFragment
        } else if let defaultFragment = defaultLibrary.makeFunction(name: "fragmentFunc") {
            fragmentFunc = defaultFragment
        } else {
            return nil
        }
        descriptor.fragmentFunction = fragmentFunc

        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    /// Ensures buffer textures exist and are the correct size
    private func ensureBufferTextures(size: CGSize) {
        guard let project = project else { return }

        // Check if size changed
        if textureSize == size && !bufferTextures.isEmpty {
            return
        }
        textureSize = size

        let width = Int(size.width)
        let height = Int(size.height)

        // Create textures for each buffer
        for buffer in project.buffers {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: max(1, width),
                height: max(1, height),
                mipmapped: false
            )
            textureDescriptor.usage = [.renderTarget, .shaderRead]
            textureDescriptor.storageMode = .private

            guard let current = device.makeTexture(descriptor: textureDescriptor),
                let previous = device.makeTexture(descriptor: textureDescriptor)
            else {
                continue
            }

            bufferTextures[buffer.name] = (current: current, previous: previous)
        }
    }

    /// Swaps the current and previous textures for feedback buffers
    private func swapFeedbackBuffers() {
        guard let project = project else { return }

        for buffer in project.buffers where buffer.feedback {
            if var textures = bufferTextures[buffer.name] {
                let temp = textures.current
                textures.current = textures.previous
                textures.previous = temp
                bufferTextures[buffer.name] = textures
            }
        }
    }

    /// Renders a single pass to a texture
    private func renderPass(
        _ pass: ShaderPass,
        to texture: MTLTexture,
        commandBuffer: MTLCommandBuffer,
        uniforms: inout Uniforms
    ) {
        guard let pipelineState = pipelineStates[pass.name] else { return }

        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0, green: 0, blue: 0, alpha: 1)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)

        // Bind input buffer textures
        if project != nil {
            for input in pass.inputs {
                if let textures = bufferTextures[input.buffer] {
                    encoder.setFragmentTexture(textures.current, index: input.binding)
                }
            }

            // Bind feedback texture (previous frame) at texture(7)
            if pass.feedback, let textures = bufferTextures[pass.name] {
                encoder.setFragmentTexture(textures.previous, index: 7)
            }
        }

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()
    }
}

extension MultiPassRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Textures will be recreated on next draw if needed
        textureSize = .zero
    }

    func draw(in view: MTKView) {
        guard let project = project else {
            // No project - just clear the screen
            guard let descriptor = view.currentRenderPassDescriptor,
                let drawable = view.currentDrawable,
                let commandBuffer = queue.makeCommandBuffer(),
                let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
            else {
                return
            }
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            return
        }

        // Ensure buffer textures exist
        ensureBufferTextures(size: view.drawableSize)

        guard let drawable = view.currentDrawable,
            let commandBuffer = queue.makeCommandBuffer()
        else {
            return
        }

        // Create uniforms
        let time = Float(CACurrentMediaTime() - startTime)
        let resolution = SIMD2<Float>(Float(view.bounds.size.width), Float(view.bounds.size.height))
        let mouse = SIMD2<Float>(Float(mousePosition.x), Float(mousePosition.y))
        #if os(macOS)
        let scale = NSScreen.main?.backingScaleFactor ?? 1.0
        #else
        let scale = UIScreen.main.scale
        #endif
        var uniforms = Uniforms(
            time: time, mouse: mouse, resolution: resolution, scale: Float(scale))

        // Swap feedback buffers first
        swapFeedbackBuffers()

        // Render passes in dependency order
        let orderedPasses = project.passesInRenderOrder()

        for pass in orderedPasses {
            if pass.isMain {
                // Render main pass to screen
                guard let descriptor = view.currentRenderPassDescriptor,
                    let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
                    let pipelineState = pipelineStates[pass.name]
                else {
                    continue
                }

                encoder.setRenderPipelineState(pipelineState)
                encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)

                // Bind input buffer textures
                for input in pass.inputs {
                    if let textures = bufferTextures[input.buffer] {
                        encoder.setFragmentTexture(textures.current, index: input.binding)
                    }
                }

                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                encoder.endEncoding()
            } else {
                // Render buffer pass to its texture
                if let textures = bufferTextures[pass.name] {
                    renderPass(
                        pass, to: textures.current, commandBuffer: commandBuffer,
                        uniforms: &uniforms)
                }
            }
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
