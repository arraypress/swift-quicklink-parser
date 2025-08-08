//
//  ArgumentOption.swift
//  QuickLinkParser
//
//  Created by David Sherlock on 08/08/2025.
//

import Foundation

/// Represents a single option for an argument with a display label and actual value.
///
/// Allows arguments to have user-friendly labels while using different values
/// in the actual URL. This is particularly useful for encoded values, API endpoints,
/// or technical identifiers that aren't meaningful to users.
///
/// ## Example
///
/// ```swift
/// // YouTube filter option
/// ArgumentOption(label: "Videos", value: "EgIQAQ%253D%253D")
///
/// // Language option  
/// ArgumentOption(label: "English", value: "en-US")
///
/// // Simple option (label equals value)
/// ArgumentOption(value: "newest")
/// ```
public struct ArgumentOption: Equatable {
    
    /// The user-friendly label to display in UI.
    ///
    /// This is what users see in dropdowns or selection controls.
    /// For example: "Videos", "English", "Production Server"
    public let label: String
    
    /// The actual value to use when processing the template.
    ///
    /// This is the value that replaces the placeholder in the URL.
    /// For example: "EgIQAQ%253D%253D", "en-US", "https://api.prod.example.com"
    public let value: String
    
    /// Initializes an option with separate label and value.
    ///
    /// - Parameters:
    ///   - label: The display label
    ///   - value: The actual value to use
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    /// Initializes an option where label equals value.
    ///
    /// Convenience initializer for simple options where the display
    /// label and the actual value are the same.
    ///
    /// - Parameter value: The value to use for both label and value
    public init(value: String) {
        self.label = value
        self.value = value
    }
    
}
