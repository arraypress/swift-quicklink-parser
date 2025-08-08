//
//  ArgumentInfo.swift
//  QuickLinkParser
//
//  Created by David Sherlock on 08/08/2025.
//

import Foundation

/// Information about a single argument placeholder in a template.
///
/// Represents an {argument} placeholder with its configuration including
/// name, default value, available options, and whether it's required.
///
/// ## Example
///
/// ```swift
/// // From: {argument name="language" default="en" options="English|en, Spanish|es, French|fr"}
/// let argInfo = ArgumentInfo(
///     name: "language",
///     defaultValue: "en",
///     options: [
///         ArgumentOption(label: "English", value: "en"),
///         ArgumentOption(label: "Spanish", value: "es"),
///         ArgumentOption(label: "French", value: "fr")
///     ],
///     required: false  // Has default, so not required
/// )
/// ```
public struct ArgumentInfo: Equatable {
    
    /// The name of the argument as specified in the template.
    ///
    /// This is the key used to look up values in the arguments dictionary
    /// when processing the template.
    public let name: String
    
    /// The default value for this argument, if specified.
    ///
    /// If present, the argument is considered optional and this value
    /// will be used when no value is provided during processing.
    /// `nil` if no default was specified.
    public let defaultValue: String?
    
    /// Available options for this argument, if specified.
    ///
    /// If present, suggests that the UI should present these as predefined
    /// choices (e.g., in a dropdown or segmented control). Each option can
    /// have a user-friendly label and the actual value to use.
    /// `nil` if no options were specified.
    public let options: [ArgumentOption]?
    
    /// Indicates whether this argument is required.
    ///
    /// An argument is required if it has no default value.
    /// Required arguments must be provided during processing or they will
    /// be listed in the result's `missingArguments`.
    public let required: Bool
    
    /// Initializes a new ArgumentInfo.
    ///
    /// - Parameters:
    ///   - name: The argument name
    ///   - defaultValue: Optional default value
    ///   - options: Optional array of predefined options
    ///   - required: Whether the argument is required
    public init(
        name: String,
        defaultValue: String? = nil,
        options: [ArgumentOption]? = nil,
        required: Bool
    ) {
        self.name = name
        self.defaultValue = defaultValue
        self.options = options
        self.required = required
    }
    
    /// Computed property that returns whether this argument has predefined options.
    public var hasOptions: Bool {
        options != nil && !options!.isEmpty
    }
    
    /// Computed property that returns whether this argument has a default value.
    public var hasDefault: Bool {
        defaultValue != nil
    }
    
}
