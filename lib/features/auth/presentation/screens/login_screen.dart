import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _green = Color(0xFF00C853);
const _greenDark = Color(0xFF004D20);
const _greenLight = Color(0xFF69F0AE);
const _bg = Color(0xFFF7F9F5);
const _surface = Colors.white;
const _textDark = Color(0xFF0D1F0F);
const _textMid = Color(0xFF4A5E4C);
const _textLight = Color(0xFF8FA891);
const _error = Color(0xFFD32F2F);
const _border = Color(0xFFDDE8DF);

// ─── Auth Mode ────────────────────────────────────────────────────────────────

enum _AuthMode { login, signup }

// ─── Screen ───────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  _AuthMode _mode = _AuthMode.login;
  bool _loading = false;
  bool _obscure = true;
  String? _errorMsg;
  String _selectedRole = 'customer';

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  late final AnimationController _enterCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _floatCtrl;

  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _shake;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _floatCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _float = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _shakeCtrl.dispose();
    _floatCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  // ── Auth Logic ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final supabase = Supabase.instance.client;

      if (_mode == _AuthMode.login) {
        if (_emailCtrl.text.trim().isEmpty) {
          throw Exception('Please enter your email address');
        }
        if (_passCtrl.text.isEmpty) {
          throw Exception('Please enter your password');
        }

        final res = await supabase.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

        if (res.user == null) throw Exception('Login failed');

        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', res.user!.id)
            .maybeSingle();

        if (mounted) {
          final role = profile?['role'] as String? ?? 'customer';
          context.go(role == 'owner' ? '/admin' : '/home');
        }
      } else {
        if (_nameCtrl.text.trim().isEmpty) {
          throw Exception('Please enter your full name');
        }
        if (_nationalIdCtrl.text.trim().isEmpty) {
          throw Exception('Please enter your national ID number');
        }

        // Profile row is created automatically by the handle_new_user DB trigger.
        final res = await supabase.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          data: {
            'full_name': _nameCtrl.text.trim(),
            'id_number': _nationalIdCtrl.text.trim(),
            'role': _selectedRole,
          },
        );

        if (res.user == null) throw Exception('Sign up failed');

        if (mounted) context.go(_selectedRole == 'owner' ? '/admin' : '/home');
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Invalid login')) msg = 'Wrong email or password.';
      if (msg.contains('already registered')) msg = 'Email already in use.';
      if (msg.contains('Password should')) {
        msg = 'Password must be 6+ characters.';
      }

      setState(() => _errorMsg = msg.replaceAll('Exception: ', ''));
      _shakeCtrl.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchMode() {
    setState(() {
      _mode = _mode == _AuthMode.login ? _AuthMode.signup : _AuthMode.login;
      _errorMsg = null;
      _selectedRole = 'customer';
      _nationalIdCtrl.clear();
    });
    _enterCtrl.forward(from: 0.6);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(size),
      ),
    );
  }

  // ── Desktop Layout (split screen) ────────────────────────────────────────────

  Widget _buildDesktopLayout(Size size) {
    return Row(
      children: [
        // Left — brand panel
        Expanded(
          flex: 5,
          child: _buildBrandPanel(),
        ),
        // Right — form panel
        Expanded(
          flex: 4,
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideIn,
              child: Container(
                color: _surface,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 56, vertical: 48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _buildForm(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile Layout (stacked) ──────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Compact brand header
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_greenDark, _green],
              ),
            ),
            child: Stack(
              children: [
                _floatingBikeIcons(compact: true),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.pedal_bike,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Bike Buddy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your city. Your pace.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Form
          FadeTransition(
            opacity: _fadeIn,
            child: Container(
              color: _surface,
              padding: const EdgeInsets.all(28),
              child: _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Brand Panel ──────────────────────────────────────────────────────────────

  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_greenDark, Color(0xFF006B29), _green],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Geometric grid overlay
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(),
          ),
          // Floating bike icons
          _floatingBikeIcons(),
          // Brand content
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Logo
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.pedal_bike,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Bike Buddy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Hero text
                FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride the\ncity your\nway.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          height: 1.05,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Find nearby bikes, book in seconds,\nand ride on your schedule.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Feature pills
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _featurePill('⚡ Electric bikes'),
                          _featurePill('📍 Live availability'),
                          _featurePill('🔲 Scan & ride'),
                          _featurePill('💳 Easy checkout'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featurePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Floating Bike Icons ──────────────────────────────────────────────────────

  Widget _floatingBikeIcons({bool compact = false}) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, __) => Stack(
        children: [
          Positioned(
            top: compact ? 20 : 80,
            right: compact ? 20 : 60,
            child: Transform.translate(
              offset: Offset(0, _float.value * 0.8),
              child: _glassIcon(Icons.electric_bike, 52, 0.15),
            ),
          ),
          Positioned(
            top: compact ? 60 : 200,
            right: compact ? 80 : 180,
            child: Transform.translate(
              offset: Offset(0, -_float.value * 0.6),
              child: _glassIcon(Icons.directions_bike, 36, 0.1),
            ),
          ),
          Positioned(
            bottom: compact ? 20 : 120,
            right: compact ? 40 : 80,
            child: Transform.translate(
              offset: Offset(0, _float.value * 0.5),
              child: _glassIcon(Icons.pedal_bike, 44, 0.12),
            ),
          ),
          if (!compact)
            Positioned(
              top: 340,
              right: 260,
              child: Transform.translate(
                offset: Offset(0, -_float.value * 0.4),
                child: _glassIcon(Icons.terrain, 28, 0.08),
              ),
            ),
        ],
      ),
    );
  }

  Widget _glassIcon(IconData icon, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity * 1.5),
        ),
      ),
      child: Icon(icon,
          color: Colors.white.withValues(alpha: 0.6), size: size * 0.5),
    );
  }

  // ── Form ─────────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    final isLogin = _mode == _AuthMode.login;

    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) => Transform.translate(
        offset: Offset(_errorMsg != null ? _shake.value : 0, 0),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode toggle tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _modeTab('Sign In', _AuthMode.login),
                _modeTab('Create Account', _AuthMode.signup),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Heading
          Text(
            isLogin ? 'Welcome back' : 'Join Bike Buddy',
            style: const TextStyle(
              color: _textDark,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLogin
                ? 'Sign in to access your rides and bookings.'
                : 'Create your account to start booking bikes.',
            style: const TextStyle(
              color: _textLight,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Signup-only fields
          if (!isLogin) ...[
            _inputField(
              label: 'Full Name',
              hint: 'e.g. Alex Kamau',
              controller: _nameCtrl,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _inputField(
              label: 'National ID Number',
              hint: 'e.g. 12345678',
              controller: _nationalIdCtrl,
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _roleSelector(),
            const SizedBox(height: 16),
          ],

          // Email
          _inputField(
            label: 'Email Address',
            hint: 'you@example.com',
            controller: _emailCtrl,
            focusNode: _emailFocus,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Password
          _inputField(
            label: 'Password',
            hint: isLogin ? 'Your password' : 'Min. 6 characters',
            controller: _passCtrl,
            focusNode: _passFocus,
            icon: Icons.lock_outline,
            obscure: _obscure,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _textLight,
                size: 20,
              ),
            ),
          ),

          // Forgot password (login only)
          if (isLogin) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _handleForgotPassword,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: _green,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          // Error message
          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _error.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: _error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(
                        color: _error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_green, _greenLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        isLogin ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          const Row(
            children: [
              Expanded(child: Divider(color: _border, thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('or',
                    style: TextStyle(color: _textLight, fontSize: 13)),
              ),
              Expanded(child: Divider(color: _border, thickness: 1)),
            ],
          ),

          const SizedBox(height: 20),

          // Continue as guest
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon:
                  const Icon(Icons.explore_outlined, color: _textMid, size: 20),
              label: const Text(
                'Browse without signing in',
                style: TextStyle(
                  color: _textMid,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Switch mode
          Center(
            child: GestureDetector(
              onTap: _switchMode,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: _textLight),
                  children: [
                    TextSpan(
                      text: isLogin
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                    ),
                    TextSpan(
                      text: isLogin ? 'Sign up' : 'Sign in',
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _modeTab(String label, _AuthMode mode) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_mode != mode) _switchMode();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? _textDark : _textLight,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I am a',
          style: TextStyle(
            color: _textMid,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 1.5),
          ),
          child: Row(
            children: [
              _roleTab('Customer', 'customer', Icons.person_outline),
              _roleTab('Shop Owner', 'owner', Icons.store_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roleTab(String label, String value, IconData icon) {
    final selected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _green : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : _textLight,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _textLight,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textMid,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: const TextStyle(
            color: _textDark,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _textLight, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: _textLight, size: 20),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: suffix,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }

  // ── Forgot Password ──────────────────────────────────────────────────────────

  Future<void> _handleForgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Enter your email above first.');
      _shakeCtrl.forward(from: 0);
      return;
    }
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(_emailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reset link sent — check your email!'),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMsg = 'Could not send reset email.');
      _shakeCtrl.forward(from: 0);
    }
  }
}

// ─── Grid Background Painter ──────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const spacing = 48.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Accent circles
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.7), 120, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2), 80, circlePaint);
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
