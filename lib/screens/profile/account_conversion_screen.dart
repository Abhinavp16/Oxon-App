import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';

class AccountConversionScreen extends ConsumerStatefulWidget {
  const AccountConversionScreen({super.key});

  @override
  ConsumerState<AccountConversionScreen> createState() =>
      _AccountConversionScreenState();
}

class _AccountConversionScreenState
    extends ConsumerState<AccountConversionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _contactPersonController.text = user.name;

      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _gstNumberController.dispose();
    _businessAddressController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitConversion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      final response = await apiClient.post(
        '/auth/convert-to-wholesaler',

        data: {
          'businessName': _businessNameController.text,
          'gstNumber': _gstNumberController.text,
          'businessAddress': _businessAddressController.text,
          'contactPerson': _contactPersonController.text,
          'phone': _phoneController.text,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = response.data['data'];
        final newUser = UserModel.fromJson(userData);
        ref.read(authProvider.notifier).updateUser(newUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Application submitted successfully! Our team will verify your details.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage =
            e.response?.data['message'] ??
            'Failed to submit application. Please try again.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const backgroundWhite = Color(0xFFF8FAFC);
    const surfaceWhite = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF1E293B);
    const textSecondary = Color(0xFF64748B);
    const borderLight = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: textPrimary,
            size: 24,
          ),
        ),
        title: Text(
          'Become a Wholesaler',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Illustration/Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceWhite,
                border: Border(
                  bottom: BorderSide(color: borderLight.withOpacity(0.5)),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedStore01,
                      color: primaryBlue,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Expand Your Business',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get access to exclusive bulk pricing, negotiation tools, and priority support.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderLight.withOpacity(0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUSINESS INFORMATION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _businessNameController,
                        label: 'Business Name',
                        hint: 'Enter your company name',
                        icon: HugeIcons.strokeRoundedBriefcase01,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Business name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _gstNumberController,
                        label: 'GST Number',
                        hint: 'Enter 15-digit GSTIN',
                        icon: HugeIcons.strokeRoundedFile01,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'GST number is required';
                          }
                          if (value!.length != 15) {
                            return 'Invalid GST number format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _businessAddressController,
                        label: 'Business Address',
                        hint: 'Enter full office address',
                        icon: HugeIcons.strokeRoundedLocation01,
                        maxLines: 3,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Address is required'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'CONTACT INFORMATION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _contactPersonController,
                        label: 'Contact Person',
                        hint: 'Full name',
                        icon: HugeIcons.strokeRoundedUser,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Contact person name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter 10-digit mobile number',
                        icon: HugeIcons.strokeRoundedCall02,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Phone number is required';
                          }
                          if (value!.length < 10) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitConversion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Submit Application',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    const textPrimary = Color(0xFF1E293B);
    const textSecondary = Color(0xFF64748B);
    const borderLight = Color(0xFFE2E8F0);
    const primaryBlue = Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: textSecondary.withOpacity(0.5),
            ),
            prefixIcon: HugeIcon(icon: icon, color: textSecondary, size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.02),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
