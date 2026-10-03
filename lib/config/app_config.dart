class AppConfig {
  AppConfig._();

  static const String appName = 'Ninth Scout';
  static const String appNameAr = 'الكشافة التاسعة';
  static const String appVersion = '1.0.0';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fdlvsngnxsamfspyvnrx.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_MyYDVBJFU2qTAtkUO5i03g_Zs3kxtMJ',
  );

  static const String postsBucket = 'posts';
  static const String avatarsBucket = 'avatars';
  static const String productsBucket = 'products';
  static const String musicBucket = 'music';

  static const String currency = 'د.ك';
}
