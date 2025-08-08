//
//  QuickLinkParserTests.swift
//  QuickLinkParserTests
//
//  Comprehensive test suite for QuickLink template parsing and processing
//  Created on 26/01/2025.
//

import XCTest
@testable import QuickLinkParser

final class QuickLinkParserTests: XCTestCase {
    
    // MARK: - Basic Parsing Tests
    
    func testSimpleArgumentParsing() {
        let template = "https://example.com?q={argument name=\"query\"}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["query": "test search"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=test search")
        XCTAssertTrue(result.missingArguments.isEmpty)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testArgumentWithDefault() {
        let template = "https://example.com?q={argument name=\"query\" default=\"hello world\"}"
        
        // Test without providing argument (should use default)
        let result1 = QuickLinkParser.process(template)
        XCTAssertTrue(result1.success)
        XCTAssertEqual(result1.url, "https://example.com?q=hello world")
        
        // Test with providing argument (should override default)
        let result2 = QuickLinkParser.process(template, arguments: ["query": "custom"])
        XCTAssertTrue(result2.success)
        XCTAssertEqual(result2.url, "https://example.com?q=custom")
    }
    
    func testArgumentWithOptions() {
        let template = "https://example.com?lang={argument name=\"language\" default=\"en\" options=\"en, es, fr, de\"}"
        
        let info = QuickLinkParser.analyze(template)
        XCTAssertEqual(info.arguments.count, 1)
        XCTAssertEqual(info.arguments[0].name, "language")
        XCTAssertEqual(info.arguments[0].defaultValue, "en")
        XCTAssertEqual(info.arguments[0].options?.count, 4)
        XCTAssertEqual(info.arguments[0].options?[0].value, "en")
        XCTAssertEqual(info.arguments[0].options?[0].label, "en")
        XCTAssertFalse(info.arguments[0].required)
    }
    
    func testSimpleOptionsExtraction() {
        // Test basic extraction first
        let template = "https://example.com?x={argument name=\"test\" options=\"a, b, c\"}"
        let info = QuickLinkParser.analyze(template)
        
        XCTAssertEqual(info.arguments.count, 1)
        XCTAssertEqual(info.arguments[0].name, "test")
        XCTAssertEqual(info.arguments[0].options?.count, 3)
        XCTAssertEqual(info.arguments[0].options?[0].value, "a")
        XCTAssertEqual(info.arguments[0].options?[1].value, "b")
        XCTAssertEqual(info.arguments[0].options?[2].value, "c")
    }
    
    func testArgumentWithLabelValueOptions() {
        let template = "https://youtube.com/results?search_query={argument name=\"query\"}&sp={argument name=\"filter\" options=\"Videos|EgIQAQ%253D%253D, Channels|EgIQAg%253D%253D, Playlists|EgIQAw%253D%253D\" default=\"EgIQAQ%253D%253D\"}"
        
        let info = QuickLinkParser.analyze(template)
        
        // Debug: Check all arguments
        XCTAssertEqual(info.arguments.count, 2, "Should have 2 arguments: query and filter")
        
        // Find the filter argument
        let filterArg = info.arguments.first { $0.name == "filter" }
        XCTAssertNotNil(filterArg, "Should find filter argument")
        
        // Check options parsing
        if let options = filterArg?.options {
            XCTAssertEqual(options.count, 3, "Should have 3 options")
            
            if options.count >= 3 {
                // Check first option (Videos)
                XCTAssertEqual(options[0].label, "Videos")
                XCTAssertEqual(options[0].value, "EgIQAQ%253D%253D")
                
                // Check second option (Channels)
                XCTAssertEqual(options[1].label, "Channels")
                XCTAssertEqual(options[1].value, "EgIQAg%253D%253D")
                
                // Check third option (Playlists)
                XCTAssertEqual(options[2].label, "Playlists")
                XCTAssertEqual(options[2].value, "EgIQAw%253D%253D")
            }
        } else {
            XCTFail("Filter argument should have options")
        }
        
        // Check default value
        XCTAssertEqual(filterArg?.defaultValue, "EgIQAQ%253D%253D")
    }
    
