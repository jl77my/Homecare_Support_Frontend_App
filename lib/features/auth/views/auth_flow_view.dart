import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AuthFlowView extends ConsumerStatefulWidget {
  const AuthFlowView({super.key});

  @override
  ConsumerState<AuthFlowView> createState() => _AuthFlowViewState();
}

class _AuthFlowViewState extends ConsumerState<AuthFlowView> {
  String _step = 'role';
  UserRole _selectedRole = UserRole.elderly;
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirmPassword = TextEditingController();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _acceptedTerms = false;
  bool _showRegPassword = false;
  bool _showLoginPassword = false;
  String? _message;
  bool _messageIsError = true;

  @override
  void dispose() {
    _regName.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regConfirmPassword.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    super.dispose();
  }

  void _go(String step) => setState(() {
        _step = step;
        _message = null;
      });

  void _setMessage(String text, {bool error = true}) => setState(() {
        _message = text;
        _messageIsError = error;
      });

  Future<void> _register() async {
    final name = _regName.text.trim();
    final email = _regEmail.text.trim();
    final password = _regPassword.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _setMessage('Complete all required fields.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _setMessage('Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _setMessage('Password must contain at least 6 characters.');
      return;
    }
    if (password != _regConfirmPassword.text) {
      _setMessage('Passwords do not match.');
      return;
    }
    if (!_acceptedTerms) {
      _setMessage('Accept the Terms of Service and Privacy Policy to continue.');
      return;
    }
    final success = await ref.read(authProvider.notifier).register(
          name: name,
          email: email,
          password: password,
          role: _selectedRole.name,
        );
    if (!mounted) return;
    if (success) {
      _loginEmail.text = email;
      _go('login');
      _setMessage('Account created. Sign in to continue.', error: false);
    } else {
      _setMessage(ref.read(authProvider).errorMessage ?? 'Registration failed. Please try again.');
    }
  }

  Future<void> _login() async {
    final email = _loginEmail.text.trim();
    final password = _loginPassword.text;
    if (email.isEmpty || password.isEmpty) {
      _setMessage('Enter your email address and password.');
      return;
    }
    final success = await ref.read(authProvider.notifier).login(email, password);
    if (!success && mounted) {
      _setMessage(ref.read(authProvider).errorMessage ?? 'Sign in failed. Check your details and try again.');
    }
  }

  void _showTerms() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'HomeCare protects personal and health information and shares it only with the care connections you authorize. By continuing, you consent to secure storage and care-team sharing for the app’s supported features.',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth < 420 ? 22 : 32, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _step == 'role'
                      ? _rolePage()
                      : _step == 'register'
                          ? _registerPage(loading)
                          : _loginPage(loading),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand() => const Text.rich(
        TextSpan(children: [
          TextSpan(text: 'Home', style: TextStyle(color: AppTheme.navy)),
          TextSpan(text: 'Care', style: TextStyle(color: AppTheme.primaryBlue)),
        ]),
        style: TextStyle(fontFamily: 'Georgia', fontSize: 29, fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
      );

  Widget _rolePage() {
    return Column(
      key: const ValueKey('role'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _brand(),
        const SizedBox(height: 28),
        const Text('Welcome to HomeCare', style: _authHeadingStyle, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Choose how you’ll use the app', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: AppTheme.textMuted)),
        const SizedBox(height: 26),
        _roleCard(UserRole.elderly, Icons.volunteer_activism_outlined, 'I’m receiving care', 'Manage your health and connect with your care team'),
        const SizedBox(height: 12),
        _roleCard(UserRole.caregiver, Icons.person_add_alt_1_outlined, 'I’m a caregiver', 'Provide care and support to someone you care for'),
        const SizedBox(height: 12),
        _roleCard(UserRole.family, Icons.people_outline_rounded, 'I’m family', 'Stay informed and support your loved one’s care'),
        const SizedBox(height: 28),
        FilledButton(onPressed: () => _go('register'), child: const Text('Continue')),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Already have an account? '),
          TextButton(onPressed: () => _go('login'), child: const Text('Sign in')),
        ]),
      ],
    );
  }

