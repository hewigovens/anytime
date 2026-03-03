import Foundation

struct FoundationModelPasteHints {
    let cityQuery: String?
    let timeZoneID: String?
    let offsetToken: String?
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
enum FoundationModelPasteInterpreter {
    static func interpret(_ text: String) async -> FoundationModelPasteHints? {
        let model = SystemLanguageModel.default
        guard model.isAvailable, model.supportsLocale() else {
            return nil
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            Extract schedule details from pasted text.
            Return JSON only with keys cityQuery, timeZoneID, and offsetToken.
            Use null when unknown. Never explain the result.
            """
        )

        do {
            let response = try await session.respond(
                to: """
                Clipboard text:
                \(text)
                """,
                options: GenerationOptions(
                    temperature: 0,
                    maximumResponseTokens: 120
                )
            )
            return decodeHints(from: response.content)
        } catch {
            return nil
        }
    }

    private static func decodeHints(from rawResponse: String) -> FoundationModelPasteHints? {
        let cleaned = rawResponse
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            return nil
        }

        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let cityQuery = (object["cityQuery"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let timeZoneID = (object["timeZoneID"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let offsetToken = (object["offsetToken"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cityQuery?.isEmpty != false, timeZoneID?.isEmpty != false, offsetToken?.isEmpty != false {
            return nil
        }

        return FoundationModelPasteHints(
            cityQuery: cityQuery?.nilIfEmpty,
            timeZoneID: timeZoneID?.nilIfEmpty,
            offsetToken: offsetToken?.nilIfEmpty
        )
    }
}
#endif

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
