import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
              description: Text('You can now log in.'),
            ),
          );
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Registration Failed'),
            description: const Text('Could not create account. Try again.'),
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
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style: ShadTheme.of(context).textTheme.h2,
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
                const SizedBox(height: 16),
                ShadInput(
                  controller: _confirmPasswordController,
                  placeholder: const Text('Confirm Password'),
                  obscureText: !_showConfirmPassword,
                  trailing: GestureDetector(
                    onTap: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    child: Icon(
                      _showConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                    ),
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
    );
  }
}
