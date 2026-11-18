import '../models/product.dart';

/// The final menu and prices agreed with the client (see CLAUDE.md).
/// Loaded into Firestore by the admin from Settings > Load CNNO menu.
/// Gula Apong was removed by the client: do not add it.
const List<Product> cnnoMenu = [
  Product(
    id: 'og-cinnamon',
    name: 'OG Cinnamon Roll',
    category: ProductCategory.single,
    tagline: 'The OG.',
    description:
        'Soft, fluffy roll filled with buttery cinnamon sugar, topped with smooth cream cheese frosting and a dusting of cinnamon.',
    imageAsset: 'assets/images/OG_Cinnamon.png',
    variants: [ProductVariant(name: 'Single', price: 8)],
    sortOrder: 1,
  ),
  Product(
    id: 'chocolate',
    name: 'Chocolate Roll',
    category: ProductCategory.single,
    tagline: 'For the choco lovers.',
    description:
        'Rich chocolate roll filled with milk chocolate, topped with silky chocolate frosting and chocolate chips.',
    imageAsset: 'assets/images/Chocolate.png',
    variants: [ProductVariant(name: 'Single', price: 10)],
    sortOrder: 2,
  ),
  Product(
    id: 'pistachio',
    name: 'Pistachio Roll',
    category: ProductCategory.single,
    tagline: 'Crave some nuts?',
    description:
        'Buttery soft roll filled with creamy pistachio sauce, topped with pistachio frosting and crushed pistachio nuts.',
    imageAsset: 'assets/images/Pistachio.png',
    variants: [ProductVariant(name: 'Single', price: 11)],
    sortOrder: 3,
  ),
  Product(
    id: 'baby-rolls',
    name: 'Baby Rolls (box)',
    category: ProductCategory.baby,
    description: 'A box of Baby Rolls. Choose your flavour.',
    imageAsset: 'assets/images/Baby_Rolls.png',
    variants: [
      ProductVariant(name: 'OG', price: 14),
      ProductVariant(name: 'Choco', price: 16),
      ProductVariant(name: 'Pista', price: 17),
    ],
    sortOrder: 4,
  ),
  Product(
    id: 'duo-box',
    name: 'Duo Box',
    category: ProductCategory.duo,
    description: 'Two rolls in one box. Choose your pair.',
    imageAsset: 'assets/images/Duo_Box.png',
    variants: [
      ProductVariant(name: 'OG + OG', price: 15),
      ProductVariant(name: 'Choco + Choco', price: 19),
      ProductVariant(name: 'Pista + Pista', price: 20),
      ProductVariant(name: 'OG + Choco', price: 17),
      ProductVariant(name: 'OG + Pista', price: 18),
      ProductVariant(name: 'Choco + Pista', price: 20),
    ],
    sortOrder: 5,
  ),
  Product(
    id: 'party-box',
    name: 'Party Box',
    category: ProductCategory.party,
    description: 'A Party Box for sharing. Choose your flavour.',
    imageAsset: 'assets/images/Party_Box.png',
    variants: [
      ProductVariant(name: 'OG', price: 54),
      ProductVariant(name: 'Choco', price: 63),
      ProductVariant(name: 'Pista', price: 72),
    ],
    sortOrder: 6,
  ),
];

/// Flavour names used for customer preferences (FR-AI-01).
const List<String> flavourOptions = ['OG', 'Chocolate', 'Pistachio'];
