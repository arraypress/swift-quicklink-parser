//
//  SystemAccessHelper.swift
//  QuickLinkParser
//
//  Platform-specific helpers for accessing system resources like clipboard and selected text
//  Created on 26/01/2025.
//

import Foundation
#if os(macOS)
import AppKit
import ApplicationServices
#elseif os(iOS)
import UIKit
#endif

/// Helper for accessing system resources like clipboard and selected text.
///
/// Provides cross-platform methods for accessing system resources with
/// appropriate implementations for macOS and iOS. Selection access is
/// currently only supported on macOS with accessibility permissions.
///
/// ## Platform Support
///
/// ### Clipboard
/// - macOS: Full support via NSPasteboard
/// - iOS: Full support via UIPasteboard
///
/// ### Selected Text
/// - macOS: Requires accessibility permissions
/// - iOS: Not currently supported
///
/// ## Example
///
/// ```swift
/// // Get clipboard content
/// if let clipboard = SystemAccessHelper.getClipboard() {
///     print("Clipboard: \(clipboard)")
/// }
///
/// // Check for accessibility permissions (macOS)
/// if SystemAccessHelper.hasAccessibilityPermission() {
///     if let selection = SystemAccessHelper.getSelectedText() {
///         print("Selected: \(selection)")
///     }
/// }
/// ```
public struct SystemAccessHelper {
    
    // MARK: - Clipboard Access
    
    /// Retrieves the current clipboard text content.
    ///
    /// Returns the current text content of the system clipboard.
    /// Cross-platform implementation using NSPasteboard on macOS
    /// and UIPasteboard on iOS.
    ///
    /// - Returns: The clipboard text content, or `nil` if empty or not text
    ///
    /// ## Example
    ///
    /// ```swift
    /// if let text = SystemAccessHelper.getClipboard() {
    ///     // Use clipboard text
    /// }
    /// ```
    public static func getClipboard() -> String? {
#if os(macOS)
        return NSPasteboard.general.string(forType: .string)
#elseif os(iOS)
        return UIPasteboard.general.string
#else
        return nil
#endif
    }
    
    /// Sets the clipboard content to the specified text.
    ///
    /// Updates the system clipboard with the provided text string.
    /// This is useful for implementing copy functionality.
    ///
    /// - Parameter text: The text to place on the clipboard
    ///
    /// ## Example
    ///
    /// ```swift
    /// SystemAccessHelper.setClipboard("Hello, World!")
    /// ```
    public static func setClipboard(_ text: String) {
#if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
#elseif os(iOS)
        UIPasteboard.general.string = text
#endif
    }
    
    // MARK: - Selection Access
    
    /// Attempts to retrieve the currently selected text.
    ///
    /// On macOS, this uses accessibility APIs to get the selected text
    /// from the frontmost application. Requires accessibility permissions.
    ///
    /// On iOS, this is not currently implemented and returns `nil`.
    ///
    /// - Returns: The selected text, or `nil` if unavailable or no permissions
    ///
    /// - Note: On macOS, requires accessibility permissions. Check and request
    ///         permissions using `hasAccessibilityPermission()` and
    ///         `requestAccessibilityPermission()`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if SystemAccessHelper.hasAccessibilityPermission() {
    ///     if let selected = SystemAccessHelper.getSelectedText() {
    ///         print("Selected text: \(selected)")
    ///     }
    /// } else {
    ///     SystemAccessHelper.requestAccessibilityPermission()
    /// }
    /// ```
    public static func getSelectedText() -> String? {
#if os(macOS)
        guard hasAccessibilityPermission() else { return nil }
        
        // Get the system-wide accessibility element
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        
        // Get the focused element
        let result = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        guard result == .success,
              let element = focusedElement else {
            return nil
        }
        
        // Try to get selected text directly
        var selectedTextValue: CFTypeRef?
        let selectedTextResult = AXUIElementCopyAttributeValue(
            element as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )
        
        if selectedTextResult == .success,
           let selectedText = selectedTextValue as? String,
           !selectedText.isEmpty {
            return selectedText
        }
        
        // Fallback: Try to get value and selected range
        var valueRef: CFTypeRef?
        let valueResult = AXUIElementCopyAttributeValue(
            element as! AXUIElement,
            kAXValueAttribute as CFString,
            &valueRef
        )
        
        if valueResult == .success,
           let fullText = valueRef as? String,
           !fullText.isEmpty {
            
            // Get selected range
            var rangeRef: CFTypeRef?
            let rangeResult = AXUIElementCopyAttributeValue(
                element as! AXUIElement,
                kAXSelectedTextRangeAttribute as CFString,
                &rangeRef
            )
            
            if rangeResult == .success,
               let rangeValue = rangeRef {
                
                if CFGetTypeID(rangeValue) == AXValueGetTypeID() {
                    var cfRange = CFRange()
                    if AXValueGetValue(rangeValue as! AXValue, .cfRange, &cfRange),
                       cfRange.length > 0 {
                        
                        let nsRange = NSRange(location: cfRange.location, length: cfRange.length)
                        if nsRange.location != NSNotFound &&
                            nsRange.location + nsRange.length <= fullText.count {
                            
                            let startIndex = fullText.index(fullText.startIndex, offsetBy: nsRange.location)
                            let endIndex = fullText.index(startIndex, offsetBy: nsRange.length)
                            return String(fullText[startIndex..<endIndex])
                        }
                    }
                }
            }
        }
        
        return nil
#else
        // Selection access not implemented on iOS
        return nil
#endif
    }
    
