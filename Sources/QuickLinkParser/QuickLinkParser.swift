//
//  QuickLinkParser.swift
//  QuickLinkParser
//
//  Main API for parsing and processing QuickLink templates with Raycast-compatible syntax
//  Created on 26/01/2025.
//

import Foundation

/// The main parser for QuickLink templates supporting Raycast-compatible placeholder syntax.
///
/// QuickLinkParser processes URL templates containing dynamic placeholders such as user arguments,
/// clipboard content, selected text, and date/time values. It supports modifier chains for
/// transforming values (e.g., URL encoding, trimming, case conversion).
///
/// ## Supported Placeholders
///
/// ### User Arguments
/// ```
/// {argument name="query"}                      // Required argument
/// {argument name="query" default="search"}     // Optional with default
/// {argument name="lang" options="en, es, fr"}  // With predefined options
/// {argument name="filter" options="Videos|EgIQAQ%3D, Channels|EgIQAg%3D"}  // Label|value syntax
/// ```
///
/// ### System Values
/// ```
/// {clipboard}                                   // Current clipboard content
/// {selection}                                   // Currently selected text
/// ```
///
/// ### Date/Time
/// ```
/// {date}                                       // Current date (system format)
/// {time}                                       // Current time (system format)
/// {datetime}                                   // Date and time combined
/// {date format="yyyy-MM-dd"}                  // Custom format
/// {date format="MMM d" offset="+7d"}          // With offset
/// ```
///
/// ### Modifiers
/// ```
/// {clipboard | percent-encode}                 // URL encode
/// {selection | trim | lowercase}               // Chain modifiers
/// ```
///
/// ## Basic Usage
///
/// ```swift
/// let template = "https://google.com/search?q={selection | percent-encode}"
///
/// // Option 1: Manual values
/// let result = QuickLinkParser.process(
///     template,
///     selection: "Hello World"
/// )
///
/// // Option 2: With system access
/// let result = QuickLinkParser.processWithSystemAccess(template)
/// ```
public struct QuickLinkParser {
    
    // MARK: - Main Processing Functions
    
    /// Processes a template string by replacing all placeholders with provided values.
    ///
    /// This is the core parsing function that handles all placeholder types including
    /// arguments, clipboard, selection, and date/time placeholders. It also applies
    /// any specified modifiers in the order they appear.
    ///
    /// - Parameters:
    ///   - template: The template string containing placeholders in Raycast syntax
    ///   - arguments: Dictionary of argument name to value mappings for {argument} placeholders
    ///   - clipboard: The clipboard content to use for {clipboard} placeholders
    ///   - selection: The selected text to use for {selection} placeholders
    ///   - date: The date to use for date/time placeholders (defaults to current date)
    ///
    /// - Returns: A `ProcessResult` containing the processed URL and any missing required arguments
    ///
    /// - Note: Required arguments without defaults that aren't provided will be listed in
    ///         the result's `missingArguments` array.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let template = "https://translate.google.com/?text={selection | percent-encode}&to={argument name=\"lang\" default=\"en\"}"
    /// let result = QuickLinkParser.process(
    ///     template,
    ///     arguments: ["lang": "es"],
    ///     selection: "Hello World"
    /// )
    /// // result.url = "https://translate.google.com/?text=Hello%20World&to=es"
    /// ```
    public static func process(
        _ template: String,
        arguments: [String: String] = [:],
        clipboard: String? = nil,
        selection: String? = nil,
        date: Date = Date()
    ) -> ProcessResult {
        var processedString = template
        var missingArguments: [String] = []
        var errors: [String] = []
        
        // Find all placeholders using regex
        let pattern = #"\{([^}]+)\}"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: template, options: [], range: NSRange(location: 0, length: template.utf16.count))
            
            // Process matches in reverse order to maintain string indices
            for match in matches.reversed() {
                guard let range = Range(match.range, in: template) else { continue }
                
                guard let contentRange = Range(match.range(at: 1), in: template) else { continue }
                let placeholderContent = String(template[contentRange])
                
                // Process the placeholder
                let result = processPlaceholder(
                    placeholderContent,
                    arguments: arguments,
                    clipboard: clipboard,
                    selection: selection,
                    date: date
                )
                
                switch result {
                case .success(let value):
                    processedString.replaceSubrange(range, with: value)
                case .missingArgument(let name):
                    missingArguments.append(name)
                case .error(let error):
                    errors.append(error)
                }
            }
        } catch {
            errors.append("Failed to parse template: \(error.localizedDescription)")
        }
        
