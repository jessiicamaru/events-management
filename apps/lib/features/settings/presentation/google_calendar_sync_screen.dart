import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';

class GoogleCalendarSyncScreen extends ConsumerStatefulWidget {
  const GoogleCalendarSyncScreen({super.key});

  @override
  ConsumerState<GoogleCalendarSyncScreen> createState() => _GoogleCalendarSyncScreenState();
}

class _GoogleCalendarSyncScreenState extends ConsumerState<GoogleCalendarSyncScreen> {
  bool _isLoading = false;
  
  // Note: Replace with your actual Web application client ID (not Android client ID) from Google Console
  // to request a serverAuthCode that can be exchanged on the backend.
  static const String _serverClientId = '';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
    serverClientId: _serverClientId,
  );

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    final translations = ref.read(translationsProvider);

    try {
      // Force sign out first to ensure we get a fresh serverAuthCode on retry
      await _googleSignIn.signOut().catchError((_) => null);

      // Sign in with Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }

      final authCode = account.serverAuthCode;
      final email = account.email;

      if (authCode == null || authCode.isEmpty) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Google Auth Error'),
            description: Text('Server auth code was not returned. Ensure serverClientId is configured correctly.'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Send Auth Code to backend
      final apiService = ref.read(apiServiceProvider);
      await apiService.connectGoogleCalendar(authCode, email);

      // Refresh data
      ref.invalidate(userProfileProvider);
      ref.invalidate(eventsProvider);

      ShadToaster.of(context).show(
        ShadToast(
          title: Text(translations.translate('google_sync_title')),
          description: Text(translations.translate('google_sync_success')),
        ),
      );
    } catch (e) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: Text(translations.translate('google_sync_title')),
          description: Text('${translations.translate('google_sync_failed')}: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isLoading = true);
    final translations = ref.read(translationsProvider);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.syncGoogleCalendar();

      ref.invalidate(eventsProvider);

      ShadToaster.of(context).show(
        ShadToast(
          title: Text(translations.translate('google_sync_title')),
          description: Text(translations.translate('google_sync_success')),
        ),
      );
    } catch (e) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: Text(translations.translate('google_sync_title')),
          description: Text('${translations.translate('google_sync_failed')}: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    final translations = ref.read(translationsProvider);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.disconnectGoogleCalendar();

      // Disconnect Google sign-in client
      await _googleSignIn.signOut().catchError((_) => null);

      ref.invalidate(userProfileProvider);
      ref.invalidate(eventsProvider);

      ShadToaster.of(context).show(
        ShadToast(
          title: Text(translations.translate('google_sync_title')),
          description: const Text('Google Calendar disconnected.'),
        ),
      );
    } catch (e) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: Text(translations.translate('google_sync_title')),
          description: Text('Disconnect failed: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final translations = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('google_sync_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.foreground,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              ShadCard(
                title: Text(
                  translations.translate('google_sync_title'),
                  style: theme.textTheme.large,
                ),
                description: Text(translations.translate('google_sync_desc')),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: profileAsync.when(
                          data: (profile) {
                            final googleEmail = profile.googleEmail;
                            final isConnected = googleEmail != null && googleEmail.isNotEmpty;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isConnected 
                                      ? '${translations.translate('google_connected_to')}:' 
                                      : translations.translate('google_not_connected'),
                                  style: theme.textTheme.muted,
                                ),
                                if (isConnected)
                                  Text(
                                    googleEmail,
                                    style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold),
                                  ),
                              ],
                            );
                          },
                          loading: () => const Text('Loading account status...'),
                          error: (_, __) => const Text('Error loading account status'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              profileAsync.when(
                data: (profile) {
                  final googleEmail = profile.googleEmail;
                  final isConnected = googleEmail != null && googleEmail.isNotEmpty;

                  if (isConnected) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ShadButton(
                          onPressed: _isLoading ? null : _syncNow,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isLoading 
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(LucideIcons.refreshCw, size: 16),
                              const SizedBox(width: 8),
                              Text(translations.translate('google_sync_now_btn')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ShadButton.destructive(
                          onPressed: _isLoading ? null : _disconnect,
                          child: Text(translations.translate('google_disconnect_btn')),
                        ),
                      ],
                    );
                  } else {
                    return ShadButton(
                      onPressed: _isLoading ? null : _connect,
                      child: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(translations.translate('google_connect_btn')),
                    );
                  }
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
