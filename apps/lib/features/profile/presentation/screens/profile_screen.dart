import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:dio/dio.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  DateTime? _selectedDob;
  String? _selectedGender;
  String _selectedAvatar = '👤';

  final List<String> _avatars = ['👤', '🐱', '🐶', '🦊', '🐼', '🦁', '🐸', '🐨', '🦄', '🤖'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _dobController = TextEditingController();
    _phoneController = TextEditingController();
    
    // Prepopulate after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileAsyncValue = ref.read(userProfileProvider);
      profileAsyncValue.whenData((profile) {
        setState(() {
          _nameController.text = profile.displayName ?? '';
          _bioController.text = profile.bio ?? '';
          _selectedDob = profile.dateOfBirth;
          if (_selectedDob != null) {
            _dobController.text = "${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}";
          }
          _selectedGender = profile.gender;
          _phoneController.text = profile.phoneNumber ?? '';
          _selectedAvatar = profile.avatar ?? '👤';
        });
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('profile_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.foreground,
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar display & selection
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.muted,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getBorderColor(profile.avatarBorderColor),
                                width: 4,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _selectedAvatar,
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            translations.translate('profile_avatar'),
                            style: theme.textTheme.small,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _avatars.length,
                              itemBuilder: (context, index) {
                                final av = _avatars[index];
                                final isSelected = av == _selectedAvatar;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedAvatar = av),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(av, style: const TextStyle(fontSize: 24)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Display Name
                    Text(translations.translate('profile_name'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: _nameController,
                      placeholder: Text(translations.translate('profile_name')),
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    Text(translations.translate('profile_bio'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: _bioController,
                      placeholder: Text(translations.translate('profile_bio')),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    Text(translations.translate('profile_dob'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDob ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDob = picked;
                            _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: ShadInput(
                          controller: _dobController,
                          placeholder: Text(translations.translate('profile_dob')),
                          trailing: const Icon(LucideIcons.calendar, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    Text(translations.translate('profile_gender'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ShadSelect<String>(
                      placeholder: Text(translations.translate('profile_gender')),
                      initialValue: _selectedGender,
                      options: [
                        ShadOption(value: 'Male', child: Text(translations.translate('gender_male'))),
                        ShadOption(value: 'Female', child: Text(translations.translate('gender_female'))),
                        ShadOption(value: 'Other', child: Text(translations.translate('gender_other'))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedGender = val;
                        });
                      },
                      selectedOptionBuilder: (context, value) {
                        if (value == 'Male') return Text(translations.translate('gender_male'));
                        if (value == 'Female') return Text(translations.translate('gender_female'));
                        return Text(translations.translate('gender_other'));
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    Text(translations.translate('profile_phone'), style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ShadInput(
                      controller: _phoneController,
                      placeholder: Text(translations.translate('profile_phone')),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ShadButton(
                      child: Text(translations.translate('save_profile')),
                      onPressed: () async {
                        await ref.read(userProfileProvider.notifier).updateProfile(
                          displayName: _nameController.text.trim(),
                          bio: _bioController.text.trim(),
                          dateOfBirth: _selectedDob,
                          gender: _selectedGender,
                          phoneNumber: _phoneController.text.trim(),
                          avatar: _selectedAvatar,
                        );

                        if (mounted) {
                          ShadToaster.of(context).show(
                            ShadToast(
                              title: Text(translations.translate('profile_update_success')),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Change Password Trigger
                    ShadButton.outline(
                      child: Text(translations.translate('change_password_title')),
                      onPressed: () => _showChangePasswordDialog(context),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final translations = ref.read(translationsProvider);
    showDialog(
      context: context,
      builder: (context) {
        return _ChangePasswordDialog(
          translations: translations,
          ref: ref,
        );
      },
    );
  }

  Color _getBorderColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.grey;
    try {
      final colorStr = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$colorStr', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final AppTranslations translations;
  final WidgetRef ref;

  const _ChangePasswordDialog({
    required this.translations,
    required this.ref,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
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

