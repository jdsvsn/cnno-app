enum UserRole { customer, admin }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.favouriteFlavours = const [],
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;

  /// Used by Smart Recommendation (FR-AI-01).
  final List<String> favouriteFlavours;

  bool get isAdmin => role == UserRole.admin;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        name: (m['name'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        role: m['role'] == 'admin' ? UserRole.admin : UserRole.customer,
        favouriteFlavours:
            ((m['favouriteFlavours'] as List?) ?? const []).cast<String>(),
      );
}