        return ProcessResult(
            url: processedString,
            missingArguments: missingArguments,
            success: missingArguments.isEmpty && errors.isEmpty,
            errors: errors
        )
    }
    
    /// Processes a template with automatic system access for clipboard and selection.
    ///
    /// This convenience method automatically retrieves the current clipboard content
    /// and attempts to get the selected text (on supported platforms with appropriate
    /// permissions) before processing the template.
    ///
    /// - Parameters:
    ///   - template: The template string containing placeholders
    ///   - arguments: Dictionary of argument name to value mappings
    ///   - date: The date to use for date/time placeholders (defaults to current date)
    ///
    /// - Returns: A `ProcessResult` containing the processed URL and any issues
    ///
    /// - Note: Selection access requires accessibility permissions on macOS.
    ///         If permissions are not granted, selection placeholders will be treated as missing.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let template = "https://google.com/search?q={clipboard | percent-encode}"
    /// let result = QuickLinkParser.processWithSystemAccess(template)
    /// // Automatically uses current clipboard content
    /// ```
    public static func processWithSystemAccess(
        _ template: String,
        arguments: [String: String] = [:],
        date: Date = Date()
    ) -> ProcessResult {
        let clipboard = SystemAccessHelper.getClipboard()
        let selection = SystemAccessHelper.getSelectedText()
        
        return process(
            template,
            arguments: arguments,
            clipboard: clipboard,
            selection: selection,
            date: date
        )
    }
    
    // MARK: - Template Analysis
    
    /// Analyzes a template to extract information about required inputs.
    ///
    /// This method parses the template without processing it, returning structured
    /// information about what inputs are needed. This is useful for building dynamic
    /// user interfaces or validating templates.
    ///
    /// - Parameter template: The template string to analyze
    ///
    /// - Returns: A `TemplateInfo` object containing details about all placeholders
    ///
    /// ## Example
    ///
    /// ```swift
    /// let template = "https://api.example.com?key={argument name=\"api_key\"}&q={selection}"
    /// let info = QuickLinkParser.analyze(template)
    /// // info.arguments = [ArgumentInfo(name: "api_key", required: true)]
    /// // info.usesSelection = true
    /// ```
    public static func analyze(_ template: String) -> TemplateInfo {
        var arguments: [ArgumentInfo] = []
        var usesClipboard = false
        var usesSelection = false
        var usesDate = false
        var dateFormats: [String] = []
        
        let pattern = #"\{([^}]+)\}"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: template, options: [], range: NSRange(location: 0, length: template.utf16.count))
            
            for match in matches {
                guard let contentRange = Range(match.range(at: 1), in: template) else { continue }
                let content = String(template[contentRange])
                
                // Remove modifiers to analyze the base placeholder
                let basePlaceholder = content.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces) ?? content
                
                if basePlaceholder.hasPrefix("argument") {
                    // For arguments, we need to pass the full content (including the "argument" prefix)
                    if let argInfo = parseArgumentInfo(from: content) {
                        // Avoid duplicates
                        if !arguments.contains(where: { $0.name == argInfo.name }) {
                            arguments.append(argInfo)
                        }
                    }
                } else if basePlaceholder == "clipboard" {
                    usesClipboard = true
                } else if basePlaceholder == "selection" {
                    usesSelection = true
                } else if basePlaceholder.hasPrefix("date") || basePlaceholder == "time" || basePlaceholder == "datetime" {
                    usesDate = true
                    
                    // Extract format if present
                    if let format = extractValue(from: basePlaceholder, key: "format") {
                        dateFormats.append(format)
                    }
                }
            }
        } catch {
            // Return partial info even if parsing fails
        }
        
        return TemplateInfo(
            arguments: arguments,
            usesClipboard: usesClipboard,
            usesSelection: usesSelection,
            usesDate: usesDate,
            dateFormats: dateFormats
        )
    }
    
    // MARK: - Validation
    
    /// Validates whether a template string has correct syntax.
    ///
    /// Performs basic validation to ensure all placeholders are properly formed
    /// and closed. This is a quick check that returns a boolean result.
    ///
    /// - Parameter template: The template string to validate
    ///
    /// - Returns: `true` if the template syntax is valid, `false` otherwise
    ///
    /// ## Example
    ///
    /// ```swift
    /// let valid = QuickLinkParser.validate("https://example.com?q={clipboard}")
    /// // valid = true
    ///
    /// let invalid = QuickLinkParser.validate("https://example.com?q={clipboard")
    /// // invalid = false (unclosed placeholder)
    /// ```
    public static func validate(_ template: String) -> Bool {
        return validateWithErrors(template).isValid
    }
    
    /// Validates a template and returns detailed error information.
    ///
    /// Performs comprehensive validation of the template syntax, returning specific
    /// error messages for any issues found. This is useful for providing user feedback
    /// when templates are being created or edited.
    ///
    /// - Parameter template: The template string to validate
    ///
    /// - Returns: A `ValidationResult` containing validation status and any error messages
    ///
    /// ## Example
    ///
    /// ```swift
    /// let result = QuickLinkParser.validateWithErrors("https://example.com?q={clipboard")
    /// // result.isValid = false
    /// // result.errors = ["Unclosed placeholder starting at position 23"]
    /// ```
    public static func validateWithErrors(_ template: String) -> ValidationResult {
        var errors: [String] = []
        
        // Check for balanced braces
        var openCount = 0
        var lastOpenIndex = -1
        
        for (index, char) in template.enumerated() {
            if char == "{" {
                openCount += 1
                lastOpenIndex = index
            } else if char == "}" {
                openCount -= 1
                if openCount < 0 {
                    errors.append("Unexpected closing brace at position \(index)")
                    openCount = 0  // Reset to continue checking
                }
            }
        }
        
        if openCount > 0 {
            errors.append("Unclosed placeholder starting at position \(lastOpenIndex)")
        }
        
        // Validate individual placeholders
        let pattern = #"\{([^}]+)\}"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: template, options: [], range: NSRange(location: 0, length: template.utf16.count))
            
            for match in matches {
                guard let contentRange = Range(match.range(at: 1), in: template) else { continue }
                let content = String(template[contentRange])
                
                // Validate placeholder content
                if let error = validatePlaceholderContent(content) {
                    errors.append(error)
                }
            }
        } catch {
            errors.append("Failed to parse template: \(error.localizedDescription)")
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors
        )
    }
    
    // MARK: - System Access Helpers
    
    /// Retrieves the current clipboard content.
    ///
    /// Cross-platform method to get the current clipboard text content.
    /// Returns `nil` if the clipboard is empty or doesn't contain text.
    ///
    /// - Returns: The current clipboard text content, or `nil` if unavailable
    ///
    /// ## Platform Support
    /// - macOS: Uses `NSPasteboard`
    /// - iOS: Uses `UIPasteboard`
    public static func getClipboard() -> String? {
        return SystemAccessHelper.getClipboard()
    }
    
    /// Attempts to retrieve currently selected text.
    ///
    /// Tries to get the currently selected text from the frontmost application.
    /// This requires accessibility permissions on macOS.
    ///
    /// - Returns: The selected text, or `nil` if unavailable or permissions not granted
    ///
    /// - Note: On macOS, this requires accessibility permissions. The app should
    ///         check and request permissions using `AXIsProcessTrusted()`.
    ///
    /// ## Platform Support
    /// - macOS: Requires accessibility permissions
    /// - iOS: Not currently supported (returns `nil`)
    public static func getSelectedText() -> String? {
        return SystemAccessHelper.getSelectedText()
    }
    
    /// Checks if the app has accessibility permissions (macOS only).
    ///
    /// Determines whether the current process has been granted accessibility
    /// permissions, which are required for getting selected text on macOS.
    ///
    /// - Returns: `true` if permissions are granted or not needed (iOS), `false` otherwise
    public static func hasAccessibilityPermission() -> Bool {
        return SystemAccessHelper.hasAccessibilityPermission()
    }
}