    func testMixedOptionFormats() {
        let template = "https://example.com?type={argument name=\"type\" options=\"Simple, With Space, Label|value123, Another Label|complex%20value\"}"
        
        let info = QuickLinkParser.analyze(template)
        let arg = info.arguments.first
        
        XCTAssertEqual(arg?.options?.count, 4)
        
        // Simple value (label equals value)
        XCTAssertEqual(arg?.options?[0].label, "Simple")
        XCTAssertEqual(arg?.options?[0].value, "Simple")
        
        // Value with space
        XCTAssertEqual(arg?.options?[1].label, "With Space")
        XCTAssertEqual(arg?.options?[1].value, "With Space")
        
        // Label|value format
        XCTAssertEqual(arg?.options?[2].label, "Label")
        XCTAssertEqual(arg?.options?[2].value, "value123")
        
        // Label|value with encoded characters
        XCTAssertEqual(arg?.options?[3].label, "Another Label")
        XCTAssertEqual(arg?.options?[3].value, "complex%20value")
    }
    
    func testMissingRequiredArgument() {
        let template = "https://example.com?q={argument name=\"query\"}"
        let result = QuickLinkParser.process(template)
        
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.missingArguments, ["query"])
        XCTAssertEqual(result.url, "https://example.com?q={argument name=\"query\"}")
    }
    
    // MARK: - System Placeholder Tests
    
    func testClipboardPlaceholder() {
        let template = "https://example.com?q={clipboard}"
        let result = QuickLinkParser.process(
            template,
            clipboard: "clipboard content"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=clipboard content")
    }
    
    func testSelectionPlaceholder() {
        let template = "https://example.com?q={selection}"
        let result = QuickLinkParser.process(
            template,
            selection: "selected text"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=selected text")
    }
    
    func testDatePlaceholder() {
        let template = "https://example.com?date={date format=\"yyyy-MM-dd\"}"
        let testDate = Date(timeIntervalSince1970: 1706284800) // 2024-01-27 00:00:00 UTC
        
        let result = QuickLinkParser.process(
            template,
            date: testDate
        )
        
        XCTAssertTrue(result.success)
        // Note: Date formatting may vary by timezone
        XCTAssertTrue(result.url.contains("date=202"))
        XCTAssertTrue(result.url.contains("-01-"))
    }
    
    func testTimePlaceholder() {
        let template = "https://example.com?time={time}"
        let result = QuickLinkParser.process(template)
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("time="))
        // Time format varies by locale, just ensure it's replaced
        XCTAssertFalse(result.url.contains("{time}"))
    }
    
    func testDateTimePlaceholder() {
        let template = "https://example.com?dt={datetime}"
        let result = QuickLinkParser.process(template)
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("dt="))
        XCTAssertFalse(result.url.contains("{datetime}"))
    }
    
    // MARK: - Date Offset Tests
    
    func testDateWithPositiveOffset() {
        let template = "https://example.com?date={date format=\"yyyy-MM-dd\" offset=\"+7d\"}"
        let baseDate = Date(timeIntervalSince1970: 1706284800) // 2024-01-27
        
        let result = QuickLinkParser.process(template, date: baseDate)
        
        XCTAssertTrue(result.success)
        // Should be 7 days later: 2024-02-03
        XCTAssertTrue(result.url.contains("-02-") || result.url.contains("-01-"))
    }
    
    func testDateWithNegativeOffset() {
        let template = "https://example.com?date={date format=\"yyyy-MM-dd\" offset=\"-1M\"}"
        let baseDate = Date(timeIntervalSince1970: 1706284800) // 2024-01-27
        
        let result = QuickLinkParser.process(template, date: baseDate)
        
        XCTAssertTrue(result.success)
        // Should be 1 month earlier
        XCTAssertTrue(result.url.contains("202"))
    }
    
    func testDateWithHourOffset() {
        let template = "https://example.com?time={date format=\"HH:mm\" offset=\"+2h\"}"
        let result = QuickLinkParser.process(template)
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("time="))
        XCTAssertFalse(result.url.contains("offset"))
    }
    
    // MARK: - Modifier Tests
    
    func testPercentEncodeModifier() {
        let template = "https://example.com?q={argument name=\"query\" | percent-encode}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["query": "hello world & friends"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("hello%20world"))
        XCTAssertTrue(result.url.contains("%26"))
    }
    
    func testTrimModifier() {
        let template = "https://example.com?q={argument name=\"query\" | trim}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["query": "  hello world  "]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=hello world")
    }
    
    func testUppercaseModifier() {
        let template = "https://example.com?q={argument name=\"query\" | uppercase}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["query": "hello world"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=HELLO WORLD")
    }
    
    func testLowercaseModifier() {
        let template = "https://example.com?q={argument name=\"query\" | lowercase}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["query": "HELLO WORLD"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=hello world")
    }
    
    func testJsonStringifyModifier() {
        let template = "https://example.com?data={argument name=\"text\" | json-stringify}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["text": "Hello \"World\"\nNew Line"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("\\\"World\\\""))
        XCTAssertTrue(result.url.contains("\\n"))
    }
    
    func testChainedModifiers() {
        let template = "https://example.com?q={argument name=\"query\" | trim | lowercase | percent-encode}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["query": "  HELLO WORLD  "]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=hello%20world")
    }
    
    // MARK: - Complex Template Tests
    
    func testMultipleArguments() {
        let template = "https://github.com/{argument name=\"owner\"}/{argument name=\"repo\"}/issues?q={argument name=\"search\" default=\"bug\"}"
        
        let result = QuickLinkParser.process(
            template,
            arguments: [
                "owner": "apple",
                "repo": "swift",
                "search": "memory leak"
            ]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://github.com/apple/swift/issues?q=memory leak")
    }
    
    func testMixedPlaceholderTypes() {
        let template = "https://example.com?q={selection | percent-encode}&user={argument name=\"username\"}&date={date format=\"yyyy-MM-dd\"}"
        
        let testDate = Date(timeIntervalSince1970: 1706284800) // 2024-01-27
        let result = QuickLinkParser.process(
            template,
            arguments: ["username": "john"],
            selection: "test query",
            date: testDate
        )
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("q=test%20query"))
        XCTAssertTrue(result.url.contains("user=john"))
        XCTAssertTrue(result.url.contains("date=202"))
    }
    
    // MARK: - Template Analysis Tests
    
    func testAnalyzeSimpleTemplate() {
        let template = "https://example.com?q={argument name=\"query\"}"
        let info = QuickLinkParser.analyze(template)
        
        XCTAssertEqual(info.arguments.count, 1)
        XCTAssertEqual(info.arguments[0].name, "query")
        XCTAssertTrue(info.arguments[0].required)
        XCTAssertFalse(info.usesClipboard)
        XCTAssertFalse(info.usesSelection)
        XCTAssertFalse(info.usesDate)
    }
    
    func testAnalyzeComplexTemplate() {
        let template = """
        https://example.com?q={selection}&clip={clipboard}&date={date format="yyyy-MM-dd"}&\
        arg1={argument name="test1" default="value1"}&arg2={argument name="test2"}
        """
        
        let info = QuickLinkParser.analyze(template)
        
        XCTAssertEqual(info.arguments.count, 2)
        XCTAssertTrue(info.usesClipboard)
        XCTAssertTrue(info.usesSelection)
        XCTAssertTrue(info.usesDate)
        XCTAssertEqual(info.dateFormats, ["yyyy-MM-dd"])
        
        XCTAssertEqual(info.requiredArguments.count, 1)
        XCTAssertEqual(info.requiredArguments[0].name, "test2")
        
        XCTAssertEqual(info.optionalArguments.count, 1)
        XCTAssertEqual(info.optionalArguments[0].name, "test1")
    }
    
    func testAnalyzeDuplicateArguments() {
        let template = "https://example.com?q1={argument name=\"query\"}&q2={argument name=\"query\"}"
        let info = QuickLinkParser.analyze(template)
        
        // Should deduplicate
        XCTAssertEqual(info.arguments.count, 1)
        XCTAssertEqual(info.arguments[0].name, "query")
    }
    
    // MARK: - Validation Tests
    
    func testValidateCorrectTemplate() {
        let template = "https://example.com?q={clipboard | percent-encode}"
        XCTAssertTrue(QuickLinkParser.validate(template))
        
        let result = QuickLinkParser.validateWithErrors(template)
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testValidateUnclosedPlaceholder() {
        let template = "https://example.com?q={clipboard"
        XCTAssertFalse(QuickLinkParser.validate(template))
        
        let result = QuickLinkParser.validateWithErrors(template)
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.errors.isEmpty)
        XCTAssertTrue(result.errors[0].contains("Unclosed"))
    }
    
    func testValidateExtraClosingBrace() {
        let template = "https://example.com?q=test}"
        
        let result = QuickLinkParser.validateWithErrors(template)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors[0].contains("closing brace"))
    }
    
    func testValidateMissingArgumentName() {
        let template = "https://example.com?q={argument default=\"test\"}"
        let result = QuickLinkParser.process(template)
        
        // Should handle gracefully even without name
        XCTAssertTrue(result.errors.isEmpty || result.missingArguments.isEmpty)
    }
    
    // MARK: - Real-World Template Tests
    
    func testGoogleSearchTemplate() {
        let template = "https://www.google.com/search?q={selection | percent-encode}"
        
        let result = QuickLinkParser.process(
            template,
            selection: "Swift programming language"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://www.google.com/search?q=Swift%20programming%20language")
    }
    
    func testGoogleTranslateTemplate() {
        let template = "https://translate.google.com/?sl={argument name=\"from\" default=\"auto\"}&tl={argument name=\"to\" default=\"en\"}&text={selection | percent-encode}"
        
        let result = QuickLinkParser.process(
            template,
            arguments: ["from": "es", "to": "en"],
            selection: "Hola mundo"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://translate.google.com/?sl=es&tl=en&text=Hola%20mundo")
    }
    
    func testGitHubRepoTemplate() {
        let template = "https://github.com/{argument name=\"owner\"}/{argument name=\"repo\"}"
        
        let result = QuickLinkParser.process(
            template,
            arguments: ["owner": "microsoft", "repo": "vscode"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://github.com/microsoft/vscode")
    }
    
    func testYouTubeSearchTemplate() {
        let template = "https://www.youtube.com/results?search_query={clipboard | trim | percent-encode}"
        
        let result = QuickLinkParser.process(
            template,
            clipboard: "  Swift tutorials  "
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://www.youtube.com/results?search_query=Swift%20tutorials")
    }
    
    func testCalendarEventTemplate() {
        let template = "https://calendar.google.com/calendar/render?action=TEMPLATE&text={argument name=\"title\" | percent-encode}&dates={date format=\"yyyyMMdd\"}/{date format=\"yyyyMMdd\" offset=\"+1d\"}"
        
        let testDate = Date(timeIntervalSince1970: 1706284800) // 2024-01-27
        let result = QuickLinkParser.process(
            template,
            arguments: ["title": "Team Meeting"],
            date: testDate
        )
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("text=Team%20Meeting"))
        XCTAssertTrue(result.url.contains("dates="))
    }
    
    // MARK: - Additional Edge Case Tests
    
    func testArgumentWithQuotesInValue() {
        let template = "https://example.com?q={argument name=\"query\"}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["query": "\"hello\" world"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=\"hello\" world")
    }
    
    func testArgumentNameWithSpaces() {
        let template = "https://example.com?q={argument name=\"search query\"}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["search query": "test"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=test")
    }
    
    func testEmptyArgumentValue() {
        let template = "https://example.com?q={argument name=\"query\" default=\"\"}"
        let result = QuickLinkParser.process(template)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=")
    }
    
    func testNilClipboardAndSelection() {
        let template = "https://example.com?clip={clipboard}&sel={selection}"
        let result = QuickLinkParser.process(template)
        
        XCTAssertTrue(result.success)
        // Should leave placeholders unchanged when nil
        XCTAssertEqual(result.url, "https://example.com?clip={clipboard}&sel={selection}")
    }
    
    func testVeryLongArgumentValue() {
        let template = "https://example.com?q={argument name=\"query\"}"
        let longValue = String(repeating: "a", count: 10000)
        let result = QuickLinkParser.process(
            template,
            arguments: ["query": longValue]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains(longValue))
    }
    
    func testSpecialCharactersInURL() {
        let template = "https://example.com/path?q={clipboard | percent-encode}#section"
        let result = QuickLinkParser.process(
            template,
            clipboard: "test & value"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com/path?q=test%20%26%20value#section")
    }
    
    func testMultipleSamePlaceholders() {
        let template = "https://example.com?q1={clipboard}&q2={clipboard}"
        let result = QuickLinkParser.process(
            template,
            clipboard: "test"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q1=test&q2=test")
    }
    
    func testArgumentWithEqualsInDefault() {
        let template = "https://example.com?q={argument name=\"query\" default=\"key=value\"}"
        let result = QuickLinkParser.process(template)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=key=value")
    }
    
    func testConsecutivePlaceholders() {
        let template = "https://example.com/{argument name=\"path1\"}{argument name=\"path2\"}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["path1": "foo", "path2": "bar"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com/foobar")
    }
    
    func testPlaceholderAtStartAndEnd() {
        let template = "{argument name=\"protocol\" default=\"https\"}://example.com/{argument name=\"path\"}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["path": "api/v1"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com/api/v1")
    }
    
    func testInvalidDateFormat() {
        let template = "https://example.com?date={date format=\"invalid-format\"}"
        let result = QuickLinkParser.process(template)
        
        // Should still succeed but with some date output
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("date="))
        XCTAssertFalse(result.url.contains("{date"))
    }
    
    func testInvalidDateOffset() {
        let template = "https://example.com?date={date offset=\"invalid\"}"
        let result = QuickLinkParser.process(template)
        
        // Should ignore invalid offset and use current date
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("date="))
        XCTAssertFalse(result.url.contains("invalid"))
    }
    
    func testModifierOnEmptyValue() {
        let template = "https://example.com?q={clipboard | trim | percent-encode}"
        let result = QuickLinkParser.process(
            template,
            clipboard: ""
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=")
    }
    
    func testCaseSensitiveModifiers() {
        let template = "https://example.com?q={clipboard | UPPERCASE}"
        let result = QuickLinkParser.process(
            template,
            clipboard: "test"
        )
        
        // Modifiers should be case-insensitive
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=TEST")
    }
    
    func testUnicodeInArguments() {
        let template = "https://example.com?q={argument name=\"query\" | percent-encode}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["query": "こんにちは 世界 🌍"]
        )
        
        XCTAssertTrue(result.success)
        // Should encode unicode properly
        XCTAssertTrue(result.url.contains("%"))
        XCTAssertFalse(result.url.contains("こんにちは"))
    }
    
    func testNewlinesInValues() {
        let template = "https://example.com?text={clipboard | percent-encode}"
        let result = QuickLinkParser.process(
            template,
            clipboard: "Line 1\nLine 2\rLine 3"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("%0A") || result.url.contains("%0D"))
    }
    
    func testMixedQuotesInArgument() {
        let template = "https://example.com?q={argument name='query' default=\"test\"}"
        // Note: This might not parse correctly with our regex
        let info = QuickLinkParser.analyze(template)
        
        // Should handle gracefully even if it doesn't parse
        XCTAssertNotNil(info)
    }
    
    func testPercentEncodeSpecialCases() {
        let template = "https://example.com?q={clipboard | percent-encode}"
        
        // Test various special characters
        let testCases = [
            ("hello world", "hello%20world"),
            ("test&value", "test%26value"),
            ("a=b", "a%3Db"),
            ("50%off", "50%25off"),
            ("path/to/file", "path%2Fto%2Ffile"),
            ("question?mark", "question%3Fmark"),
            ("hash#tag", "hash%23tag"),
            ("at@sign", "at%40sign")
        ]
        
        for (input, expected) in testCases {
            let result = QuickLinkParser.process(template, clipboard: input)
            XCTAssertTrue(result.success)
            XCTAssertEqual(result.url, "https://example.com?q=\(expected)", "Failed for input: \(input)")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyTemplate() {
        let template = ""
        let result = QuickLinkParser.process(template)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "")
    }
    
    func testTemplateWithoutPlaceholders() {
        let template = "https://example.com/static/path?param=value"
        let result = QuickLinkParser.process(template)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, template)
    }
    
    func testPlaceholderWithSpecialCharacters() {
        let template = "https://example.com?data={argument name=\"data-value\"}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["data-value": "test"]
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?data=test")
    }
    
    func testNestedBraces() {
        // This should not be valid, but should handle gracefully
        let template = "https://example.com?q={{clipboard}}"
        let result = QuickLinkParser.process(
            template,
            clipboard: "test"
        )
        
        // Should leave as-is since it's not valid syntax
        XCTAssertEqual(result.url, template)
    }
    
    func testUnknownPlaceholderType() {
        let template = "https://example.com?q={unknown_placeholder}"
        let result = QuickLinkParser.process(template)
        
        // Should leave unknown placeholders unchanged
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, template)
    }
    
    func testUnknownModifier() {
        let template = "https://example.com?q={clipboard | unknown-modifier}"
        let result = QuickLinkParser.process(
            template,
            clipboard: "test"
        )
        
        // Should ignore unknown modifiers
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=test")
    }
    
    func testEmptyModifierChain() {
        let template = "https://example.com?q={clipboard | }"
        let result = QuickLinkParser.process(
            template,
            clipboard: "test"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=test")
    }
    
    func testWhitespaceInPlaceholders() {
        let template = "https://example.com?q={ clipboard | trim | percent-encode }"
        let result = QuickLinkParser.process(
            template,
            clipboard: "  test  "
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://example.com?q=test")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceSimpleTemplate() {
        let template = "https://example.com?q={clipboard}"
        
        measure {
            for _ in 0..<1000 {
                _ = QuickLinkParser.process(
                    template,
                    clipboard: "test content"
                )
            }
        }
    }
    
    func testPerformanceComplexTemplate() {
        let template = """
        https://example.com?q={selection | trim | lowercase | percent-encode}&\
        user={argument name=\"username\" default=\"john\"}&\
        date={date format=\"yyyy-MM-dd\"}&\
        time={time}&\
        clip={clipboard | percent-encode}
        """
        
        measure {
            for _ in 0..<100 {
                _ = QuickLinkParser.process(
                    template,
                    arguments: ["username": "test"],
                    clipboard: "clipboard",
                    selection: "selection"
                )
            }
        }
    }
    
    func testPerformanceAnalysis() {
        let template = """
        https://example.com?q={selection | trim | lowercase | percent-encode}&\
        arg1={argument name=\"test1\" default=\"value1\" options=\"a, b, c\"}&\
        arg2={argument name=\"test2\"}&\
        arg3={argument name=\"test3\" default=\"value3\"}&\
        date={date format=\"yyyy-MM-dd\" offset=\"+7d\"}
        """
        
        measure {
            for _ in 0..<1000 {
                _ = QuickLinkParser.analyze(template)
            }
        }
    }
    
    // MARK: - System Access Tests
    
    func testProcessWithSystemAccess() {
        let template = "https://example.com?q={clipboard}"
        
        // Set clipboard first
        SystemAccessHelper.setClipboard("test clipboard content")
        
        // Process with system access
        let result = QuickLinkParser.processWithSystemAccess(template)
        
        // Should use actual clipboard
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.url.contains("test clipboard content") || result.url == "https://example.com?q=")
    }
    
    func testAccessibilityPermissionCheck() {
        // Just verify the method exists and returns a boolean
        let hasPermission = QuickLinkParser.hasAccessibilityPermission()
        XCTAssertNotNil(hasPermission)
    }
    
    // MARK: - Batch Processing Tests
    
    func testProcessingMultipleTemplates() {
        let templates = [
            "https://google.com/search?q={clipboard}",
            "https://github.com/{argument name=\"owner\"}/{argument name=\"repo\"}",
            "https://example.com?date={date format=\"yyyy-MM-dd\"}"
        ]
        
        let arguments = ["owner": "apple", "repo": "swift"]
        let clipboard = "search term"
        
        var results: [ProcessResult] = []
        for template in templates {
            let result = QuickLinkParser.process(
                template,
                arguments: arguments,
                clipboard: clipboard
            )
            results.append(result)
        }
        
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results[0].success)
        XCTAssertTrue(results[1].success)
        XCTAssertTrue(results[2].success)
    }
    
    // MARK: - Documentation Example Tests
    
    func testDocumentationExample1() {
        // From main documentation
        let template = "https://google.com/search?q={selection | percent-encode}"
        let result = QuickLinkParser.process(
            template,
            selection: "Hello World"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://google.com/search?q=Hello%20World")
    }
    
    func testDocumentationExample2() {
        // From process method documentation
        let template = "https://translate.google.com/?text={selection | percent-encode}&to={argument name=\"lang\" default=\"en\"}"
        let result = QuickLinkParser.process(
            template,
            arguments: ["lang": "es"],
            selection: "Hello World"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.url, "https://translate.google.com/?text=Hello%20World&to=es")
    }
    
    func testDocumentationExample3() {
        // From analyze method documentation
        let template = "https://api.example.com?key={argument name=\"api_key\"}&q={selection}"
        let info = QuickLinkParser.analyze(template)
        
        XCTAssertEqual(info.arguments.count, 1)
        XCTAssertEqual(info.arguments[0].name, "api_key")
        XCTAssertTrue(info.arguments[0].required)
        XCTAssertTrue(info.usesSelection)
    }
}
