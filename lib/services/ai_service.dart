import 'package:cloud_functions/cloud_functions.dart';

import '../config.dart';
import '../models/product.dart';

class Recommendation {
  const Recommendation({required this.product, required this.message, required this.fromAi});
  final Product product;
  final String message;

  /// False when the Cloud Function was unavailable and a simple rule was used.
  final bool fromAi;
}

class ChatMessage {
  const ChatMessage({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;
  Map<String, dynamic> toMap() => {'role': fromUser ? 'user' : 'model', 'text': text};
}

/// Generative AI features. Gemini is only called through Cloud Functions,
/// so no API key is ever in the app (see functions/index.js).
class AiService {
  AiService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  final FirebaseFunctions _functions;

  /// FR-AI-01 Smart Recommendation.
  Future<Recommendation?> recommend({
    required List<Product> products,
    required List<String> favourites,
    required List<String> pastOrderedProductIds,
  }) async {
    final available = products.where((p) => p.available).toList();
    if (available.isEmpty) return null;
    try {
      final res = await _functions
          .httpsCallable('recommend', options: HttpsCallableOptions(timeout: const Duration(seconds: 15)))
          .call<Map<String, dynamic>>({});
      final data = Map<String, dynamic>.from(res.data);
      final match = available.where((p) => p.id == data['productId']);
      if (match.isNotEmpty && (data['message'] as String?)?.isNotEmpty == true) {
        return Recommendation(product: match.first, message: data['message'] as String, fromAi: true);
      }
    } catch (_) {
      // Fall through to the simple rule below.
    }
    return fallbackRecommendation(available, favourites, pastOrderedProductIds);
  }

  /// Rule used when the AI is unavailable: suggest an available single roll
  /// the customer has not ordered yet, preferring their favourite flavours.
  static Recommendation? fallbackRecommendation(
    List<Product> available,
    List<String> favourites,
    List<String> pastOrderedProductIds,
  ) {
    final singles = available.where((p) => p.category == ProductCategory.single).toList();
    final pool = singles.isEmpty ? available : singles;
    if (pool.isEmpty) return null;
    bool isFav(Product p) =>
        favourites.any((f) => p.name.toLowerCase().contains(f.toLowerCase()));
    final notTried = pool.where((p) => !pastOrderedProductIds.contains(p.id)).toList();
    final candidates = notTried.isEmpty ? pool : notTried;
    final pick = candidates.firstWhere(isFav, orElse: () => candidates.first);
    final flavour = pick.name.replaceAll(' Roll', '');
    return Recommendation(
      product: pick,
      message: 'Fancy something new? Try the $flavour.',
      fromAi: false,
    );
  }

  /// FR-AI-02 Order Assistant. Answers come from the Firestore menu on the
  /// server. Any failure returns the "contact CNNO" message (BR-09).
  Future<String> ask(List<ChatMessage> history) async {
    try {
      final res = await _functions
          .httpsCallable('orderAssistant', options: HttpsCallableOptions(timeout: const Duration(seconds: 20)))
          .call<Map<String, dynamic>>({
        'messages': history.map((m) => m.toMap()).toList(),
      });
      final reply = (Map<String, dynamic>.from(res.data)['reply'] as String?)?.trim();
      return (reply == null || reply.isEmpty) ? AppConfig.contactCnnoMessage : reply;
    } catch (_) {
      return AppConfig.assistantUnavailableMessage;
    }
  }
}