// MARK: - Private Processing Helpers

private extension QuickLinkParser {
    
    /// Result type for placeholder processing
    enum PlaceholderResult {
        case success(String)
        case missingArgument(String)
        case error(String)
    }
    
    /// Process a single placeholder content string
    static func processPlaceholder(
        _ content: String,
        arguments: [String: String],
        clipboard: String?,
        selection: String?,
        date: Date
    ) -> PlaceholderResult {
        // Split content and modifiers
        let parts = content.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let basePlaceholder = parts.first else {
            return .error("Empty placeholder")
        }
        
        let modifiers = Array(parts.dropFirst())
        
        // Process the base placeholder
        var value: String?
        
        if basePlaceholder.hasPrefix("argument") {
            // Parse argument placeholder
            if let argInfo = parseArgumentInfo(from: basePlaceholder) {
                if let providedValue = arguments[argInfo.name] {
                    value = providedValue
                } else if let defaultValue = argInfo.defaultValue {
                    value = defaultValue
                } else {
                    return .missingArgument(argInfo.name)
                }
            }
        } else if basePlaceholder == "clipboard" {
            value = clipboard
        } else if basePlaceholder == "selection" {
            value = selection
        } else if basePlaceholder == "date" || basePlaceholder.hasPrefix("date ") {
            value = formatDate(date, placeholder: basePlaceholder)
        } else if basePlaceholder == "time" {
            value = formatTime(date)
        } else if basePlaceholder == "datetime" {
            value = formatDateTime(date)
        }
        
        // Apply modifiers
        if var processedValue = value {
            for modifier in modifiers {
                processedValue = applyModifier(processedValue, modifier: modifier)
            }
            return .success(processedValue)
        }
        
        // If no value was found, return the placeholder unchanged (for unknown types)
        return .success("{\(content)}")
    }
    
