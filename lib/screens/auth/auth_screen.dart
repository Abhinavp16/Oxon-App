import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  // Controllers
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();

  // State
  bool _isLogin = true;
  bool _isWholesaler = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToOxonCallsAndMessages = false;
  bool _showPolicyDetails = false;
  File? _documentFile;

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  static const _surfaceWarm = Color(0xFFF7F7F6);
  static const _textDark = Color(0xFF1C1917);
  static const _textMuted = Color(0xFF78716C);
  static const _borderColor = Color(0xFFE7E1D7);

  Color get _primaryColor =>
      _isWholesaler ? const Color(0xFFF97316) : const Color(0xFFF59E0B);
  Color get _primaryDark =>
      _isWholesaler ? const Color(0xFFEA580C) : const Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _businessNameController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() async {
    await _fadeController.reverse();
    setState(() {
      _isLogin = !_isLogin;
      if (!_isLogin) {
        _isWholesaler = false;
      }
      _clearFields();
    });
    _slideController.reset();
    _slideController.forward();
    _fadeController.forward();
  }

  void _toggleRole(bool isWholesaler) {
    if (_isWholesaler == isWholesaler) return;

    setState(() {
      _isWholesaler = isWholesaler;
      _documentFile = null;
    });
  }

  void _clearFields() {
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _nameController.clear();
    _businessNameController.clear();
    _agreedToOxonCallsAndMessages = false;
    _showPolicyDetails = false;
    _documentFile = null;
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _documentFile = File(image.path);
      });
    }
  }

  Future<void> _handleSubmit() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (_isLogin) {
      final success = await ref
          .read(authProvider.notifier)
          .loginWithPhone(
            phone: phone,
            password: password,
            expectedRole: _isWholesaler ? 'wholesaler' : 'buyer',
          );
      if (success && mounted) {
        context.go('/home');
      }
    } else {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _showError('Please enter your name');
        return;
      }
      if (_confirmPasswordController.text != password) {
        _showError('Passwords do not match');
        return;
      }
      if (!_agreedToOxonCallsAndMessages) {
        _showError('Please accept Terms & Conditions and Privacy Policy');
        return;
      }

      final success = await ref
          .read(authProvider.notifier)
          .registerWithPhone(
            name: name,
            phone: phone,
            password: password,
            isWholesaler: _isWholesaler,
            businessName: _isWholesaler
                ? _businessNameController.text.trim()
                : null,
          );
      if (success && mounted) {
        context.go('/home');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFEFD),
                        Color(0xFFFFF9F6),
                        Color(0xFFFFFCFA),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -150,
                right: -130,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryColor.withValues(alpha: 0.10),
                        _primaryColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -190,
                left: -160,
                child: Container(
                  width: 430,
                  height: 430,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFB923C).withValues(alpha: 0.08),
                        const Color(0xFFFB923C).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _AuthBackgroundPainter(_primaryColor),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              _buildLogo(),
                              const SizedBox(height: 42),
                              Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _isLogin
                                      ? 'Welcome back'
                                      : 'Create your account',
                                  key: ValueKey(_isLogin),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _textDark,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                _isLogin
                                    ? 'Sign in to pick up where you left off.'
                                    : 'Set up your OXON account in a minute.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 30),
                              if (_isLogin) ...[
                                _buildRoleToggle(),
                                const SizedBox(height: 28),
                              ],
                              if (authState.error != null) ...[
                                _buildErrorBanner(authState.error!),
                                const SizedBox(height: 18),
                              ],
                              _buildForm(),
                              if (!_isLogin) ...[
                                const SizedBox(height: 20),
                                _buildOxonConsentCheckbox(),
                              ],
                              const SizedBox(height: 26),
                              _buildSubmitButton(authState.isLoading),
                              const SizedBox(height: 24),
                              _buildAuthToggle(),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: 58,
          height: 58,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'assets/images/oxon logo.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OXON',
                style: GoogleFonts.plusJakartaSans(
                  color: _textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Marketplace',
                style: GoogleFonts.plusJakartaSans(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9DDD5)),
      ),
      child: SizedBox(
        height: 52,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              alignment: _isWholesaler
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryDark.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: _buildRoleButton('Customer', false)),
                Expanded(child: _buildRoleButton('Wholesaler', true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(String label, bool isWholesaler) {
    final isSelected = _isWholesaler == isWholesaler;

    return GestureDetector(
      onTap: () => _toggleRole(isWholesaler),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? _textDark : const Color(0xFF76675F),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field (signup only)
          if (!_isLogin) ...[
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your name',
              icon: HugeIcons.strokeRoundedUser,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
          ],

          // Phone field
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '10-digit mobile number',
            icon: HugeIcons.strokeRoundedCall,
            keyboardType: TextInputType.phone,
            prefix: '+91 ',
            maxLength: 10,
          ),
          const SizedBox(height: 16),

          // Password field
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: HugeIcons.strokeRoundedLockPassword,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),

          // Confirm password (signup only)
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              icon: HugeIcons.strokeRoundedLockPassword,
              isPassword: true,
              obscureText: _obscureConfirmPassword,
              onToggleObscure: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ],

          // Wholesaler fields
          if (!_isLogin && _isWholesaler) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _businessNameController,
              label: 'Business Name',
              hint: 'Your shop or company name',
              icon: HugeIcons.strokeRoundedStore01,
              required: false,
            ),
            const SizedBox(height: 16),
            _buildDocumentPicker(),
          ],

          // Forgot password (login only)
          if (_isLogin) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.plusJakartaSans(
                    color: _primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? prefix,
    int? maxLength,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: _textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!required) ...[
              const SizedBox(width: 6),
              Text(
                '(Optional)',
                style: GoogleFonts.plusJakartaSans(
                  color: _textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          style: GoogleFonts.plusJakartaSans(
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF57534E),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: HugeIcon(icon: icon, color: _primaryDark, size: 21),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 50,
              minHeight: 54,
            ),
            prefixText: prefix,
            prefixStyle: GoogleFonts.plusJakartaSans(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: HugeIcon(
                      icon: obscureText
                          ? HugeIcons.strokeRoundedViewOff
                          : HugeIcons.strokeRoundedView,
                      color: _textMuted,
                      size: 21,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.only(
              left: 0,
              right: 14,
              top: 15,
              bottom: 15,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Business Document',
              style: GoogleFonts.plusJakartaSans(
                color: _textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(Optional)',
              style: GoogleFonts.plusJakartaSans(
                color: _textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDocument,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _documentFile != null
                  ? _primaryColor.withValues(alpha: 0.08)
                  : _surfaceWarm,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _documentFile != null ? _primaryColor : _borderColor,
                width: _documentFile != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _documentFile != null
                        ? _primaryColor.withValues(alpha: 0.14)
                        : const Color(0xFFFFF3D6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: HugeIcon(
                    icon: _documentFile != null
                        ? HugeIcons.strokeRoundedCheckmarkCircle01
                        : HugeIcons.strokeRoundedFileUpload,
                    color: _documentFile != null ? _primaryColor : _textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _documentFile != null
                            ? 'Document Selected'
                            : 'Upload Document',
                        style: GoogleFonts.plusJakartaSans(
                          color: _textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _documentFile != null
                            ? _documentFile!.path.split('/').last
                            : 'GST certificate, trade license, etc.',
                        style: GoogleFonts.plusJakartaSans(
                          color: _textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_documentFile != null)
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _documentFile = null),
                    color: _textMuted,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _textDark,
          disabledBackgroundColor: _primaryColor.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _textDark,
                ),
              )
            : Text(
                _isLogin ? 'Sign In' : 'Create Account',
                style: GoogleFonts.plusJakartaSans(
                  color: _textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _buildOxonConsentCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreedToOxonCallsAndMessages,
                onChanged: (value) => setState(
                  () => _agreedToOxonCallsAndMessages = value ?? false,
                ),
                activeColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: const BorderSide(color: Color(0xFFC7C7CC), width: 1.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'By continuing, you agree to our Terms & Conditions and Privacy Policy.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _showPolicyDetails = !_showPolicyDetails),
                icon: Icon(
                  _showPolicyDetails
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _textMuted,
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _showPolicyDetails
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '- We collect basic details like name, phone, email, and app usage data.',
                    style: GoogleFonts.plusJakartaSans(
                      color: _textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '- We use this data to process orders, provide support, and improve services.',
                    style: GoogleFonts.plusJakartaSans(
                      color: _textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '- We share data only with logistics, payment, service partners, or legal authorities.',
                    style: GoogleFonts.plusJakartaSans(
                      color: _textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '- You can request access, correction, or deletion of your data where permitted.',
                    style: GoogleFonts.plusJakartaSans(
                      color: _textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthToggle() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isLogin ? "Don't have an account? " : 'Already have an account? ',
            style: GoogleFonts.plusJakartaSans(
              color: _textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: _toggleAuthMode,
            child: Text(
              _isLogin ? 'Sign Up' : 'Sign In',
              style: GoogleFonts.plusJakartaSans(
                color: _primaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackgroundPainter extends CustomPainter {
  const _AuthBackgroundPainter(this.accentColor);

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final softLine = Paint()
      ..color = accentColor.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final faintLine = Paint()
      ..color = accentColor.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final softFill = Paint()
      ..color = accentColor.withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;

    final topShape = Path()
      ..moveTo(size.width * 0.35, -20)
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.06,
        size.width * 0.43,
        size.height * 0.14,
        size.width * 0.66,
        size.height * 0.19,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.23,
        size.width * 0.97,
        size.height * 0.16,
        size.width * 1.08,
        size.height * 0.18,
      )
      ..lineTo(size.width * 1.08, -20)
      ..close();
    canvas.drawPath(topShape, softFill);

    final topSweep = Path()
      ..moveTo(size.width * 0.08, -10)
      ..cubicTo(
        size.width * 0.10,
        size.height * 0.13,
        size.width * 0.18,
        size.height * 0.18,
        size.width * 0.43,
        size.height * 0.20,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.23,
        size.width * 0.84,
        size.height * 0.16,
        size.width * 1.05,
        size.height * 0.18,
      );
    canvas.drawPath(topSweep, softLine);

    final upperEcho = Path()
      ..moveTo(size.width * 0.18, -8)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.09,
        size.width * 0.24,
        size.height * 0.14,
        size.width * 0.50,
        size.height * 0.17,
      )
      ..cubicTo(
        size.width * 0.73,
        size.height * 0.20,
        size.width * 0.88,
        size.height * 0.12,
        size.width * 1.04,
        size.height * 0.14,
      );
    canvas.drawPath(upperEcho, faintLine);

    final lowerGeometry = Path()
      ..moveTo(-20, size.height * 0.70)
      ..lineTo(size.width * 0.24, size.height * 0.78)
      ..lineTo(size.width * 0.07, size.height * 0.94)
      ..lineTo(size.width * 0.34, size.height * 0.84)
      ..lineTo(size.width * 0.22, size.height * 1.03);
    canvas.drawPath(lowerGeometry, softLine);

    final lowerEcho = Path()
      ..moveTo(-10, size.height * 0.76)
      ..lineTo(size.width * 0.16, size.height * 0.83)
      ..lineTo(size.width * 0.02, size.height * 0.91)
      ..lineTo(size.width * 0.27, size.height * 0.88);
    canvas.drawPath(lowerEcho, faintLine);

    canvas.drawCircle(
      Offset(size.width * 0.91, size.height * 0.63),
      size.width * 0.18,
      faintLine,
    );
  }

  @override
  bool shouldRepaint(covariant _AuthBackgroundPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
