import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:dio/dio.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';

class ChangePasswordDialog extends StatefulWidget {
  final AppTranslations translations;
  final WidgetRef ref;

  const ChangePasswordDialog({
    super.key,
    required this.translations,
    required this.ref,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmNewPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onTextChanged);
    _confirmNewPasswordController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onTextChanged);
    _confirmNewPasswordController.removeListener(_onTextChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  Widget _buildRequirementRow(String text, bool isMet, ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? LucideIcons.check : LucideIcons.circle,
            color: isMet ? Colors.green : theme.colorScheme.mutedForeground.withValues(alpha: 0.4),
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.small.copyWith(
                color: isMet ? Colors.green : theme.colorScheme.mutedForeground,
                fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final translations = widget.translations;
    final password = _newPasswordController.text;

    final hasMinLength = password.length >= 6;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[^a-zA-Z0-9]'));
    final allRequirementsMet = hasMinLength && hasUppercase && hasLowercase && hasDigit && hasSpecial;

    final isMatching = _confirmNewPasswordController.text.isNotEmpty &&
        _confirmNewPasswordController.text == _newPasswordController.text;

    return ShadDialog(
      title: Text(translations.translate('change_password_title')),
      description: Text(translations.translate('change_password_desc')),
      actions: [
        ShadButton.secondary(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(translations.translate('cancel')),
        ),
        ShadButton(
          onPressed: _isLoading
              ? null
              : () async {
                  final currentPassword = _currentPasswordController.text.trim();
                  final newPassword = _newPasswordController.text.trim();
                  final confirmPassword = _confirmNewPasswordController.text.trim();

                  if (currentPassword.isEmpty) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: Text(translations.translate('error_title')),
                        description: Text(translations.translate('current_password_empty')),
                      ),
                    );
                    return;
                  }

                  if (newPassword.isEmpty) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: Text(translations.translate('error_title')),
                        description: Text(translations.translate('new_password_empty')),
                      ),
                    );
                    return;
                  }

                  if (confirmPassword.isEmpty) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: Text(translations.translate('error_title')),
                        description: Text(translations.translate('confirm_password_empty')),
                      ),
                    );
                    return;
                  }

                  if (newPassword != confirmPassword) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: Text(translations.translate('pwd_mismatch_title')),
                        description: Text(translations.translate('pwd_mismatch_desc')),
                      ),
                    );
                    return;
                  }

                  if (!allRequirementsMet) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: Text(translations.translate('error_title')),
                        description: Text(translations.translate('new_password_invalid')),
                      ),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    await widget.ref.read(userProfileProvider.notifier).changePassword(currentPassword, newPassword);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ShadToaster.of(context).show(
                        ShadToast(
                          title: Text(translations.translate('change_password_success')),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      String errorMessage = translations.translate('change_password_error');
                      if (e is DioException) {
                        final responseData = e.response?.data;
                        if (responseData is List) {
                          final errorMessages = <String>[];
                          for (final err in responseData) {
                            if (err is Map && err.containsKey('description')) {
                              final desc = err['description'].toString();
                              errorMessages.add(translations.translateBackendError(desc));
                            }
                          }
                          if (errorMessages.isNotEmpty) {
                            errorMessage = errorMessages.join('\n');
                          }
                        } else if (responseData is Map && responseData.containsKey('errors')) {
                          final errors = responseData['errors'];
                          if (errors is Map) {
                            final errorMessages = <String>[];
                            errors.forEach((key, value) {
                              if (value is List) {
                                errorMessages.addAll(value.map((v) => translations.translateBackendError(v.toString())));
                              } else {
                                errorMessages.add(translations.translateBackendError(value.toString()));
                              }
                            });
                            if (errorMessages.isNotEmpty) {
                              errorMessage = errorMessages.join('\n');
                            }
                          }
                        } else if (responseData is Map && responseData.containsKey('description')) {
                          errorMessage = translations.translateBackendError(responseData['description'].toString());
                        }
                      }
                      ShadToaster.of(context).show(
                        ShadToast.destructive(
                          title: Text(translations.translate('change_password_error')),
                          description: Text(errorMessage),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(translations.translate('change_password_title')),
        ),
      ],
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(translations.translate('current_password'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ShadInput(
              controller: _currentPasswordController,
              obscureText: !_showCurrentPassword,
              placeholder: Text(translations.translate('current_password')),
              trailing: GestureDetector(
                onTap: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                child: Icon(
                  _showCurrentPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(translations.translate('new_password'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ShadInput(
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              placeholder: Text(translations.translate('new_password')),
              trailing: GestureDetector(
                onTap: () => setState(() => _showNewPassword = !_showNewPassword),
                child: Icon(
                  _showNewPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Password requirements
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translations.translate('pwd_reqs_title'),
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRequirementRow(translations.translate('req_len'), hasMinLength, theme),
                  _buildRequirementRow(translations.translate('req_lower'), hasLowercase, theme),
                  _buildRequirementRow(translations.translate('req_upper'), hasUppercase, theme),
                  _buildRequirementRow(translations.translate('req_digit'), hasDigit, theme),
                  _buildRequirementRow(translations.translate('req_special'), hasSpecial, theme),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(translations.translate('confirm_password_placeholder'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ShadInput(
              controller: _confirmNewPasswordController,
              obscureText: !_showConfirmNewPassword,
              placeholder: Text(translations.translate('confirm_password_placeholder')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMatching)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        LucideIcons.check,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                  GestureDetector(
                    onTap: () => setState(() => _showConfirmNewPassword = !_showConfirmNewPassword),
                    child: Icon(
                      _showConfirmNewPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
