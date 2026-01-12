# ShaderTune

> **⚠️ Early Prototype / Work in Progress**
> This is an experimental Metal shader editor in active development. Expect bugs, missing features, and breaking changes.

A live Metal shader editor for macOS that provides real-time compilation and rendering of Metal Shading Language (MSL) shaders.

## Features

- **Live Preview**: See your shader render in real-time as you code
- **Syntax Highlighting**: Full MSL syntax support with keywords and functions
- **Error Reporting**: Inline compilation errors with line/column information
- **Code Completion**: Ctrl+Space for Metal API completions
- **File Navigation**: Browse and edit shader files from your project
- **Auto-Compile**: Optional debounced compilation as you type

## Getting Started

1. Open ShaderTune.xcodeproj in Xcode
2. Build and run (Cmd+R)
3. Open a folder containing .metal files (Cmd+O)
4. Select a shader file from the sidebar
5. Edit your fragment shader and see the results live

## Current Limitations

- Fragment shaders only (vertex shader is provided automatically)
- No shader preview export or recording
- Basic file operations (no create/delete/rename)

## Requirements

- macOS 14.0+
- Xcode 15.0+
- Metal-compatible GPU

## Development

### Code Formatting

This project uses Swift's built-in formatter to maintain consistent code style.

**Format all Swift files:**
```bash
swift format format -i -r ShaderTune/
```

**Check formatting without modifying files:**
```bash
swift format lint -r ShaderTune/
```

The project's formatting rules are defined in `.swift-format` at the repository root.
