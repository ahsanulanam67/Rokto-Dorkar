import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/api_service.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key, required this.initialEmail});

  final String initialEmail;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_codeSent && !(_emailKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await context.read<ApiService>().requestPasswordReset(
        _email.text.trim().toLowerCase(),
      );
      if (mounted) {
        setState(() => _codeSent = true);
        _message('If this email has an active account, a reset code was sent.');
      }
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<ApiService>().confirmPasswordReset(
        email: _email.text.trim().toLowerCase(),
        otp: _otp.text,
        newPassword: _password.text,
        confirmPassword: _confirmation.text,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Password reset. Log in with your new password.'),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset password')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _codeSent ? _buildResetForm() : _buildEmailForm(),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildEmailForm() => Form(
    key: _emailKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_rounded, size: 58, color: AppTheme.red),
        const SizedBox(height: 16),
        Text(
          'Forgot your password?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your verified account email. We will send a six-digit reset code.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) => value == null || !value.contains('@')
              ? 'Enter a valid email address'
              : null,
          onFieldSubmitted: (_) => _requestCode(),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _requestCode,
          child: _busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send reset code'),
        ),
      ],
    ),
  );

  Widget _buildResetForm() => Form(
    key: _resetKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the code sent to ${_email.text.trim()}.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _otp,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(labelText: 'Six-digit OTP'),
          validator: (value) =>
              value?.length == 6 ? null : 'Enter the six-digit code',
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _password,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: (value) =>
              (value?.length ?? 0) < 8 ? 'Use at least 8 characters' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmation,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(
            labelText: 'Confirm new password',
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
          validator: (value) =>
              value == _password.text ? null : 'Passwords do not match',
          onFieldSubmitted: (_) => _resetPassword(),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _resetPassword,
          child: _busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Reset password'),
        ),
        TextButton(
          onPressed: _busy ? null : _requestCode,
          child: const Text('Resend code'),
        ),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _codeSent = false),
          child: const Text('Use a different email'),
        ),
      ],
    ),
  );
}
