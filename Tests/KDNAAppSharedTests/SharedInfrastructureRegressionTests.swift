import Foundation
import XCTest
import KDNAAppShared

final class SharedInfrastructureRegressionTests: XCTestCase {
    func testProviderNormalizationAndAttachmentFallbackRemainLocal() {
        XCTAssertEqual(ProviderID(normalizing: "  OpenAI\n"), .chatgpt)
        XCTAssertEqual(ProviderID(normalizing: "阿里云百炼"), .qwen)
        XCTAssertNil(ProviderID(normalizing: "unregistered-provider"))
        XCTAssertTrue(ProviderAttachmentCapabilities.forProvider(.chatgpt).supportsNativeFileInputs)
        XCTAssertFalse(ProviderAttachmentCapabilities.forProvider(.codex).supportsNativeFileInputs)
        XCTAssertTrue(AttachmentCompatibility.shouldRetryWithoutFileAttachments(attachmentPolicy: .preferProviderAttachments, error: .serverError("unsupported input_file")))
        XCTAssertFalse(AttachmentCompatibility.shouldRetryWithoutFileAttachments(attachmentPolicy: .inlineTextOnly, error: .serverError("unsupported input_file")))
        XCTAssertFalse(AttachmentCompatibility.shouldRetryWithoutFileAttachments(attachmentPolicy: .preferProviderAttachments, error: .unauthorized))
    }

    func testPublicToolCallCodableKeepsArgumentsOpaque() throws {
        let original = ToolCall(id: "call:1", type: "function", function: .init(name: "inspect", arguments: "{\"raw\":\"é 😀\"}"))
        let decoded = try JSONDecoder().decode(ToolCall.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.function.name, original.function.name)
        XCTAssertEqual(Array(decoded.function.arguments.utf8), Array(original.function.arguments.utf8))
    }

    func testSSEMultilineAndUnterminatedCompatibilityEventsWithoutNetwork() async throws {
        var buffered: [String] = []
        try await SSEStreamParser.parse(data: Data(": comment\r\ndata: first\r\ndata: second\r\n\r\ndata: tail".utf8), deliveryMode: .bufferedEvents) { buffered.append($0) }
        XCTAssertEqual(buffered, ["first\nsecond", "tail"])
        var compatible: [String] = []
        try await SSEStreamParser.parse(data: Data("data: {\"ok\":true}\ndata: [DONE]".utf8)) { compatible.append($0) }
        XCTAssertEqual(compatible, ["{\"ok\":true}", "[DONE]"])
    }
}
