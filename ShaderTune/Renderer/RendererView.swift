import SwiftUI
import MetalKit

struct RendererView: NSViewRepresentable {
	@Binding var mousePosition: CGPoint
	@Binding var compiledLibrary: MTLLibrary?

	func makeNSView(context: Context) -> MTKView {
		let view = MTKView()
		view.device = context.coordinator.device
		view.delegate = context.coordinator
		view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
		view.colorPixelFormat = .bgra8Unorm
		return view
	}

	func updateNSView(_ nsView: MTKView, context: Context) {
		context.coordinator.mousePosition = mousePosition

		// Update pipeline when library changes
		context.coordinator.updatePipeline(with: compiledLibrary)
	}

	func makeCoordinator() -> Renderer {
		Renderer()
	}
}
