import Foundation

/// A purchase pulled out of a card alert message.
struct ParsedPurchase: Equatable {
    let amount: Double
    let merchant: String?
}

/// Extracts the peso amount and merchant from a credit card purchase alert,
/// e.g. "...charged PHP 1,250.00 at JOLLIBEE MAKATI on 11/16/26...".
/// Returns nil for messages that aren't purchases (OTPs, payments, declines).
enum TransactionMessageParser {
    private static let ignoredPhrases = [
        "otp", "one-time", "one time pin", "one time password",
        "declined", "reversal", "refund", "payment received", "payment posted",
        "credited", "do not share"
    ]

    // "PHP 1,250.00", "Php1250", "P 89.50", "₱1,250"; not preceded by another letter.
    private static let amountPattern = try! NSRegularExpression(
        pattern: #"(?<![A-Za-z])(?:PHP|P|₱)\s?([0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)"#,
        options: [.caseInsensitive]
    )

    // Merchant follows "at", up to " on <date>", " using", " with", " via", a sentence break, or the end.
    private static let merchantPattern = try! NSRegularExpression(
        pattern: #"\bat\s+(.+?)(?=\s+on\s|\s+using\s|\s+with\s|\s+via\s|[.,;]\s|[.;]?$)"#,
        options: [.caseInsensitive, .anchorsMatchLines]
    )

    static func parse(_ message: String) -> ParsedPurchase? {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = text.lowercased()
        guard !ignoredPhrases.contains(where: lowercased.contains) else { return nil }

        guard let amountText = firstCapture(of: amountPattern, in: text),
              let amount = Double(amountText.replacingOccurrences(of: ",", with: "")),
              amount > 0 else {
            return nil
        }

        let merchant = firstCapture(of: merchantPattern, in: text)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .flatMap { $0.isEmpty ? nil : String($0.prefix(60)) }

        return ParsedPurchase(amount: amount, merchant: merchant)
    }

    private static func firstCapture(of regex: NSRegularExpression, in text: String) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[captureRange])
    }
}
