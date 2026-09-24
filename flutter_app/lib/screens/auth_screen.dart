import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _otp = TextEditingController();
  bool _register = false;
  bool _awaitingOtp = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmation.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submitCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthState>();
      if (_register) {
        final debugOtp = await auth.requestRegistration(
          _email.text.trim().toLowerCase(),
          _phone.text.trim(),
          _password.text,
          _confirmation.text,
        );
        if (mounted) {
          setState(() => _awaitingOtp = true);
          _showMessage(
            debugOtp == null
                ? 'We sent a verification code to your email.'
                : 'Development OTP: $debugOtp',
          );
        }
      } else {
        await auth.login(_email.text.trim().toLowerCase(), _password.text);
      }
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.text.length != 6) {
      _showMessage('Enter the six-digit verification code.');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AuthState>().verifyRegistration(
        _email.text.trim().toLowerCase(),
        _otp.text,
      );
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _busy = true);
    try {
      final debugOtp = await context.read<AuthState>().resendRegistrationOTP(
        _email.text.trim().toLowerCase(),
      );
      if (mounted) {
        _showMessage(
          debugOtp == null
              ? 'A new verification code was sent.'
              : 'Development OTP: $debugOtp',
        );
      }
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  void _switchMode() {
    setState(() {
      _register = !_register;
      _awaitingOtp = false;
      _otp.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.bloodtype_rounded,
                    size: 82,
                    color: AppTheme.crimson,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rokto Dorkar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _awaitingOtp
                        ? 'Verify ${_email.text.trim()}'
                        : _register
                        ? 'Create your verified donor account'
                        : 'Find the right donor, faster',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  if (_awaitingOtp) ...[
                    TextFormField(
                      controller: _otp,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Six-digit OTP',
                        prefixIcon: Icon(Icons.mark_email_read_outlined),
                      ),
                      onFieldSubmitted: (_) => _verifyOtp(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _verifyOtp,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify and continue'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _resendOtp,
                      child: const Text('Resend code'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _awaitingOtp = false),
                      child: const Text('Change email'),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter a valid email address'
                          : null,
                    ),
                    if (_register) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) => (value?.trim().length ?? 0) < 10
                            ? 'Enter a valid phone number'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) < 8
                          ? 'Use at least 8 characters'
                          : null,
                    ),
                    if (_register) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmation,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                        validator: (value) => value != _password.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submitCredentials,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _register ? 'Send verification code' : 'Log in',
                            ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _switchMode,
                      child: Text(
                        _register
                            ? 'Already registered? Log in'
                            : 'New here? Create an account',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
