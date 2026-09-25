import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import '../widgets/location_fields.dart';
import 'password_reset_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _otp = TextEditingController();
  bool _register = false;
  bool _awaitingOtp = false;
  bool _busy = false;
  bool _obscure = true;
  bool _requestedLocations = false;
  Map<String, dynamic> _locations = {};
  String? _gender, _bloodGroup, _division, _district, _subdistrict;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedLocations) {
      _requestedLocations = true;
      _loadLocations();
    }
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await context.read<ApiService>().locations();
      if (mounted) setState(() => _locations = locations);
    } catch (_) {
      // Login remains available; registration will ask the user to retry.
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmation.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submitCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    if (_register &&
        (_division == null || _district == null || _subdistrict == null)) {
      _showMessage('Choose your division, district, and subdistrict.');
      return;
    }
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthState>();
      if (_register) {
        final debugOtp = await auth.requestRegistration({
          'email': _email.text.trim().toLowerCase(),
          'phone_number': _phone.text.trim(),
          'name': _name.text.trim(),
          'gender': _gender,
          'blood_group': _bloodGroup,
          'division': _division,
          'district': _district,
          'subdistrict': _subdistrict,
          'password': _password.text,
          'confirm_password': _confirmation.text,
        });
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
    body: Column(
      children: [
        // Gradient hero header
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.gradientHeader,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7F5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/brand_mark.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Rokto Dorkar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _awaitingOtp
                        ? 'Verify ${_email.text.trim()}'
                        : _register
                        ? 'Create your verified donor account'
                        : 'Find the right donor, faster',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(210),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 0),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (value) => (value?.length ?? 0) < 8
                              ? 'Use at least 8 characters'
                              : null,
                        ),
                        if (_register) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (value) => value?.trim().isEmpty ?? true
                                ? 'Enter your name'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Mobile number',
                              hintText: '01XXXXXXXXX',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) {
                              final digits = (value ?? '').replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              return digits.length < 10
                                  ? 'Enter a valid mobile number'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _bloodGroup,
                                  decoration: const InputDecoration(
                                    labelText: 'Blood group',
                                  ),
                                  items: bloodGroups
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _bloodGroup = value),
                                  validator: (value) =>
                                      value == null ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _gender,
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'male',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'female',
                                      child: Text('Female'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'other',
                                      child: Text('Other'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _gender = value),
                                  validator: (value) =>
                                      value == null ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_locations.isEmpty)
                            OutlinedButton.icon(
                              onPressed: _loadLocations,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Load locations'),
                            )
                          else
                            LocationFields(
                              locations: _locations,
                              division: _division,
                              district: _district,
                              subdistrict: _subdistrict,
                              onDivisionChanged: (value) => setState(() {
                                _division = value;
                                _district = _subdistrict = null;
                              }),
                              onDistrictChanged: (value) => setState(() {
                                _district = value;
                                _subdistrict = null;
                              }),
                              onSubdistrictChanged: (value) =>
                                  setState(() => _subdistrict = value),
                            ),
                        ],
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
                          onPressed: _busy || (_register && _locations.isEmpty)
                              ? null
                              : _submitCredentials,
                          child: _busy
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _register
                                      ? 'Send verification code'
                                      : 'Log in',
                                ),
                        ),
                        if (!_register)
                          TextButton.icon(
                            onPressed: _busy
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => PasswordResetScreen(
                                        initialEmail: _email.text.trim(),
                                      ),
                                    ),
                                  ),
                            icon: const Icon(Icons.lock_reset_outlined),
                            label: const Text('Forgot password?'),
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
      ],
    ),
  );
}
