import Foundation
import MetalKit

struct Uniforms {
	let time: Float
	let mouse: SIMD2<Float>
	let resolution: SIMD2<Float>
	let scale: Float
}

class Renderer: NSObject {
	let device: MTLDevice
	let queue: MTLCommandQueue
	let pipelineState: MTLRenderPipelineState
	
	var mousePosition: CGPoint = .zero
	let startTime: TimeInterval = CACurrentMediaTime()
	
	override init() {
		device = MTLCreateSystemDefaultDevice()!
		queue = device.makeCommandQueue()!
		pipelineState = Self.makePipelineState(device: device)
		super.init()
	}
	
	private static func makePipelineState(device: MTLDevice) -> MTLRenderPipelineState {
		let library = device.makeDefaultLibrary()!
		let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
		pipelineStateDescriptor.vertexFunction = library.makeFunction(name: "vertexFunc")!
		pipelineStateDescriptor.fragmentFunction = library.makeFunction(name: "fragmentFunc")!
		pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		return try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
	}
}

extension Renderer: MTKViewDelegate {
	
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
	}
	
	func draw(in view: MTKView) {
		guard let descriptor = view.currentRenderPassDescriptor,
			  let drawable = view.currentDrawable,
			  let commandBuffer = queue.makeCommandBuffer(),
			  let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
			return
		}
		
		let time = Float(CACurrentMediaTime() - startTime)
		let resolution = SIMD2<Float>(Float(view.bounds.size.width), Float(view.bounds.size.height))
		let mouse = SIMD2<Float>(Float(mousePosition.x), Float(mousePosition.y))
		let scale = NSScreen.main!.backingScaleFactor
		var uniforms = Uniforms(time: time, mouse: mouse, resolution: resolution, scale: Float(scale))
		
		commandEncoder.setRenderPipelineState(pipelineState)
		commandEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
		commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
		commandEncoder.endEncoding()
		
		commandBuffer.present(drawable)
		commandBuffer.commit()
	}
}
