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
    // Note: "credited" is deliberately not in this list. Many genuine purchase
    // alerts mention rewards points or cashback being "credited" alongside the
    // purchase itself (e.g. "Earn points credited for this purchase of
    // PHP 1,500.00 at SM SUPERMARKET..."), which would otherwise be wrongly
    // discarded. Account-level credits are still caught by the more specific
    // "payment received"/"payment posted" phrases below.
    private static let ignoredPhrases = [
        "otp", "one-time", "one time pin", "one time password",
        "declined", "reversal", "refund", "payment of", "payment received", "payment posted",
        "do not share"
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

        let fullRange = NSRange(text.startIndex..., in: text)
        let amountMatches = amountPattern.matches(in: text, range: fullRange)
        guard !amountMatches.isEmpty else { return nil }

        let merchantMatch = merchantPattern.firstMatch(in: text, range: fullRange)

        // A message can mention more than one peso amount (e.g. a cashback or
        // rewards figure alongside the purchase itself), so prefer whichever
        // amount immediately precedes the merchant mention over just the
        // first amount in the text.
        let chosenMatch: NSTextCheckingResult
        if let merchantMatch {
            let precedingMatches = amountMatches.filter { $0.range.location <= merchantMatch.range.location }
            chosenMatch = precedingMatches.last ?? amountMatches[0]
        } else {
            chosenMatch = amountMatches[0]
        }

        guard let amountRange = Range(chosenMatch.range(at: 1), in: text),
              let amount = Double(text[amountRange].replacingOccurrences(of: ",", with: "")),
              amount > 0 else {
            return nil
        }

        let merchant = merchantMatch
            .flatMap { Range($0.range(at: 1), in: text) }
            .map { String(text[$0]) }
            // Merchant names are padded with runs of spaces, e.g. "UNIQLO SM MARILAO      BU".
            .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
            .flatMap { $0.isEmpty ? nil : String($0.prefix(60)) }

        return ParsedPurchase(amount: amount, merchant: merchant)
    }
}
