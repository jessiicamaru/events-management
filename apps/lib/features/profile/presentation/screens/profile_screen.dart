import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/user_profile_provider.dart';
import '../../../../core/localization/locale_provider.dart';

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
                                      color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
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
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return ShadDialog(
          title: Text(translations.translate('change_password_title')),
          description: Text(translations.translate('change_password_desc')),
          actions: [
            ShadButton.secondary(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translations.translate('cancel')),
            ),
            ShadButton(
              onPressed: () async {
                final currentPassword = currentPasswordController.text;
                final newPassword = newPasswordController.text;

                if (currentPassword.isEmpty || newPassword.isEmpty) {
                  ShadToaster.of(context).show(
                    const ShadToast.destructive(
                      title: Text('Password fields cannot be empty'),
                    ),
                  );
                  return;
                }

                try {
                  await ref.read(userProfileProvider.notifier).changePassword(currentPassword, newPassword);
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
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: Text(translations.translate('change_password_error')),
                        description: Text(e.toString()),
                      ),
                    );
                  }
                }
              },
              child: Text(translations.translate('change_password_title')),
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
                  controller: currentPasswordController,
                  obscureText: true,
                  placeholder: Text(translations.translate('current_password')),
                ),
                const SizedBox(height: 16),
                Text(translations.translate('new_password'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ShadInput(
                  controller: newPasswordController,
                  obscureText: true,
                  placeholder: Text(translations.translate('new_password')),
                ),
              ],
            ),
          ),
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
