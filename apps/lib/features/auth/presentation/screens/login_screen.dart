import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/localization/locale_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(apiServiceProvider).post('/login', data: {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      if (response.statusCode == 200 && response.data['accessToken'] != null) {
        final token = response.data['accessToken'];
        await ref.read(authProvider.notifier).login(token);
        if (mounted) {
          context.go('/calendar');
        }
      }
    } catch (e) {
      if (mounted) {
        final translations = ref.read(translationsProvider);
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: Text(translations.translate('login_failed_title')),
            description: Text(translations.translate('login_failed_desc')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final currentLocale = ref.watch(localeProvider);
    final translations = ref.watch(translationsProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          translations.translate('welcome_back'),
                          style: theme.textTheme.h2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ShadInput(
                          controller: _emailController,
                          placeholder: Text(translations.translate('email_placeholder')),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        ShadInput(
                          controller: _passwordController,
                          placeholder: Text(translations.translate('password_placeholder')),
                          obscureText: !_showPassword,
                          trailing: GestureDetector(
                            onTap: () => setState(() => _showPassword = !_showPassword),
                            child: Icon(
                              _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ShadButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(translations.translate('login_button')),
                        ),
                        const SizedBox(height: 16),
                        ShadButton.outline(
                          onPressed: () => context.go('/register'),
                          child: Text(translations.translate('create_account_link')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: ShadButton.outline(
                size: ShadButtonSize.sm,
                width: 40,
                height: 40,
                padding: EdgeInsets.zero,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ShadDialog(
                      title: Text(translations.translate('select_language_title')),
                      description: Text(translations.translate('select_language_desc')),
                      child: Material(
                        type: MaterialType.transparency,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('English'),
                              trailing: currentLocale == AppLocale.en
                                  ? const Icon(LucideIcons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                ref.read(localeProvider.notifier).setLocale(AppLocale.en);
                                Navigator.of(ctx).pop();
                              },
                            ),
                            ListTile(
                              title: const Text('Tiếng Việt'),
                              trailing: currentLocale == AppLocale.vi
                                  ? const Icon(LucideIcons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                ref.read(localeProvider.notifier).setLocale(AppLocale.vi);
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Icon(LucideIcons.languages, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