  Widget _roleCard(UserRole role, IconData icon, String title, String subtitle) {
    final selected = _selectedRole == role;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0F7FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppTheme.primaryBlue : AppTheme.border, width: selected ? 2 : 1),
          ),
          child: Row(children: [
            Container(width: 64, height: 64, decoration: const BoxDecoration(color: Color(0xFFE5F2FF), shape: BoxShape.circle), child: Icon(icon, color: AppTheme.primaryBlue, size: 32)),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, height: 1.4)),
            ])),
            Icon(selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded, color: AppTheme.primaryBlue),
          ]),
        ),
      ),
    );
  }

  Widget _registerPage(bool loading) {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _back(() => _go('role')),
        const SizedBox(height: 22),
        const Text('Create your account', style: _authHeadingStyle),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: Chip(avatar: const Icon(Icons.person_outline, size: 20), label: Text(_roleName(_selectedRole)))),
        const SizedBox(height: 18),
        _fieldLabel('Full name'),
        TextField(controller: _regName, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.name], decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded), hintText: 'e.g. Maria Tan')),
        const SizedBox(height: 14),
        _fieldLabel('Email address'),
        TextField(controller: _regEmail, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded), hintText: 'name@example.com')),
        const SizedBox(height: 14),
        _fieldLabel('Password'),
        _passwordField(_regPassword, _showRegPassword, () => setState(() => _showRegPassword = !_showRegPassword), hintText: 'At least 6 characters'),
        const SizedBox(height: 14),
        _fieldLabel('Confirm password'),
        _passwordField(_regConfirmPassword, _showRegPassword, () => setState(() => _showRegPassword = !_showRegPassword), hintText: 'Re-enter your password', onSubmitted: (_) => _register()),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Checkbox(value: _acceptedTerms, onChanged: loading ? null : (value) => setState(() => _acceptedTerms = value ?? false)),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(children: [
            const Text('I agree to the '),
            InkWell(onTap: _showTerms, child: const Text('Terms of Service and Privacy Policy', style: TextStyle(color: AppTheme.primaryBlue, decoration: TextDecoration.underline))),
          ]))),
        ]),
        _statusMessage(),
        const SizedBox(height: 16),
        FilledButton(onPressed: loading ? null : _register, child: loading ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create account')),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Already registered? '), TextButton(onPressed: () => _go('login'), child: const Text('Sign in'))]),
      ],
    );
  }

  Widget _loginPage(bool loading) {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _back(() => _go('role')),
        const SizedBox(height: 28),
        const Text('Welcome back', style: _authHeadingStyle),
        const SizedBox(height: 8),
        const Text('Sign in to continue', style: TextStyle(fontSize: 17, color: AppTheme.textMuted)),
        const SizedBox(height: 36),
        _fieldLabel('Email address'),
        TextField(controller: _loginEmail, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded), hintText: 'name@example.com')),
        const SizedBox(height: 16),
        _fieldLabel('Password'),
        _passwordField(_loginPassword, _showLoginPassword, () => setState(() => _showLoginPassword = !_showLoginPassword), hintText: 'Enter your password', onSubmitted: (_) => _login()),
        _statusMessage(),
        const SizedBox(height: 30),
        FilledButton(onPressed: loading ? null : _login, child: loading ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in')),
        const SizedBox(height: 28),
        Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Text('or', style: TextStyle(color: AppTheme.textMuted))), const Expanded(child: Divider())]),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: () => _go('register'), child: const Text('Create an account')),
      ],
    );
  }

  Widget _back(VoidCallback action) => Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: action, tooltip: 'Back', icon: const Icon(Icons.arrow_back_rounded), constraints: const BoxConstraints(minWidth: 48, minHeight: 48)));

  Widget _fieldLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)));

  Widget _passwordField(TextEditingController controller, bool visible, VoidCallback toggle, {required String hintText, ValueChanged<String>? onSubmitted}) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onSubmitted: onSubmitted,
      decoration: InputDecoration(hintText: hintText, prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: toggle, tooltip: visible ? 'Hide password' : 'Show password', icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined))),
    );
  }

  Widget _statusMessage() {
    if (_message == null) return const SizedBox.shrink();
    final color = _messageIsError ? AppTheme.primaryRed : AppTheme.primaryGreen;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(_messageIsError ? Icons.error_outline : Icons.check_circle_outline, color: color, size: 20), const SizedBox(width: 8), Expanded(child: Text(_message!, style: TextStyle(color: color, fontWeight: FontWeight.w600)))]),
      ),
    );
  }

  String _roleName(UserRole role) => switch (role) {
        UserRole.elderly => 'Receiving care',
        UserRole.caregiver => 'Caregiver',
        UserRole.family => 'Family member',
        UserRole.admin => 'Administrator',
      };
}

const _authHeadingStyle = TextStyle(
  fontFamily: 'Georgia',
  color: AppTheme.navy,
  fontSize: 30,
  height: 1.18,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
);
