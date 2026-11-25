import XCTest
@testable import ExpenseTracker

final class TransactionMessageParserTests: XCTestCase {

    func test_parse_readsAmountAndMerchant() {
        let message = "Your RCBC credit card ending 1234 was charged PHP 1,250.00 at JOLLIBEE MAKATI on 11/16/26 12:30PM."

        XCTAssertEqual(
            TransactionMessageParser.parse(message),
            ParsedPurchase(amount: 1250, merchant: "JOLLIBEE MAKATI")
        )
    }

    func test_parse_readsRCBCPurchaseAlert() {
        let message = "Your transaction at UNIQLO SM MARILAO      BU on 11/17 11:45AM for PHP1582.00 using your Card ending in xxxx1234 is approved. If you don't recognize this transaction, call 0288881883 immediately. You can also lock your Card using the RCBC Pulz app to prevent unauthorized transactions."

        XCTAssertEqual(
            TransactionMessageParser.parse(message),
            ParsedPurchase(amount: 1582, merchant: "UNIQLO SM MARILAO BU")
        )
    }

    func test_parse_ignoresRCBCPaymentPosted() {
        XCTAssertNil(TransactionMessageParser.parse("Payment of Php22,277.36 made to Card end 1234 was posted on 11/16."))
    }

    func test_parse_acceptsPesoSignAndShortPrefix() {
        XCTAssertEqual(TransactionMessageParser.parse("Purchase of ₱89.50 at 7-ELEVEN")?.amount, 89.5)
        XCTAssertEqual(TransactionMessageParser.parse("Purchase of P 2,000 at SM STORE.")?.amount, 2000)
        XCTAssertEqual(TransactionMessageParser.parse("Purchase of Php450 at GRAB")?.merchant, "GRAB")
    }

    func test_parse_returnsNilMerchantWhenMissing() {
        XCTAssertEqual(
            TransactionMessageParser.parse("Card purchase PHP 300.00 approved."),
            ParsedPurchase(amount: 300, merchant: nil)
        )
    }

    func test_parse_ignoresNonPurchaseMessages() {
        XCTAssertNil(TransactionMessageParser.parse("Your OTP is 123456 for a PHP 500.00 purchase. Do not share."))
        XCTAssertNil(TransactionMessageParser.parse("Payment received: PHP 5,000.00. Thank you!"))
        XCTAssertNil(TransactionMessageParser.parse("Your PHP 1,000.00 transaction at SHOPEE was declined."))
        XCTAssertNil(TransactionMessageParser.parse("Enjoy 0% installment this holiday season!"))
    }

    func test_parse_doesNotTreatWordsEndingInPAsCurrency() {
        XCTAssertNil(TransactionMessageParser.parse("Visit our shop 24/7 for deals"))
    }

    func test_parse_doesNotIgnorePurchasesThatMentionRewardsCredited() {
        XCTAssertEqual(
            TransactionMessageParser.parse(
                "You earned 15 points credited to your account for this purchase of PHP 1,500.00 at SM SUPERMARKET on 11/20/26."
            ),
            ParsedPurchase(amount: 1500, merchant: "SM SUPERMARKET")
        )
        XCTAssertEqual(
            TransactionMessageParser.parse(
                "Cashback of PHP 20.00 will be credited after your purchase of PHP 1,000.00 at PUREGOLD on 11/20/26."
            ),
            ParsedPurchase(amount: 1000, merchant: "PUREGOLD")
        )
    }

    func test_parse_stillIgnoresAccountLevelCredits() {
        XCTAssertNil(TransactionMessageParser.parse("Payment received: PHP 5,000.00. Thank you!"))
        XCTAssertNil(TransactionMessageParser.parse("Payment of Php22,277.36 made to Card end 1234 was posted on 11/16."))
    }
}