    /// Parse argument information from placeholder content
    static func parseArgumentInfo(from placeholder: String) -> ArgumentInfo? {
        // Extract name
        guard let name = extractValue(from: placeholder, key: "name") else {
            return nil
        }
        
        // Extract optional default value
        let defaultValue = extractValue(from: placeholder, key: "default")
        
        // Extract and parse options if present
        let optionsString = extractValue(from: placeholder, key: "options")
        let options: [ArgumentOption]? = optionsString.map { parseOptions($0) }
        
        return ArgumentInfo(
            name: name,
            defaultValue: defaultValue,
            options: options,
            required: defaultValue == nil
        )
    }
    
    /// Parse options string into ArgumentOption array
    /// Supports both "value1, value2" and "Label1|value1, Label2|value2" formats
    static func parseOptions(_ optionsString: String) -> [ArgumentOption] {
        let optionParts = optionsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        return optionParts.compactMap { part in
            if part.contains("|") {
                // Label|value format
                let components = part.split(separator: "|", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                if components.count == 2 {
                    return ArgumentOption(label: components[0], value: components[1])
                }
            }
            // Simple value format (label equals value)
            return ArgumentOption(value: part)
        }
    }
    
    /// Extract a value for a given key from placeholder content
    static func extractValue(from content: String, key: String) -> String? {
        // Pattern to match key="value" or key=value
        let quotedPattern = "\(key)=\"([^\"]*)\""
        let unquotedPattern = "\(key)=([^\\s]+)"
        
        // Try quoted pattern first
        if let regex = try? NSRegularExpression(pattern: quotedPattern, options: []) {
            let range = NSRange(location: 0, length: content.utf16.count)
            if let match = regex.firstMatch(in: content, options: [], range: range),
               let valueRange = Range(match.range(at: 1), in: content) {
                // Return the captured content (without quotes)
                return String(content[valueRange])
            }
        }
        
        // Try unquoted pattern
        if let regex = try? NSRegularExpression(pattern: unquotedPattern, options: []) {
            let range = NSRange(location: 0, length: content.utf16.count)
            if let match = regex.firstMatch(in: content, options: [], range: range),
               let valueRange = Range(match.range(at: 1), in: content) {
                return String(content[valueRange])
            }
        }
        
        return nil
    }
    
    /// Apply a modifier to a value
    static func applyModifier(_ value: String, modifier: String) -> String {
        switch modifier.lowercased() {
        case "percent-encode":
            // Use a more restrictive character set that encodes &, =, and other special chars
            let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
            return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
        case "trim":
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case "uppercase":
            return value.uppercased()
        case "lowercase":
            return value.lowercased()
        case "json-stringify":
            // Escape for JSON
            let escaped = value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")
            return "\"\(escaped)\""
        default:
            // Unknown modifier, return value unchanged
            return value
        }
    }
    
    /// Format date with optional format string and offset
    static func formatDate(_ date: Date, placeholder: String) -> String {
        var workingDate = date
        
        // Apply offset if present
        if let offset = extractValue(from: placeholder, key: "offset") {
            workingDate = applyDateOffset(to: date, offset: offset)
        }
        
        // Apply format if present
        if let format = extractValue(from: placeholder, key: "format") {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return formatter.string(from: workingDate)
        }
        
        // Default format
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: workingDate)
    }
    
