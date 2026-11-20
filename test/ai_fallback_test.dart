import 'package:cnno_app/data/menu_seed.dart';
import 'package:cnno_app/models/product.dart';
import 'package:cnno_app/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recommendation fallback (FR-AI-01, FR-AI-03)', () {
    test('returns nothing when no product is available', () {
      expect(AiService.fallbackRecommendation(const [], const [], const []), isNull);
    });

    test('suggests a single roll, not a box, when singles are available', () {
      final r = AiService.fallbackRecommendation(cnnoMenu, const [], const []);
      expect(r!.product.category, ProductCategory.single);
    });

    test('uses boxes when every single roll is unavailable', () {
      final boxesOnly = cnnoMenu.where((p) => p.category != ProductCategory.single).toList();
      final r = AiService.fallbackRecommendation(boxesOnly, const [], const []);
      expect(r, isNotNull);
      expect(r!.product.category, isNot(ProductCategory.single));
    });

    test('still suggests something when the customer has tried every roll', () {
      final r = AiService.fallbackRecommendation(
        cnnoMenu,
        const ['chocolate'],
        const ['og-cinnamon', 'chocolate', 'pistachio'],
      );
      expect(r!.product.id, 'chocolate');
    });

    test('favourite matching ignores case', () {
      final r = AiService.fallbackRecommendation(cnnoMenu, const ['PISTACHIO'], const []);
      expect(r!.product.id, 'pistachio');
    });

    test('message names the flavour without the word Roll and never a price', () {
      final r = AiService.fallbackRecommendation(cnnoMenu, const ['Chocolate'], const []);
      expect(r!.message, 'Fancy something new? Try the Chocolate.');
      expect(r.message.contains('RM'), isFalse);
      expect(r.fromAi, isFalse);
    });
  });
}
