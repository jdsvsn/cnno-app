import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// UI-01 Login and Register (FR-01, FR-02).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthService>();
    try {
      if (_register) {
        await auth.register(_name.text, _email.text, _password.text);
      } else {
        await auth.logIn(_email.text, _password.text);
      }
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email first');
      return;
    }
    try {
      await context.read<AuthService>().resetPassword(_email.text);
      if (mounted) showMessage(context, 'Password reset email sent');
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    InputDecoration dec(String hint) => InputDecoration(hintText: hint);
    Widget label(String s) => Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 14),
          child: Text(s, style: t.bodySmall?.copyWith(color: CnnoColors.text)),
        );

    return Scaffold(
      body: Column(
        children: [
          const Awning(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/images/CNNO_Logo_Maroon.png', height: 110),
                    const SizedBox(height: 12),
                    Text('Welcome to CNNO',
                        textAlign: TextAlign.center,
                        style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Handcrafted cinnamon rolls, ordered your way',
                        textAlign: TextAlign.center,
                        style: t.bodyMedium?.copyWith(color: CnnoColors.muted)),
                    const SizedBox(height: 20),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        backgroundColor: CnnoColors.softPink,
                        selectedBackgroundColor: Colors.white,
                        selectedForegroundColor: CnnoColors.text,
                        side: BorderSide.none,
                      ),
                      segments: const [
                        ButtonSegment(value: false, label: Text('Log in')),
                        ButtonSegment(value: true, label: Text('Register')),
                      ],
                      selected: {_register},
                      onSelectionChanged: (s) => setState(() {
                        _register = s.first;
                        _error = null;
                      }),
                    ),
                    if (_register) ...[
                      label('Name'),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: dec('Your name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                      ),
                    ],
                    label('Email'),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: dec('you@email.com'),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    label('Password'),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      decoration: dec('Enter your password').copyWith(
                        suffixIcon: IconButton(
                          tooltip: _hidePassword ? 'Show password' : 'Hide password',
                          icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your password';
                        if (_register && v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (!_register)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: _forgot,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: t.bodyMedium?.copyWith(color: CnnoColors.primary)),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Text(_register ? 'Create account' : 'Log in'),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Admin staff use the same login. The app opens the admin dashboard after sign in.',
                      textAlign: TextAlign.center,
                      style: t.bodySmall?.copyWith(color: CnnoColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
