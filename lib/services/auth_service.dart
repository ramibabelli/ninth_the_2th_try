import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _client;
  Profile? _profile;

  AuthService(this._client) {
    _client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isSignedIn => currentUser != null;
  String? get userId => currentUser?.id;
  String? get email => currentUser?.email;
  String? get userFullName =>
      currentUser?.userMetadata?['full_name'] as String?;
  Profile? get profile => _profile;

  bool get canEditMusic {
    final role = _profile?.role?.toString();
    return role == 'music-editor' || role == 'admin';
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
    try {
      await loadProfile();
    } catch (e) {
      // لا نمنع تسجيل الدخول في حالة فشل تحميل الملف الشخصي
      debugPrint('فشل تحميل الملف الشخصي: $e');
    }
  }

  Future<void> signOut() async {
    _profile = null;
    await _client.auth.signOut();
    notifyListeners();
  }

  Future<void> loadProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      _profile = data == null ? null : Profile.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('خطأ أثناء تحميل الملف الشخصي: $e');
      _profile = null;
    }
    notifyListeners();
  }

  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _client.from('profiles').upsert({
      'id': uid,
      if (fullName != null && fullName.trim().isNotEmpty)
        'full_name': fullName.trim(),
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty)
        'avatar_url': avatarUrl,
    });
    await loadProfile();
  }
}