// lib/screens/login_screen.dart
// Login / Signup screen with email/password authentication

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

/// Login/Signup screen with toggle between modes
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form keys for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // State
  bool _isSignup = false; // false = login, true = signup
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Handle login or signup based on current mode
  Future<void> _submit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();

      if (_isSignup) {
        // Sign up new user
        final credential = await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );

        // Create user profile in Firestore
        if (credential.user != null && mounted) {
          await context.read<AuthService>().signOut(); // Just to be safe
          // Note: ProductService.createUserProfile is called from HomeScreen init
        }
      } else {
        // Sign in existing user
        await authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      // Navigation to HomeScreen is handled by authStateChanges listener in main.dart
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Toggle between login and signup mode
  void _toggleMode() {
    setState(() {
      _isSignup = !_isSignup;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wideLayout = constraints.maxWidth >= 820;
            final content = wideLayout
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(child: _buildHero(compact: false)),
                      const SizedBox(width: 28),
                      Expanded(child: _buildAuthForm()),
                    ],
                  )
                : Column(
                    children: [
                      _buildHero(compact: true),
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: _buildAuthForm(),
                      ),
                    ],
                  );

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: wideLayout ? 1120 : 520,
                  minHeight: wideLayout ? 620 : 0,
                ),
                child: wideLayout
                    ? Padding(
                        padding: const EdgeInsets.all(28),
                        child: content,
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: content,
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero({required bool compact}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: compact ? 260 : 620,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF285C46), Color(0xFF34785A), Color(0xFF6A9B68)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -75,
              top: compact ? -100 : 75,
              child: _heroOrb(compact ? 230 : 390, 0.08),
            ),
            Positioned(
              right: compact ? -35 : 48,
              top: compact ? 65 : 140,
              child: _essentialsIllustration(compact: compact),
            ),
            Positioned(
              left: compact ? -80 : -115,
              bottom: compact ? -150 : -175,
              child: _heroOrb(compact ? 210 : 300, 0.07),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 22 : 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'ShelfSense',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'FRESH LIVING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: compact ? 190 : 380,
                    child: Text(
                      _isSignup
                          ? 'Stay on top of every essential.'
                          : 'Keep every essential in check.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 27 : 42,
                        height: 1.08,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: compact ? 270 : 350,
                    child: Text(
                      'Track groceries, medicine, soap, skincare and more—all in one place.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: compact ? 13 : 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 34),
                  if (!compact)
                    const Row(
                      children: [
                        _Benefit(
                          icon: Icons.calendar_month_outlined,
                          label: 'Expiry tracking',
                        ),
                        SizedBox(width: 22),
                        _Benefit(
                          icon: Icons.notifications_active_outlined,
                          label: 'Timely reminders',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroOrb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1,
        ),
      ),
    );
  }

  Widget _essentialsIllustration({required bool compact}) {
    final size = compact ? 42.0 : 58.0;
    return SizedBox(
      width: compact ? 112 : 180,
      height: compact ? 112 : 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: compact ? 88 : 142,
            height: compact ? 88 : 142,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: compact ? 43 : 68,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _essentialBubble(Icons.medication_outlined, size),
          ),
          Positioned(
            left: 0,
            bottom: 5,
            child: _essentialBubble(Icons.soap_outlined, size * 0.84),
          ),
          Positioned(
            right: compact ? 3 : 12,
            bottom: compact ? 0 : 8,
            child: _essentialBubble(Icons.spa_outlined, size * 0.72),
          ),
        ],
      ),
    );
  }

  Widget _essentialBubble(IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE4F0D9),
        borderRadius: BorderRadius.circular(size * 0.36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF34785A), size: size * 0.52),
    );
  }

  Widget _buildAuthForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isSignup ? 'Create your account' : 'Welcome back',
                style: const TextStyle(
                  color: Color(0xFF29372F),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _isSignup
                    ? 'Track groceries, medicine, soap and more in one place.'
                    : 'Sign in to see what needs your attention next.',
                style: const TextStyle(
                  color: Color(0xFF7B887F),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _modeTab('Sign in', selected: !_isSignup),
                    _modeTab('Create account', selected: _isSignup),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEFED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF2CECA)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFF9C342F)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_isSignup) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip:
                        _obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (_isSignup && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_isSignup) ...[
                const SizedBox(height: 8),
                const Text(
                  'Use at least 6 characters for your password.',
                  style: TextStyle(
                    color: Color(0xFF7B887F),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        _isSignup ? 'Create my account' : 'Sign in securely',
                      ),
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: Color(0xFF839087),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Your personal items stay private',
                    style: TextStyle(
                      color: Color(0xFF7B887F),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTab(String label, {required bool selected}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF29372F).withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: _isLoading || selected ? null : _toggleMode,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF34785A)
                    : const Color(0xFF7B887F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Benefit({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 17),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