    /// Format time with system format
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Format date and time with system format
    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Apply date offset string (e.g., "+7d", "-1M")
    static func applyDateOffset(to date: Date, offset: String) -> Date {
        let trimmedOffset = offset.trimmingCharacters(in: .whitespaces)
        
        // Parse offset pattern: +/-NUMBER[m|h|d|M|y]
        let pattern = "^([+-])(\\d+)([mhdMy])$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return date
        }
        
        let range = NSRange(location: 0, length: trimmedOffset.utf16.count)
        guard let match = regex.firstMatch(in: trimmedOffset, options: [], range: range) else {
            return date
        }
        
        guard let signRange = Range(match.range(at: 1), in: trimmedOffset),
              let numberRange = Range(match.range(at: 2), in: trimmedOffset),
              let unitRange = Range(match.range(at: 3), in: trimmedOffset) else {
            return date
        }
        
        let sign = String(trimmedOffset[signRange])
        let number = Int(String(trimmedOffset[numberRange])) ?? 0
        let unit = String(trimmedOffset[unitRange])
        
        let value = (sign == "+") ? number : -number
        
        var components = DateComponents()
        switch unit {
        case "m": components.minute = value
        case "h": components.hour = value
        case "d": components.day = value
        case "M": components.month = value
        case "y": components.year = value
        default: return date
        }
        
        return Calendar.current.date(byAdding: components, to: date) ?? date
    }
    
    /// Validate placeholder content for errors
    static func validatePlaceholderContent(_ content: String) -> String? {
        let parts = content.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let basePlaceholder = parts.first else {
            return "Empty placeholder content"
        }
        
        // Check known placeholder types
        let knownTypes = ["argument", "clipboard", "selection", "date", "time", "datetime"]
        let isKnown = knownTypes.contains { basePlaceholder == $0 || basePlaceholder.hasPrefix("\($0) ") }
        
        if !isKnown {
            // Could be an unknown type, but that's not necessarily an error
            // Only report error for clearly malformed content
            if basePlaceholder.contains("\"") && !basePlaceholder.contains("=\"") {
                return "Malformed placeholder: \(basePlaceholder)"
            }
        }
        
        // Validate argument placeholders
        if basePlaceholder.hasPrefix("argument") {
            if extractValue(from: basePlaceholder, key: "name") == nil {
                return "Argument placeholder missing required 'name' attribute"
            }
        }
        
        // Validate modifiers
        let validModifiers = ["percent-encode", "trim", "uppercase", "lowercase", "json-stringify"]
        for modifier in parts.dropFirst() {
            if !validModifiers.contains(modifier.lowercased()) {
                // Not an error, just unknown modifier
                // Could be a future modifier
            }
        }
        
        return nil
    }
    
}
