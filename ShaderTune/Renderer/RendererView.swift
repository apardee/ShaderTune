import MetalKit
import SwiftUI

#if os(macOS)
struct RendererView: NSViewRepresentable {
    @Binding var mousePosition: CGPoint
    @Binding var compiledLibrary: MTLLibrary?

    // Multi-pass project support
    @Binding var project: ShaderProject?
    @Binding var passLibraries: [String: MTLLibrary]

    init(
        mousePosition: Binding<CGPoint>,
        compiledLibrary: Binding<MTLLibrary?>,
        project: Binding<ShaderProject?> = .constant(nil),
        passLibraries: Binding<[String: MTLLibrary]> = .constant([:])
    ) {
        self._mousePosition = mousePosition
        self._compiledLibrary = compiledLibrary
        self._project = project
        self._passLibraries = passLibraries
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        // Use appropriate device based on renderer type
        if project != nil {
            view.device = context.coordinator.multiPassRenderer.device
            view.delegate = context.coordinator.multiPassRenderer
        } else {
            view.device = context.coordinator.singlePassRenderer.device
            view.delegate = context.coordinator.singlePassRenderer
        }
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.colorPixelFormat = .bgra8Unorm
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        let coordinator = context.coordinator

        if let project = project {
            // Multi-pass mode
            nsView.device = coordinator.multiPassRenderer.device
            nsView.delegate = coordinator.multiPassRenderer
            coordinator.multiPassRenderer.mousePosition = mousePosition
            coordinator.multiPassRenderer.setProject(project, libraries: passLibraries)
        } else {
            // Single-pass mode
            nsView.device = coordinator.singlePassRenderer.device
            nsView.delegate = coordinator.singlePassRenderer
            coordinator.singlePassRenderer.mousePosition = mousePosition
            coordinator.singlePassRenderer.updatePipeline(with: compiledLibrary)
        }
    }

    func makeCoordinator() -> RendererCoordinator {
        RendererCoordinator()
    }
}
#else
struct RendererView: UIViewRepresentable {
    @Binding var mousePosition: CGPoint
    @Binding var compiledLibrary: MTLLibrary?

    // Multi-pass project support
    @Binding var project: ShaderProject?
    @Binding var passLibraries: [String: MTLLibrary]

    init(
        mousePosition: Binding<CGPoint>,
        compiledLibrary: Binding<MTLLibrary?>,
        project: Binding<ShaderProject?> = .constant(nil),
        passLibraries: Binding<[String: MTLLibrary]> = .constant([:])
    ) {
        self._mousePosition = mousePosition
        self._compiledLibrary = compiledLibrary
        self._project = project
        self._passLibraries = passLibraries
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        // Use appropriate device based on renderer type
        if project != nil {
            view.device = context.coordinator.multiPassRenderer.device
            view.delegate = context.coordinator.multiPassRenderer
        } else {
            view.device = context.coordinator.singlePassRenderer.device
            view.delegate = context.coordinator.singlePassRenderer
        }
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.colorPixelFormat = .bgra8Unorm
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        let coordinator = context.coordinator

        if let project = project {
            // Multi-pass mode
            uiView.device = coordinator.multiPassRenderer.device
            uiView.delegate = coordinator.multiPassRenderer
            coordinator.multiPassRenderer.mousePosition = mousePosition
            coordinator.multiPassRenderer.setProject(project, libraries: passLibraries)
        } else {
            // Single-pass mode
            uiView.device = coordinator.singlePassRenderer.device
            uiView.delegate = coordinator.singlePassRenderer
            coordinator.singlePassRenderer.mousePosition = mousePosition
            coordinator.singlePassRenderer.updatePipeline(with: compiledLibrary)
        }
    }

    func makeCoordinator() -> RendererCoordinator {
        RendererCoordinator()
    }
}
#endif

/// Coordinator that holds both single-pass and multi-pass renderers
class RendererCoordinator {
    let singlePassRenderer: Renderer
    let multiPassRenderer: MultiPassRenderer

    init() {
        singlePassRenderer = Renderer()
        multiPassRenderer = MultiPassRenderer()
    }
}
