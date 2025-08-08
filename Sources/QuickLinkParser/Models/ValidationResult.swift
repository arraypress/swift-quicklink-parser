//
//  ValidationResult.swift
//  QuickLinkParser
//
//  Created by David Sherlock on 08/08/2025.
//

import Foundation

/// The result of validating a template's syntax.
///
/// Contains validation status and detailed error messages for any
/// syntax issues found in the template.
///
/// ## Example
///
/// ```swift
/// let validation = QuickLinkParser.validateWithErrors(template)
///
/// if !validation.isValid {
///     for error in validation.errors {
///         print("Error: \(error)")
///     }
/// }
/// ```
public struct ValidationResult {
    
    /// Indicates whether the template syntax is valid.
    ///
    /// `true` if no syntax errors were found, `false` otherwise.
    public let isValid: Bool
    
    /// Array of error messages describing any syntax issues.
    ///
    /// Empty if the template is valid. Messages include details about
    /// the nature and location of syntax errors.
    public let errors: [String]
    
    /// Initializes a new ValidationResult.
    ///
    /// - Parameters:
    ///   - isValid: Whether the template is valid
    ///   - errors: Array of error messages
    public init(isValid: Bool, errors: [String] = []) {
        self.isValid = isValid
        self.errors = errors
    }
    
    /// Computed property that returns whether there are any errors.
    public var hasErrors: Bool {
        !errors.isEmpty
    }
    
    /// Computed property that returns the first error message, if any.
    public var firstError: String? {
        errors.first
    }
    
}
