import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'config/theme_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/root_shell.dart';
import 'services/auth_service.dart';
import 'services/music_cache_service.dart';
import 'services/music_service.dart';
import 'services/post_service.dart';
import 'services/product_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  } catch (error) {
    debugPrint('Supabase initialization failed: $error');
  }

  final client = Supabase.instance.client;
  final authService = AuthService(client);

  final themeController = ThemeController(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(
          value: PostService(client, authService),
        ),
        ChangeNotifierProvider.value(value: ProductService(client)),
        ChangeNotifierProvider.value(value: MusicService(client)),
        ChangeNotifierProvider.value(value: MusicCacheService()),
        Provider.value(value: StorageService(client)),
      ],
      child: const NinthScoutApp(),
    ),
  );
}

class NinthScoutApp extends StatelessWidget {
  const NinthScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeController.themeMode,
      locale: themeController.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.isSignedIn) return const AuthScreen();
    return const RootShell();
  }
}