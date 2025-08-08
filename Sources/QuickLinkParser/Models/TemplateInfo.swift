//
//  TemplateInfo.swift
//  QuickLinkParser
//
//  Created by David Sherlock on 08/08/2025.
//

import Foundation

/// Information about a QuickLink template's structure and requirements.
///
/// Provides detailed information about all placeholders found in a template,
/// useful for building dynamic user interfaces or validating templates before use.
///
/// ## Example
///
/// ```swift
/// let info = QuickLinkParser.analyze(template)
///
/// // Build UI for required arguments
/// for arg in info.arguments where arg.required {
///     // Create input field for arg.name
/// }
///
/// // Check system requirements
/// if info.usesSelection && !hasSelectionAccess {
///     // Request accessibility permissions
/// }
/// ```
public struct TemplateInfo {
    
    /// Array of all argument placeholders found in the template.
    ///
    /// Each element contains information about an argument including its name,
    /// default value (if any), available options (if any), and whether it's required.
    /// Duplicates are automatically removed.
    public let arguments: [ArgumentInfo]
    
    /// Indicates whether the template uses {clipboard} placeholders.
    ///
    /// If `true`, the template expects clipboard content to be available
    /// during processing.
    public let usesClipboard: Bool
    
    /// Indicates whether the template uses {selection} placeholders.
    ///
    /// If `true`, the template expects selected text to be available.
    /// On macOS, this typically requires accessibility permissions.
    public let usesSelection: Bool
    
    /// Indicates whether the template uses any date/time placeholders.
    ///
    /// Includes {date}, {time}, {datetime}, and any variants with custom
    /// formats or offsets.
    public let usesDate: Bool
    
    /// Array of custom date format strings found in the template.
    ///
    /// Contains all unique format strings specified in date placeholders,
    /// e.g., "yyyy-MM-dd" from {date format="yyyy-MM-dd"}.
    /// Empty if no custom formats are used.
    public let dateFormats: [String]
    
    /// Initializes a new TemplateInfo.
    ///
    /// - Parameters:
    ///   - arguments: Array of argument information
    ///   - usesClipboard: Whether template uses clipboard
    ///   - usesSelection: Whether template uses selection
    ///   - usesDate: Whether template uses date/time
    ///   - dateFormats: Array of date format strings
    public init(
        arguments: [ArgumentInfo] = [],
        usesClipboard: Bool = false,
        usesSelection: Bool = false,
        usesDate: Bool = false,
        dateFormats: [String] = []
    ) {
        self.arguments = arguments
        self.usesClipboard = usesClipboard
        self.usesSelection = usesSelection
        self.usesDate = usesDate
        self.dateFormats = dateFormats
    }
    
    /// Computed property that returns only required arguments.
    ///
    /// Filters the arguments array to include only those without default values.
    public var requiredArguments: [ArgumentInfo] {
        arguments.filter { $0.required }
    }
    
    /// Computed property that returns only optional arguments.
    ///
    /// Filters the arguments array to include only those with default values.
    public var optionalArguments: [ArgumentInfo] {
        arguments.filter { !$0.required }
    }
    
}
