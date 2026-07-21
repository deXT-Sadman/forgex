import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(
      email: _emailController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      setState(() => _emailSent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Could not send reset email.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _emailSent
              ? _buildSentView(context)
              : _buildFormView(context, authProvider),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Icon(
            Icons.lock_reset_rounded,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Forgot your password?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter the email linked to your account and we'll send you a link to reset your password.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          CustomTextField(
            label: 'Email',
            controller: _emailController,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 28),
          CustomButton(
            label: 'Send Reset Link',
            isLoading: authProvider.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSentView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read_rounded,
          size: 64,
          color: AppColors.success,
        ),
        const SizedBox(height: 20),
        Text(
          'Check your inbox',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "We've sent a password reset link to ${_emailController.text.trim()}.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        CustomButton(
          label: 'Back to Sign In',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
