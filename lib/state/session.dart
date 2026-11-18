import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum SessionState { loading, signedOut, signedIn }

/// Holds the signed-in user and their Firestore profile (role decides
/// whether the customer app or the admin dashboard opens).
class Session extends ChangeNotifier {
  Session(this.auth, {FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance {
    _authSub = auth.authChanges().listen(_onAuth);
  }

  final AuthService auth;
  final FirebaseFirestore _db;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  SessionState state = SessionState.loading;
  AppUser? user;

  void _onAuth(User? u) {
    _profileSub?.cancel();
    if (u == null) {
      user = null;
      state = SessionState.signedOut;
      notifyListeners();
      return;
    }
    state = SessionState.loading;
    notifyListeners();
    _profileSub = _db.collection('users').doc(u.uid).snapshots().listen((doc) {
      if (doc.exists) {
        user = AppUser.fromMap(u.uid, doc.data()!);
        state = SessionState.signedIn;
        notifyListeners();
      }
      // While registering, the profile doc may arrive a moment later.
    }, onError: (_) {
      state = SessionState.signedOut;
      notifyListeners();
    });
  }

  Future<void> setFavourites(List<String> flavours) async {
    final u = user;
    if (u == null) return;
    await _db.collection('users').doc(u.uid).update({'favouriteFlavours': flavours});
  }

  Future<void> logOut() => auth.logOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
