/// App-wide settings that the client still has to confirm.
/// Change them here only; the rest of the app reads these values.
class AppConfig {
  AppConfig._();

  /// Minimum days between today and the earliest preorder date (BR-03).
  /// TODO(Jude): confirm with the client. Proposed: 1 day.
  static const int preorderLeadDays = 1;

  /// Payment is made outside the app; the app only records the method (BR-08).
  /// TODO(Jude): confirm the accepted methods with the client.
  static const List<String> paymentMethods = [
    'Cash',
    'Bank transfer',
    'DuitNow QR',
  ];

  /// Region used for Cloud Functions (same as Firestore).
  static const String functionsRegion = 'asia-southeast1';

  /// Shown when the AI is unsure or unavailable (BR-09).
  static const String contactCnnoMessage =
      'I am not sure about that one. Please contact CNNO directly and they will help you.';

  static const String brandText = "cnno's bakes";
}