    // MARK: - Accessibility Permissions
    
    /// Checks if the app has accessibility permissions.
    ///
    /// On macOS, checks whether the current process is trusted for accessibility.
    /// On iOS, always returns `true` as this feature is not applicable.
    ///
    /// - Returns: `true` if permissions are granted or not needed, `false` otherwise
    ///
    /// ## Example
    ///
    /// ```swift
    /// if !SystemAccessHelper.hasAccessibilityPermission() {
    ///     // Show UI explaining why permission is needed
    ///     // Then request permission
    ///     SystemAccessHelper.requestAccessibilityPermission()
    /// }
    /// ```
    public static func hasAccessibilityPermission() -> Bool {
#if os(macOS)
        return AXIsProcessTrusted()
#else
        // Not applicable on iOS
        return true
#endif
    }
    
    /// Requests accessibility permissions from the user (macOS only).
    ///
    /// On macOS, this will prompt the user to grant accessibility permissions
    /// if not already granted. The prompt will only appear once per app.
    ///
    /// On iOS, this method does nothing as accessibility permissions
    /// are not required for the supported features.
    ///
    /// - Note: After calling this method, the app may need to be restarted
    ///         for the permissions to take effect.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if !SystemAccessHelper.hasAccessibilityPermission() {
    ///     SystemAccessHelper.requestAccessibilityPermission()
    ///     // Show message that app needs to be restarted
    /// }
    /// ```
    public static func requestAccessibilityPermission() {
#if os(macOS)
        // Use string literal to avoid concurrency warning with kAXTrustedCheckOptionPrompt
        let options: [String: Any] = ["AXTrustedCheckOptionPrompt": true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
#endif
    }
    
    /// Opens System Preferences/Settings to the Accessibility pane (macOS only).
    ///
    /// Directly opens the Privacy & Security > Accessibility settings where
    /// users can manually grant permissions to the app.
    ///
    /// On iOS, this method does nothing.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Button("Grant Permission") {
    ///     SystemAccessHelper.openAccessibilitySettings()
    /// }
    /// ```
    public static func openAccessibilitySettings() {
#if os(macOS)
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
#endif
    }
    
    // MARK: - Utility Methods
    
    /// Gets the current system username.
    ///
    /// Returns the username of the currently logged-in user.
    /// Useful for templates that need to reference user-specific paths.
    ///
    /// - Returns: The current username
    ///
    /// ## Example
    ///
    /// ```swift
    /// let username = SystemAccessHelper.getCurrentUsername()
    /// let downloadsPath = "/Users/\(username)/Downloads"
    /// ```
    public static func getCurrentUsername() -> String {
#if os(macOS) || os(iOS)
        return NSUserName()
#else
        return ProcessInfo.processInfo.environment["USER"] ?? "unknown"
#endif
    }
    
    /// Gets the user's home directory path.
    ///
    /// Returns the full path to the current user's home directory.
    ///
    /// - Returns: The home directory path
    ///
    /// ## Example
    ///
    /// ```swift
    /// let homePath = SystemAccessHelper.getHomeDirectory()
    /// let documentsPath = "\(homePath)/Documents"
    /// ```
    public static func getHomeDirectory() -> String {
        return NSHomeDirectory()
    }
    
}
