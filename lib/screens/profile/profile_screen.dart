import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/theme_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/errors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.isSignedIn) auth.loadProfile();
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<AuthService>().signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translateSupabaseError(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: Consumer<AuthService>(
        builder: (context, auth, _) {
          final themeController = context.watch<ThemeController>();
          final profile = auth.profile;
          final name = profile?.displayName ??
              auth.userFullName ??
              (auth.email?.split('@').first ?? 'كشاف');
          final initials = profile?.initials ??
              (name.isEmpty
                  ? '؟'
                  : name
                      .split(' ')
                      .where((p) => p.isNotEmpty)
                      .map((p) => p.substring(0, 1))
                      .take(2)
                      .join());

          return ResponsivePage(
            maxWidth: 720,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        UserAvatar(profile: profile, fullName: name, radius: 34),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? initials : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                auth.email ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'حساب نشط',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle(theme, colorScheme, 'التفضيلات'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          themeController.themeMode == ThemeMode.dark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: colorScheme.primary,
                        ),
                        title: const Text('الوضع الليلي'),
                        subtitle: const Text('تبديل مظهر التطبيق'),
                        value: themeController.themeMode == ThemeMode.dark,
                        onChanged: (_) => themeController.toggleTheme(),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(
                          Icons.language_rounded,
                          color: colorScheme.primary,
                        ),
                        title: const Text('اللغة'),
                        subtitle: Text(themeController.isArabic ? 'العربية' : 'English'),
                        trailing: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              label: Text('عربي'),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('EN'),
                            ),
                          ],
                          selected: {themeController.isArabic},
                          showSelectedIcon: false,
                          onSelectionChanged: (value) {
                            themeController.setLocale(
                              value.first ? const Locale('ar') : const Locale('en'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle(theme, colorScheme, 'معلومات'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.info_outline_rounded,
                          color: colorScheme.primary,
                        ),
                        title: const Text('عن المنصة'),
                        subtitle: const Text('نُسخة قيد التطوير'),
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: AppConfig.appNameAr,
                          applicationVersion: 'الإصدار ${AppConfig.appVersion}',
                          applicationLegalese: AppConfig.appName,
                        ),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      const ListTile(
                        leading: Icon(Icons.tag),
                        title: Text('نسخة التطبيق'),
                        subtitle: Text('1.0.0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: colorScheme.errorContainer.withValues(alpha: 0.4),
                  child: ListTile(
                    leading: Icon(
                      Icons.logout_rounded,
                      color: colorScheme.onErrorContainer,
                    ),
                    title: Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: _signOut,
                  ),
                ),
                const SizedBox(height: 16),
                const EmptyState(
                  icon: Icons.boy_rounded,
                  title: 'معًا نحو كشافة أفضل',
                  subtitle: 'منصة الكشافة التاسعة',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, ColorScheme colorScheme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}