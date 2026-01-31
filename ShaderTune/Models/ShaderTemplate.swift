//
//  ShaderTemplate.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 12/31/25.
//

import Foundation

enum ShaderTemplate {
    static let defaultShader = """
        #include <metal_stdlib>
        using namespace metal;

        fragment float4 fragmentShader(
            float4 position [[position]],
            constant float2 &resolution [[buffer(0)]],
            constant float &time [[buffer(1)]]
        ) {
            float2 uv = position.xy / resolution;
            return float4(uv.x, uv.y, 0.5 + 0.5 * sin(time), 1.0);
        }
        """
}
