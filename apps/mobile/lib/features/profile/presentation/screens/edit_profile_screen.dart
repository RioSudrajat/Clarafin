import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/models/user_profile_model.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/avatar_picker_section.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  int? _selectedAvatarIndex;
  late String _avatarUrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _selectedAvatarIndex = profile.selectedAvatarIndex;
    _avatarUrl = profile.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nama lengkap tidak boleh kosong',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    ref.read(userProfileProvider.notifier).updateProfile(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: _avatarUrl,
      selectedAvatarIndex: _selectedAvatarIndex,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profil berhasil diperbarui!',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        backgroundColor: NeoBrutalism.lime,
      ),
    );

    context.pop();
  }

  void _showCustomPhotoDialog() {
    final customUrlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2.0),
        ),
        title: Text(
          'Unggah Foto Profil',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan tautan gambar atau gunakan contoh foto.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customUrlController,
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoBrutalism.lime,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
            onPressed: () {
              final url = customUrlController.text.trim();
              if (url.isNotEmpty) {
                setState(() {
                  _avatarUrl = url;
                  _selectedAvatarIndex = null;
                });
              }
              Navigator.of(ctx).pop();
            },
            child: Text('Gunakan Foto', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Pinned Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2.0),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: NeoBrutalism.circleDecoration(
                        backgroundColor: Colors.white,
                        shadowOffset: 2,
                        borderWidth: 2,
                      ),
                      child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Profil',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Active Avatar Preview
                    Center(
                      child: Stack(
                        children: [
                          UserAvatar(
                            avatarUrl: _avatarUrl,
                            size: 88,
                            borderWidth: 2.5,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: NeoBrutalism.lime,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2.0),
                              ),
                              child: const Icon(Icons.check, size: 16, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Avatar Picker Section (6 Notion Avatars)
                    AvatarPickerSection(
                      selectedIndex: _selectedAvatarIndex,
                      onSelectPreset: (index) {
                        setState(() {
                          _selectedAvatarIndex = index;
                          _avatarUrl = UserProfile.notionAvatars[index - 1];
                        });
                      },
                      onCustomPhoto: _showCustomPhotoDialog,
                    ),
                    const SizedBox(height: 20),

                    // Field 1: Nama Lengkap
                    _buildInputField(
                      label: 'Nama Lengkap',
                      controller: _nameController,
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),

                    // Field 2: Email
                    _buildInputField(
                      label: 'Alamat Email',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Field 3: Nomor Telepon
                    _buildInputField(
                      label: 'Nomor Telepon',
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 28),

                    // Save Button
                    GestureDetector(
                      onTap: _saveProfile,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: NeoBrutalism.lime,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.black, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
