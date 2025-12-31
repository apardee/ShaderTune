# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShaderTune is a SwiftUI application for macOS/iOS. The project is currently in early development stages.

## Build & Run Commands

**Build the project:**
```bash
xcodebuild -project ShaderTune.xcodeproj -scheme ShaderTune -configuration Debug build
```

**Build for release:**
```bash
xcodebuild -project ShaderTune.xcodeproj -scheme ShaderTune -configuration Release build
```

**Clean build:**
```bash
xcodebuild -project ShaderTune.xcodeproj -scheme ShaderTune clean
```

**Running in Xcode:**
Open `ShaderTune.xcodeproj` in Xcode and use Cmd+R to build and run.

## Architecture

**Entry Point:**
- `ShaderTune/ShaderTuneApp.swift` - Main app entry point using `@main` attribute

**UI Structure:**
- `ShaderTune/ContentView.swift` - Root view of the application
- SwiftUI-based architecture with declarative UI patterns

**Assets:**
- `ShaderTune/Assets.xcassets/` - Image and color assets

## Development Notes

- This is a standard Xcode project (not a Swift Package or CocoaPods/SPM workspace)
- Target: ShaderTune
- Build configurations: Debug and Release
- SwiftUI framework is used for UI development

## Syntax Highlighting

ShaderTune uses **C++ syntax highlighting** for Metal shaders (since MSL is based on C++14). While this provides basic syntax highlighting, it doesn't highlight MSL-specific keywords like `kernel`, `vertex`, `fragment`, or types like `float4`, `texture2d`, etc.

A complete Metal Shading Language syntax definition is available in `ShaderTune/Resources/metal.js` for future use when switching to an editor that supports custom language definitions.

See `ShaderTune/Resources/README.md` for detailed information about syntax highlighting and upgrade paths.
