import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Passwords do not match'),
          description: const Text('Please make sure both passwords are the same.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ref.read(apiServiceProvider).post('/register', data: {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast(
              title: Text('Account Created'),
              description: Text('Your account has been created. You can now log in.'),
            ),
          );
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Could not create account. Please try again.';
        if (e is DioException) {
          final responseData = e.response?.data;
          if (responseData is Map && responseData.containsKey('errors')) {
            final errors = responseData['errors'];
            if (errors is Map) {
              final errorMessages = <String>[];
              errors.forEach((key, value) {
                if (value is List) {
                  errorMessages.addAll(value.map((v) => v.toString()));
                } else {
                  errorMessages.add(value.toString());
                }
              });
              if (errorMessages.isNotEmpty) {
                errorMessage = errorMessages.join('\n');
              }
            }
          }
        }
        
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Registration Failed'),
            description: Text(errorMessage),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRequirementRow(String text, bool isMet, ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? LucideIcons.check : LucideIcons.circle,
            color: isMet ? Colors.green : theme.colorScheme.mutedForeground.withOpacity(0.4),
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
    final password = _passwordController.text;
    
    final hasMinLength = password.length >= 6;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[^a-zA-Z0-9]'));

    return Scaffold(
      body: Center(
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
                    'Create Account',
                    style: theme.textTheme.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ShadInput(
                    controller: _emailController,
                    placeholder: const Text('Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  ShadInput(
                    controller: _passwordController,
                    placeholder: const Text('Password'),
                    obscureText: !_showPassword,
                    trailing: GestureDetector(
                      onTap: () => setState(() => _showPassword = !_showPassword),
                      child: Icon(
                        _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
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
                          'Password Requirements:',
                          style: theme.textTheme.small.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRequirementRow('At least 6 characters', hasMinLength, theme),
                        _buildRequirementRow('At least one lowercase letter (a-z)', hasLowercase, theme),
                        _buildRequirementRow('At least one uppercase letter (A-Z)', hasUppercase, theme),
                        _buildRequirementRow('At least one digit (0-9)', hasDigit, theme),
                        _buildRequirementRow('At least one special character (!, @, #, ...)', hasSpecial, theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShadInput(
                    controller: _confirmPasswordController,
                    placeholder: const Text('Confirm Password'),
                    obscureText: !_showConfirmPassword,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_confirmPasswordController.text.isNotEmpty &&
                            _confirmPasswordController.text == _passwordController.text)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(
                              LucideIcons.check,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                        GestureDetector(
                          onTap: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                          child: Icon(
                            _showConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ShadButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Register'),
                  ),
                  const SizedBox(height: 16),
                  ShadButton.outline(
                    onPressed: () => context.go('/login'),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
