//
//  ProcessResult.swift
//  QuickLinkParser
//
//  Created by David Sherlock on 08/08/2025.
//

import Foundation

/// The result of processing a QuickLink template.
///
/// Contains the processed URL string along with information about any
/// missing arguments or errors encountered during processing.
///
/// ## Example
///
/// ```swift
/// let result = QuickLinkParser.process(template)
///
/// if result.success {
///     // Use result.url
/// } else {
///     // Handle missing arguments or errors
///     print("Missing: \(result.missingArguments)")
///     print("Errors: \(result.errors)")
/// }
/// ```
public struct ProcessResult {
    
    /// The processed URL string with all placeholders replaced.
    ///
    /// If processing was successful, this contains the final URL ready for use.
    /// If there were missing required arguments, placeholders for those arguments
    /// remain unchanged in the string.
    public let url: String
    
    /// Array of argument names that were required but not provided.
    ///
    /// Only includes required arguments (those without default values) that
    /// were not found in the provided arguments dictionary.
    public let missingArguments: [String]
    
    /// Indicates whether processing was completely successful.
    ///
    /// Returns `true` only if there are no missing arguments and no errors.
    /// When `true`, the `url` property contains a fully processed URL ready for use.
    public let success: Bool
    
    /// Array of error messages encountered during processing.
    ///
    /// May include parsing errors, invalid placeholder syntax, or other issues.
    /// Empty array if no errors were encountered.
    public let errors: [String]
    
    /// Initializes a new ProcessResult.
    ///
    /// - Parameters:
    ///   - url: The processed URL string
    ///   - missingArguments: Array of missing required argument names
    ///   - success: Whether processing was successful
    ///   - errors: Array of error messages
    public init(
        url: String,
        missingArguments: [String] = [],
        success: Bool,
        errors: [String] = []
    ) {
        self.url = url
        self.missingArguments = missingArguments
        self.success = success
        self.errors = errors
    }
    
}
