import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/enums.dart';
import '../providers/auth_provider.dart';

class AuthFlowView extends ConsumerStatefulWidget {
  const AuthFlowView({super.key});

  @override
  ConsumerState<AuthFlowView> createState() => _AuthFlowViewState();
}

class _AuthFlowViewState extends ConsumerState<AuthFlowView> {
  String _step = 'role'; // 'role', 'register', 'login'
  UserRole _selectedRole = UserRole.elderly;

  // Controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _showRegPassword = false;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _showLoginPassword = false;

  String? _authError;
  String? _regSuccessMsg;

  // Standard Email Validation Regular Expression
  final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  @override
  void dispose() {
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  void _handleSelectRole(UserRole role) {
    setState(() {
      _selectedRole = role;
      _authError = null;
      _regSuccessMsg = null;
      _step = 'register';
    });
  }

  // Registration Handler with Email Validation
  Future<void> _handleRegister() async {
    setState(() {
      _authError = null;
      _regSuccessMsg = null;
    });

    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;
    final confirmPassword = _regConfirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _authError = 'Please fill in all required fields.');
      return;
    }

    if (!_emailRegExp.hasMatch(email)) {
      setState(() => _authError = 'Please enter a valid email address (e.g. name@domain.com).');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _authError = 'Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      setState(() => _authError = 'Password should be at least 6 characters.');
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          name: name,
          email: email,
          password: password,
          role: _selectedRole.name,
        );

    if (success && mounted) {
      setState(() {
        _regSuccessMsg = 'Registration successful! Please log in with your credentials.';
        _loginEmailController.text = email;
        _loginPasswordController.text = '';
        _step = 'login';
      });
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage;
      setState(() => _authError = error ?? 'Registration failed.');
    }
  }

  // Login Handler with Email Validation
  Future<void> _handleLogin() async {
    setState(() => _authError = null);

    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _authError = 'Please provide both email and password.');
      return;
    }

    if (!_emailRegExp.hasMatch(email)) {
      setState(() => _authError = 'Please enter a valid email address.');
      return;
    }

    final success = await ref.read(authProvider.notifier).login(
          email,
          password,
        );

    if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage;
      setState(() => _authError = error ?? 'Invalid credentials.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.favorite, color: Color(0xFFEF4444), size: 38),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'HomeCare Portal',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'CAREGIVER, FAMILY & SENIOR PORTAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_authError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFFCA5A5), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _authError!,
                              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_regSuccessMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Color(0xFF6EE7B7), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _regSuccessMsg!,
                              style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentStep(authState.isLoading),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isLoading) {
    switch (_step) {
      case 'role':
        return _buildRoleStep();
      case 'register':
        return _buildRegisterStep(isLoading);
      case 'login':
        return _buildLoginStep(isLoading);
      default:
        return _buildRoleStep();
    }
  }

  Widget _buildRoleStep() {
    return Column(
      key: const ValueKey('step_role'),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF262626),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF404040)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'STEP 1: SELECT YOUR ROLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFA3A3A3),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                emoji: '👵',
                title: 'Senior / Elderly',
                description: 'Simplified high-contrast view, big SOS & reminders',
                role: UserRole.elderly,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                emoji: '🩺',
                title: 'Caregiver Specialist',
                description: 'Log vitals, write care reports with photos & manage tasks',
                role: UserRole.caregiver,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                emoji: '👨‍👩‍👧',
                title: 'Family Member',
                description: 'View care reports, photo feeds, vitals & live updates',
                role: UserRole.family,
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String emoji,
    required String title,
    required String description,
    required UserRole role,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _handleSelectRole(role),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF404040)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF737373)),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterStep(bool isLoading) {
    return Container(
      key: const ValueKey('step_register'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _step = 'role'),
                icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFFA3A3A3)),
                label: const Text('Back', style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'ROLE: ${_selectedRole.name.toUpperCase()}',
                  style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Create Account',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your details to register as a ${_selectedRole.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 12),
          ),
          const SizedBox(height: 20),
          _buildDarkTextField(
            controller: _regNameController,
            label: 'FULL NAME',
            icon: Icons.person_outline,
            hint: 'e.g. Sarah Johnson',
          ),
          const SizedBox(height: 12),
          _buildDarkTextField(
            controller: _regEmailController,
            label: 'EMAIL ADDRESS',
            icon: Icons.email_outlined,
            hint: 'name@domain.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildDarkTextField(
            controller: _regPasswordController,
            label: 'PASSWORD',
            icon: Icons.lock_outline,
            hint: 'At least 6 characters',
            obscureText: !_showRegPassword,
            suffixIcon: IconButton(
              icon: Icon(_showRegPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
              onPressed: () => setState(() => _showRegPassword = !_showRegPassword),
            ),
          ),
          const SizedBox(height: 12),
          _buildDarkTextField(
            controller: _regConfirmPasswordController,
            label: 'CONFIRM PASSWORD',
            icon: Icons.security_outlined,
            hint: 'Re-enter password',
            obscureText: !_showRegPassword,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('PROCEED TO LOGIN', style: TextStyle(fontWeight: FontWeight.w900)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => setState(() {
                _authError = null;
                _step = 'login';
              }),
              child: const Text.rich(
                TextSpan(
                  text: 'Already registered? ',
                  style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Sign In Here',
                      style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold),
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

  Widget _buildLoginStep(bool isLoading) {
    return Container(
      key: const ValueKey('step_login'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _step = 'register'),
                icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFFA3A3A3)),
                label: const Text('Back', style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'ACCOUNT LOGIN',
                  style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter your email and password to access HomeCare',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 12),
          ),
          const SizedBox(height: 20),
          _buildDarkTextField(
            controller: _loginEmailController,
            label: 'EMAIL ADDRESS',
            icon: Icons.email_outlined,
            hint: 'name@domain.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildDarkTextField(
            controller: _loginPasswordController,
            label: 'PASSWORD',
            icon: Icons.lock_outline,
            hint: 'Enter your password',
            obscureText: !_showLoginPassword,
            suffixIcon: IconButton(
              icon: Icon(_showLoginPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
              onPressed: () => setState(() => _showLoginPassword = !_showLoginPassword),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SIGN IN TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => setState(() {
                _authError = null;
                _step = 'register';
              }),
              child: const Text.rich(
                TextSpan(
                  text: 'Need a new account? ',
                  style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Register Now',
                      style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold),
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

  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF525252), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF737373), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF171717),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}