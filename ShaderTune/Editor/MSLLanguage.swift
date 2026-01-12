import Foundation
import LanguageSupport
import RegexBuilder

/// MSL keyword and identifier definitions
private let mslReservedIdentifiers: [String] = {
    var identifiers: [String] = []

    // Function qualifiers
    identifiers += ["kernel", "vertex", "fragment"]

    // Address space qualifiers
    identifiers += ["constant", "device", "threadgroup", "threadgroup_imageblock"]

    // Type qualifiers
    identifiers += ["const", "constexpr", "static", "volatile"]

    // Control flow
    identifiers += ["if", "else", "switch", "case", "default"]
    identifiers += ["for", "while", "do", "break", "continue", "return"]
    identifiers += ["discard_fragment"]

    // C++ base
    identifiers += ["namespace", "using", "struct", "enum", "typedef"]
    identifiers += ["class", "template", "typename", "sizeof", "operator"]
    identifiers += ["public", "private", "protected"]
    identifiers += ["true", "false", "nullptr"]
    identifiers += ["auto", "inline", "explicit"]

    // Scalar types
    identifiers += ["void", "bool", "char", "uchar", "short", "ushort"]
    identifiers += ["int", "uint", "half", "float"]

    // Vector types
    identifiers += ["bool2", "bool3", "bool4"]
    identifiers += ["char2", "char3", "char4"]
    identifiers += ["uchar2", "uchar3", "uchar4"]
    identifiers += ["short2", "short3", "short4"]
    identifiers += ["ushort2", "ushort3", "ushort4"]
    identifiers += ["int2", "int3", "int4"]
    identifiers += ["uint2", "uint3", "uint4"]
    identifiers += ["half2", "half3", "half4"]
    identifiers += ["float2", "float3", "float4"]

    // Packed vectors
    identifiers += ["packed_float2", "packed_float3", "packed_float4"]
    identifiers += ["packed_half2", "packed_half3", "packed_half4"]

    // Matrix types
    identifiers += ["float2x2", "float2x3", "float2x4"]
    identifiers += ["float3x2", "float3x3", "float3x4"]
    identifiers += ["float4x2", "float4x3", "float4x4"]

    // Texture types
    identifiers += ["texture1d", "texture1d_array"]
    identifiers += ["texture2d", "texture2d_array", "texture2d_ms"]
    identifiers += ["texture3d"]
    identifiers += ["texturecube", "texturecube_array"]

    // Depth textures
    identifiers += ["depth2d", "depth2d_array", "depthcube"]

    // Sampler types
    identifiers += ["sampler", "samplerstate"]

    // Common built-in functions
    identifiers += ["abs", "acos", "asin", "atan", "atan2"]
    identifiers += ["ceil", "clamp", "cos", "cross"]
    identifiers += ["degrees", "distance", "dot"]
    identifiers += ["exp", "exp2", "floor", "fma", "fmax", "fmin", "fmod", "fract"]
    identifiers += ["length", "log", "log2"]
    identifiers += ["max", "min", "mix"]
    identifiers += ["normalize"]
    identifiers += ["pow", "radians", "reflect", "refract"]
    identifiers += ["round", "rsqrt"]
    identifiers += ["saturate", "sign", "sin", "smoothstep", "sqrt", "step"]
    identifiers += ["tan", "trunc"]
    identifiers += ["faceforward"]
    identifiers += ["sample", "read", "write", "gather"]

    return identifiers
}()

private let mslReservedOperators = [
    ".", ",", ":", ";", "=", "@", "#", "&", "->", "`", "?", "!", "~",
]

extension LanguageConfiguration {

    /// Language configuration for Metal Shading Language (MSL)
    ///
    public static func msl(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        let numberRegex: Regex<Substring> = Regex {
            Optionally { "-" }
            ChoiceOf {
                Regex {
                    /0x/
                    OneOrMore { /[0-9a-fA-F]/ }
                }  // Hex
                Regex {
                    OneOrMore { /[0-9]/ }
                    "."
                    OneOrMore { /[0-9]/ }
                }  // Float
                Regex { OneOrMore { /[0-9]/ } }  // Integer
            }
            Optionally { /[fFuU]/ }  // Suffix
        }

        let identifierRegex: Regex<Substring> = Regex {
            /[a-zA-Z_]/
            ZeroOrMore {
                /[a-zA-Z0-9_]/
            }
        }

        let operatorRegex: Regex<Substring> = Regex {
            OneOrMore {
                /[+\-*\/%=<>!&|^~?:]/
            }
        }

        return LanguageConfiguration(
            name: "Metal",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: true,
            stringRegex: /\"(?:\\\"|[^\"])*+\"/,
            characterRegex: /'(?:\\'|[^'])+'/,
            numberRegex: numberRegex,
            singleLineComment: "//",
            nestedComment: (open: "/*", close: "*/"),
            identifierRegex: identifierRegex,
            operatorRegex: operatorRegex,
            reservedIdentifiers: mslReservedIdentifiers,
            reservedOperators: mslReservedOperators,
            languageService: languageService
        )
    }
}
