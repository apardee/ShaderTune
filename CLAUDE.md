# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShaderTune is a SwiftUI Metal shader editor for macOS/iOS that provides real-time compilation, syntax highlighting, error reporting, and code completion for Metal Shading Language (MSL).

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

**Core UI:**
- `ShaderTune/ContentView.swift` - Main view with toolbar, editor, and feature integration
- SwiftUI-based architecture with declarative UI patterns

**Editor:**
- `ShaderTune/Editor/ShaderEditorView.swift` - CodeEditorView-based editor with native MSL syntax highlighting
- `ShaderTune/Editor/MSLLanguage.swift` - Metal Shading Language definition with 200+ keywords, types, and functions
- Uses **CodeEditorView** package from mchakravarty/CodeEditorView (TextKit 2-based)
- **Dark mode theme** enabled by default

**Metal Compiler Integration:**
- `ShaderTune/Services/MetalCompilerService.swift` - Real-time Metal shader compilation via MTLDevice
- Parses compiler errors with regex: `program_source:(\d+):(\d+):\s*(error|warning):\s*(.+)`
- Errors displayed inline in the editor with native TextKit 2 messaging system

**Models:**
- `ShaderTune/Models/CompilationDiagnostic.swift` - Compilation error/warning model
- `ShaderTune/Models/ShaderTemplate.swift` - 10 built-in shader templates (Fragment, Vertex, Compute, Complete Pipelines)
- `ShaderTune/Models/CompletionItem.swift` - Code completion item model

**Editor Features:**
- `ShaderTune/Editor/TemplatePickerView.swift` - Template selection UI
- `ShaderTune/Editor/FindReplaceView.swift` - Find/replace functionality (Cmd+F)
- `ShaderTune/Editor/CompletionView.swift` - Code completion popup (Ctrl+Space)
- `ShaderTune/Editor/CompletionProvider.swift` - Completion filtering and trigger detection
- `ShaderTune/Editor/MetalKeywordDatabase.swift` - 200+ Metal keywords, types, and functions

**Assets:**
- `ShaderTune/Assets.xcassets/` - Image and color assets

## Features

### Code Editor
- Native MSL syntax highlighting (200+ keywords, types, functions)
- Dark mode theme with Xcode-like colors
- Line numbers and current line highlighting
- Inline error/warning display with hover tooltips
- Monospaced font (SF Mono Medium, 13pt)

### Metal Compiler Integration
- Real-time shader compilation with 1-second debounce
- Auto-compile toggle
- Manual compile button
- Error parsing from Metal compiler output
- Inline error display at source location

### Code Completion
- Ctrl+Space to trigger completion popup
- Auto-trigger after 2+ characters
- 200+ completions for keywords, types, and functions
- Arrow keys to navigate, Enter/Tab to select
- Filters by prefix matching

### Templates
- 10 built-in shader templates:
  - Fragment shaders (gradient, textures, procedural)
  - Vertex shaders (transforms, attributes)
  - Compute kernels (image processing, parallel computation)
  - Complete pipelines (vertex + fragment)
- Template picker UI with categorized display

### Find/Replace
- Cmd+F keyboard shortcut
- Find Next, Replace, Replace All functionality
- Basic string matching (case-sensitive)

## Development Notes

- This is a standard Xcode project (not a Swift Package or CocoaPods/SPM workspace)
- Target: ShaderTune
- Build configurations: Debug and Release
- Swift Package Dependencies:
  - **CodeEditorView** (mchakravarty/CodeEditorView @ main)
  - **LanguageSupport** (included with CodeEditorView)
  - **Rearrange** (dependency of CodeEditorView)

## Known Limitations

- Cursor position tracking is simplified (end of text) for code completion
- Find/Replace doesn't track cursor position for "Find Next"
- Code completion popup has fixed positioning (x:100, y:100)
- Templates are hardcoded (not user-customizable)
- No shader preview/rendering (text editor only)

## Upgrade Paths

For future enhancements, consider:
1. **Full cursor tracking** - Track actual text cursor position for better completion insertion
2. **Advanced find/replace** - Regex support, case-insensitive matching, highlight all matches
3. **Shader preview** - Add Metal rendering view to preview shader output
4. **Custom templates** - Allow users to create and save their own shader templates
5. **Language server** - Integrate with custom MSL language server for advanced completion
6. **Settings panel** - User-configurable editor theme, font size, keybindings
7. **File management** - Open/save shader files, recent files list
