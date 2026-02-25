import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _avatarController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phone);
    _addressController = TextEditingController(text: user?.address);
    _avatarController = TextEditingController(text: user?.avatar);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(authProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            avatar: _avatarController.text.trim(),
          );

      if (mounted) {
        final t = ref.read(localeProvider.notifier).translate;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('Profile updated successfully'))),
          );
          context.pop();
        } else {
          final error = ref.read(authProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t(error ?? 'Failed to update profile'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(localeProvider.notifier).translate;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            HugeIcons.strokeRoundedArrowLeft01,
            color: Colors.black,
          ),
        ),
        title: Text(
          t('Edit Profile'),
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                        image: _avatarController.text.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_avatarController.text),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _avatarController.text.isEmpty
                          ? const Icon(
                              HugeIcons.strokeRoundedUser,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          HugeIcons.strokeRoundedCamera01,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                label: t('Full Name'),
                controller: _nameController,
                icon: HugeIcons.strokeRoundedUser,
                validator: (val) => val == null || val.isEmpty
                    ? t('Please enter your name')
                    : null,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: t('Phone Number'),
                controller: _phoneController,
                icon: HugeIcons.strokeRoundedSmartPhone01,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: t('Address'),
                controller: _addressController,
                icon: HugeIcons.strokeRoundedLocation01,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: t('Avatar URL'),
                controller: _avatarController,
                icon: HugeIcons.strokeRoundedLink01,
                hint: t('Enter image URL'),
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          t('Save Changes'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
        ),
      ],
    );
  }
}
