# Swift QuickLink Parser

A Swift package for parsing and processing dynamic URL templates with Raycast-compatible placeholder syntax.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-blue.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2013%20|%20macOS%2010.15%20|%20tvOS%2013%20|%20watchOS%206-lightgrey.svg)](https://swift.org)

## Overview

QuickLinkParser processes URL templates containing dynamic placeholders for user input, clipboard content, selected text, and date/time values. It supports Raycast's template syntax including modifier chains for transforming values.

## Features

- 🎯 **Full Raycast Compatibility** - Supports Raycast's template syntax
- 📋 **System Integration** - Access clipboard and selected text (with permissions)
- 📅 **Date/Time Support** - Custom formats and offsets
- 🔧 **Modifier Chains** - Transform values with trim, encode, case conversion
- 🏗️ **Template Analysis** - Extract requirements before processing
- ✅ **Validation** - Check template syntax with detailed errors
- 🚀 **Cross-Platform** - Works on iOS and macOS

## Installation

### Swift Package Manager

Add QuickLinkParser to your project in Xcode:

1. **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/arraypress/swift-quicklink-parser`
3. Choose the version and add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-quicklink-parser", from: "1.0.0")
]
```

## Quick Start

```swift
import QuickLinkParser

// Simple example
let template = "https://google.com/search?q={selection | percent-encode}"
let result = QuickLinkParser.process(
    template,
    selection: "Swift programming"
)

if result.success {
    print(result.url) // "https://google.com/search?q=Swift%20programming"
}

// With system access (auto-detects clipboard/selection)
let result = QuickLinkParser.processWithSystemAccess(template)
```

## Supported Placeholder Syntax

### User Arguments

```swift
{argument name="query"}                      // Required argument
{argument name="query" default="search"}     // Optional with default
{argument name="lang" options="en, es, fr"}  // Simple dropdown options

// Label|value syntax for user-friendly options
{argument name="filter" options="Videos|EgIQAQ%3D, Channels|EgIQAg%3D"}
```

The `options` attribute supports two formats:
- **Simple**: `"option1, option2, option3"` - Label and value are the same
- **Label|Value**: `"Display Label|actual_value"` - Different label and value

This is particularly useful for:
- Encoded values (YouTube filters, API tokens)
- Technical IDs with friendly names
- URLs with descriptive labels

### System Values

```swift
{clipboard}                                   // Current clipboard content
{selection}                                   // Currently selected text (macOS only)
```

### Date/Time

```swift
{date}                                       // Current date (system format)
{time}                                       // Current time
{datetime}                                   // Date and time combined
{date format="yyyy-MM-dd"}                  // Custom format
{date format="MMM d" offset="+7d"}          // 7 days from now
{date offset="-1M"}                         // 1 month ago
```

### Modifiers

```swift
{clipboard | percent-encode}                 // URL encode
{selection | trim}                           // Remove whitespace
{argument name="text" | lowercase}          // Convert to lowercase
{clipboard | trim | lowercase | percent-encode}  // Chain multiple
```

Available modifiers:
- `percent-encode` - URL encoding for safe URLs
- `trim` - Remove leading/trailing whitespace
- `uppercase` - Convert to UPPERCASE
- `lowercase` - Convert to lowercase
- `json-stringify` - Escape for JSON strings

## Core API

### Processing Templates

```swift
// Manual values - you provide everything
let result = QuickLinkParser.process(
    template,
    arguments: ["query": "test", "lang": "en"],
    clipboard: "clipboard text",
    selection: "selected text",
    date: Date()
)

// With system access - automatically gets clipboard/selection
let result = QuickLinkParser.processWithSystemAccess(
    template,
    arguments: ["query": "test"]
)

// Check the result
if result.success {
    // Use result.url
    if let url = URL(string: result.url) {
        UIApplication.shared.open(url)  // iOS
        NSWorkspace.shared.open(url)    // macOS
    }
} else {
    // Handle missing arguments or errors
    print("Missing: \(result.missingArguments)")
    print("Errors: \(result.errors)")
}
```

### Analyzing Templates

```swift
// Get template requirements before processing
let info = QuickLinkParser.analyze(template)

// Build your UI based on requirements
for arg in info.arguments {
    print("Argument: \(arg.name)")
    print("Required: \(arg.required)")
    print("Default: \(arg.defaultValue ?? "none")")
    print("Options: \(arg.options ?? [])")
}

// Check what system features are needed
if info.usesSelection {
    // May need accessibility permissions on macOS
}
if info.usesClipboard {
    // Will need clipboard access
}
```

### Validation

```swift
// Simple validation
if QuickLinkParser.validate(template) {
    // Template syntax is valid
}

// Detailed validation with error messages
let validation = QuickLinkParser.validateWithErrors(template)
if !validation.isValid {
    for error in validation.errors {
        print("Syntax error: \(error)")
    }
}
```

### System Access Helpers

```swift
// Get clipboard content
if let clipboard = QuickLinkParser.getClipboard() {
    print("Clipboard: \(clipboard)")
}

// Set clipboard content
SystemAccessHelper.setClipboard("New clipboard text")

// Check accessibility permissions (macOS only)
if !QuickLinkParser.hasAccessibilityPermission() {
    // Show explanation to user first
    showPermissionExplanation()
    
    // Then request permission
    SystemAccessHelper.requestAccessibilityPermission()
    // Note: App may need restart after granting
}

// Get selected text (macOS only, requires permission)
if let selection = QuickLinkParser.getSelectedText() {
    print("Selected: \(selection)")
}
```

## Platform-Specific Notes

### macOS

- ✅ Full clipboard support
- ✅ Selected text with accessibility permissions
- ⚠️ Selection requires user approval in System Settings

**Important:** For selected text access, your app must:

1. Add to `Info.plist`:
```xml
<key>NSAccessibilityUsageDescription</key>
<string>This app needs accessibility access to read selected text for QuickLinks</string>
```

2. Handle permissions in your app:
```swift
// Check and request if needed
if !SystemAccessHelper.hasAccessibilityPermission() {
    // Show your custom UI explaining why
    showAccessibilityPermissionDialog()
    
    // Open System Settings
    SystemAccessHelper.openAccessibilitySettings()
    
    // Note: App restart may be required
}
```

### iOS

- ✅ Full clipboard support
- ❌ Selected text not available (iOS limitation)
- ✅ No special permissions required

On iOS, `{selection}` placeholders will return `nil`. Design your templates accordingly or provide clipboard as fallback.

## Real-World Examples

### Google Search

```swift
let template = "https://google.com/search?q={selection | percent-encode}"
let result = QuickLinkParser.process(template, selection: "Swift tutorials")
// Result: "https://google.com/search?q=Swift%20tutorials"
```

### GitHub Repository

```swift
let template = "https://github.com/{argument name=\"owner\"}/{argument name=\"repo\"}"
let result = QuickLinkParser.process(
    template,
    arguments: ["owner": "apple", "repo": "swift"]
)
// Result: "https://github.com/apple/swift"
```

### Google Translate

```swift
let template = """
https://translate.google.com/
?sl={argument name="from" default="auto"}
&tl={argument name="to" default="en"}
&text={selection | percent-encode}
"""

let result = QuickLinkParser.process(
    template,
    arguments: ["from": "es", "to": "en"],
    selection: "Hola mundo"
)
// Result: "https://translate.google.com/?sl=es&tl=en&text=Hola%20mundo"
```

### YouTube Advanced Search

```swift
let template = """
https://youtube.com/results?search_query={argument name="query" | percent-encode}
&sp={argument name="filter" options="Any|, Videos|EgIQAQ%253D%253D, Channels|EgIQAg%253D%253D, 
Playlists|EgIQAw%253D%253D, This Week|CAISBAgCEAE, This Month|CAISBAgDEAE" default=""}
"""

let info = QuickLinkParser.analyze(template)
// info.arguments[1].options contains:
// - ArgumentOption(label: "Any", value: "")
// - ArgumentOption(label: "Videos", value: "EgIQAQ%253D%253D")
// - ArgumentOption(label: "Channels", value: "EgIQAg%253D%253D")
// etc.

// In your UI, show the labels:
Picker("Filter", selection: $selectedFilter) {
    ForEach(info.arguments[1].options ?? [], id: \.value) { option in
        Text(option.label).tag(option.value)
    }
}

// Process with the value:
let result = QuickLinkParser.process(
    template,
    arguments: ["query": "Swift tutorials", "filter": "EgIQAQ%253D%253D"]
)
// Result: "https://youtube.com/results?search_query=Swift%20tutorials&sp=EgIQAQ%253D%253D"
```

```swift
let template = """
https://calendar.google.com/calendar/render
?action=TEMPLATE
&text={argument name="title" | percent-encode}
&dates={date format="yyyyMMdd'T'HHmmss"}/{date format="yyyyMMdd'T'HHmmss" offset="+1h"}
"""

let result = QuickLinkParser.process(
    template,
    arguments: ["title": "Team Meeting"]
)
// Creates a 1-hour calendar event starting now
```

### Amazon Product Search

```swift
let template = "https://amazon.com/s?k={clipboard | trim | percent-encode}"
let result = QuickLinkParser.processWithSystemAccess(template)
// Uses current clipboard content
```

## Building User Interfaces

Here's how to build a dynamic UI based on template requirements:

```swift
import SwiftUI
import QuickLinkParser

struct QuickLinkView: View {
    let template: String
    @State private var arguments: [String: String] = [:]
    @State private var error: String?
    
    var templateInfo: TemplateInfo {
        QuickLinkParser.analyze(template)
    }
    
    var body: some View {
        Form {
            // Generate input fields for each argument
            ForEach(templateInfo.arguments, id: \.name) { arg in
                Section(arg.name) {
                    if let options = arg.options {
                        // Dropdown for options
                        Picker(arg.name, selection: binding(for: arg)) {
                            ForEach(options, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                    } else {
                        // Text field for free input
                        TextField(
                            arg.defaultValue ?? "Enter \(arg.name)",
                            text: binding(for: arg)
                        )
                    }
                    
                    if arg.required {
                        Text("Required").font(.caption).foregroundColor(.red)
                    }
                }
            }
            
            // System requirements
            if templateInfo.usesClipboard {
                Text("📋 Will use clipboard content").font(.caption)
            }
            if templateInfo.usesSelection {
                Text("✂️ Will use selected text").font(.caption)
            }
            
            Button("Open Link") {
                openQuickLink()
            }
            
            if let error = error {
                Text(error).foregroundColor(.red)
            }
        }
    }
    
    func binding(for arg: ArgumentInfo) -> Binding<String> {
        Binding(
            get: { arguments[arg.name] ?? arg.defaultValue ?? "" },
            set: { arguments[arg.name] = $0 }
        )
    }
    
    func openQuickLink() {
        let result = QuickLinkParser.processWithSystemAccess(
            template,
            arguments: arguments
        )
        
        if result.success {
            if let url = URL(string: result.url) {
                #if os(iOS)
                UIApplication.shared.open(url)
                #elseif os(macOS)
                NSWorkspace.shared.open(url)
                #endif
            }
        } else {
            error = "Missing: \(result.missingArguments.joined(separator: ", "))"
        }
    }
}
```

## Data Types Reference

### ProcessResult

```swift
struct ProcessResult {
    let url: String                  // Processed URL ready to use
    let missingArguments: [String]   // Required args not provided
    let success: Bool                 // true if all requirements met
    let errors: [String]              // Any parsing errors
}
```

### TemplateInfo

```swift
struct TemplateInfo {
    let arguments: [ArgumentInfo]    // All arguments found
    let usesClipboard: Bool          // Uses {clipboard}
    let usesSelection: Bool          // Uses {selection}
    let usesDate: Bool               // Uses date/time placeholders
    let dateFormats: [String]        // Custom date formats found
    
    var requiredArguments: [ArgumentInfo]  // Args without defaults
    var optionalArguments: [ArgumentInfo]  // Args with defaults
}
```

### ArgumentInfo

```swift
struct ArgumentInfo {
    let name: String                 // Argument identifier
    let defaultValue: String?        // Default if specified
    let options: [ArgumentOption]?   // Dropdown options if specified
    let required: Bool               // true if no default value
    
    var hasOptions: Bool            // Has dropdown options
    var hasDefault: Bool            // Has a default value
}

struct ArgumentOption {
    let label: String               // Display label ("Videos")
    let value: String               // Actual value ("EgIQAQ%253D%253D")
}
```

## Advanced Usage

### Custom Date Formats

```swift
// ISO 8601
{date format="yyyy-MM-dd'T'HH:mm:ssZ"}

// Human readable
{date format="EEEE, MMMM d, yyyy 'at' h:mm a"}

// File naming
{date format="yyyyMMdd_HHmmss"}
```

### Chaining Multiple Modifiers

```swift
// Process in order: trim → lowercase → encode
{clipboard | trim | lowercase | percent-encode}

// Each modifier transforms the previous result
"  HELLO WORLD  " → "HELLO WORLD" → "hello world" → "hello%20world"
```

### Fallback Patterns

```swift
// In your app logic
let result = QuickLinkParser.process(
    template,
    selection: getSelectedText(),
    clipboard: getSelectedText() ?? getClipboard()  // Fallback
)
```

## Performance

QuickLinkParser is optimized for speed:

- ⚡ ~0.1ms for simple templates
- ⚡ ~0.5ms for complex templates with multiple placeholders
- ⚡ Efficient regex-based parsing
- ⚡ Minimal memory allocation

Suitable for real-time processing in response to hotkeys or user actions.

## Testing

The package includes comprehensive tests:

```bash
# Run all tests
swift test

# Run with coverage
swift test --enable-code-coverage

# Run specific tests
swift test --filter QuickLinkParserTests.testGoogleSearchTemplate
```

## Project Structure

```
QuickLinkParser/
├── Sources/
│   └── QuickLinkParser/
│       ├── QuickLinkParser.swift      # Main API
│       ├── Models.swift               # Data types
│       └── SystemAccessHelper.swift   # Platform-specific
└── Tests/
    └── QuickLinkParserTests/
        └── QuickLinkParserTests.swift # Test suite
```

## Requirements

- **Swift 5.9+**
- **iOS 13.0+** / **macOS 10.15+** / **tvOS 13.0+** / **watchOS 6.0+**
- **Xcode 14.0+** (for development)

## Limitations

- **iOS**: Selected text access not available (platform limitation)
- **macOS**: Selection requires accessibility permissions
- **Clipboard**: Only supports current clipboard (no history)

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

QuickLinkParser is available under the MIT license. See LICENSE file for details.

## Acknowledgments

- Syntax compatible with [Raycast](https://raycast.com) QuickLinks
- Inspired by URL template systems and text expansion tools

---

Made with ❤️ for the Swift community
