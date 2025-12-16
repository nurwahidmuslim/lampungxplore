import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:intl/intl.dart'; 

// =========================================================================
// WIDGET SCREEN GANTI KATA SANDI (TIDAK BERUBAH)
// =========================================================================

class ChangePasswordScreen extends StatefulWidget {
  final User user;

  const ChangePasswordScreen({super.key, required this.user});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // 1. Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: widget.user.email!,
          password: _currentPasswordController.text,
        );
        await widget.user.reauthenticateWithCredential(credential);

        // 2. Update password
        await widget.user.updatePassword(_newPasswordController.text);

        if (mounted) {
          _showMessage(context, 'Kata sandi berhasil diubah');
          Navigator.pop(context); // Kembali ke halaman sebelumnya (ProfilPage)
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Gagal mengubah kata sandi.';
        if (e.code == 'wrong-password') {
          message = 'Kata Sandi Lama salah.';
        } else if (e.code == 'user-disabled') {
          message = 'Akun pengguna dinonaktifkan.';
        }
        if (mounted) {
          _showMessage(context, message);
        }
      } catch (e) {
        if (mounted) {
          _showMessage(context, 'Terjadi kesalahan: $e');
        }
      }
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    // Implementasi Field Kata Sandi Sesuai Desain Screenshot
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: label,
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: toggleVisibility,
            color: Colors.deepPurple,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          helperText: helperText,
          helperStyle: const TextStyle(color: Colors.grey),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Kata Sandi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pastikan kata sandi baru aman dan mudah diingat.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Sandi Lama
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Sandi Lama',
                isVisible: _isCurrentPasswordVisible,
                toggleVisibility: () {
                  setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible);
                },
                validator: (value) => value?.isEmpty ?? true ? 'Sandi lama tidak boleh kosong' : null,
              ),

              // Sandi Baru
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'Sandi Baru',
                isVisible: _isNewPasswordVisible,
                toggleVisibility: () {
                  setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
                },
                helperText: 'Minimal 6 karakter & kombinasi huruf dan angka',
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Sandi baru tidak boleh kosong';
                  if (value!.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),

              // Konfirmasi Sandi Baru
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Konfirmasi Sandi Baru',
                isVisible: _isConfirmPasswordVisible,
                toggleVisibility: () {
                  setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                },
                validator: (value) {
                  if (value != _newPasswordController.text) return 'Konfirmasi kata sandi tidak cocok';
                  return null;
                },
              ),
              
              const SizedBox(height: 30),

              // Tombol Utama Ubah Kata Sandi
              ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Ubah Kata Sandi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET SCREEN EDIT PROFIL (TIDAK BERUBAH)
// =========================================================================

class EditProfileScreen extends StatefulWidget {
  final User user;
  final String? initialAddress;
  final String? initialPhoneNumber; 
  final String? initialBirthDate;   
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.initialAddress,
    required this.onProfileUpdated,
    this.initialPhoneNumber, 
    this.initialBirthDate,   
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController; 
  late TextEditingController _emailController;
  
  DateTime? _selectedBirthDate; 
  File? _selectedImage;
  bool _isLoading = false;
  final _originalEmail = FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhoneNumber ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');
    
    // Inisialisasi Tanggal Lahir dari string ISO (jika ada)
    if (widget.initialBirthDate != null && widget.initialBirthDate!.isNotEmpty) {
      try {
        _selectedBirthDate = DateTime.parse(widget.initialBirthDate!);
      } catch (e) {
        // Fallback jika parsing tanggal gagal
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_pics/${widget.user.uid}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      _showMessage('Gagal upload foto: $e');
      return null;
    }
  }

  // BARU: Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2004, 8, 17), 
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF00bcd4), 
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00bcd4), 
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        String? photoURL = widget.user.photoURL;
        if (_selectedImage != null) {
          photoURL = await _uploadImage(_selectedImage!);
        }

        // 1. Update Auth: Display Name & Photo URL
        await widget.user.updateDisplayName(_nameController.text);
        if (photoURL != null) {
          await widget.user.updatePhotoURL(photoURL);
        }

        // 2. Handle Email Change (Warning/Re-authentication required)
        if (_emailController.text != _originalEmail) {
           // Jika email diubah, pengguna harus re-authenticate (untuk keamanan, kita hanya beri pesan)
           _showMessage('Perubahan email akan diproses setelah Anda login kembali dan mengonfirmasi.');
           // Note: Proses updateEmail() dilewatkan di sini karena memerlukan re-auth
        }

        // 3. Update Firestore: Phone, Birth Date
        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
          'phoneNumber': _phoneController.text, // Simpan No. Telepon
          'birthDate': _selectedBirthDate?.toIso8601String() ?? '', // Simpan Tanggal Lahir (ISO string)
        }, SetOptions(merge: true));

        setState(() => _isLoading = false);
        widget.onProfileUpdated(); 
        if (mounted) {
           Navigator.pop(context);
           _showMessage('Profil berhasil diperbarui');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showMessage('Gagal memperbarui profil: $e');
      }
    }
  }

  // BARU: Widget untuk field input bergaya custom (sesuai gambar)
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label, // Label di dalam field
          labelStyle: TextStyle(
            color: Colors.grey[700], 
            fontWeight: FontWeight.normal
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), 
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none, // Menghilangkan border
          ),
          filled: true,
          fillColor: Colors.transparent, 
        ),
      ),
    );
  }

  // BARU: Widget untuk field Tanggal Lahir (Date Picker)
  Widget _buildDateField({required BuildContext context}) {
    final String formattedDate = _selectedBirthDate != null
        ? DateFormat('dd MMM yyyy').format(_selectedBirthDate!)
        : 'Pilih Tanggal'; // Teks placeholder

    return GestureDetector(
      onTap: _isLoading ? null : () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        margin: const EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              // Tampilkan label Tanggal Lahir jika belum memilih
              _selectedBirthDate == null ? 'Tanggal Lahir' : formattedDate,
              style: TextStyle(
                fontSize: 16, 
                color: _selectedBirthDate != null ? Colors.black87 : Colors.grey[700],
                fontWeight: FontWeight.w600
              ),
            ),
            Icon(
              Icons.calendar_today, 
              size: 20, 
              color: Colors.grey[500]
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Penyesuaian agar Avatar tidak terpotong (Mengurangi Offset)
    const double avatarRadius = 50.0;
    const double overlapHeight = 80.0; // Seberapa dalam avatar masuk ke header (lebih kecil dari sebelumnya)
    const double topBarHeight = 50.0; 
    final double avatarOffset = avatarRadius + (topBarHeight - overlapHeight) - topBarHeight;

    return Scaffold(
      // Header BARU dengan warna dan layout yang minimalis
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0), // Tinggi AppBar disesuaikan
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00bcd4), // Biru Cyan
                Color(0xFF00e5ff), // Biru Muda
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Edit Profil', // Teks di samping tombol kembali
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: false, // Memastikan judul berada di kiri
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        // Padding disesuaikan
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 0), 
        child: Column(
          children: [
            // Avatar (Ditarik ke atas agar tampak tumpang tindih)
            Transform.translate(
              offset: Offset(0, -avatarOffset), // Geser avatar ke atas
              child: Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: avatarRadius, // 50.0
                        backgroundColor: Colors.white,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (widget.user.photoURL != null ? NetworkImage(widget.user.photoURL!) : null),
                        child: (_selectedImage == null && widget.user.photoURL == null)
                            ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 1.5),
                          ),
                          child: const Icon(Icons.edit, color: Colors.blue, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
   Form(
 key: _formKey,
 child: Column(
   crossAxisAlignment: CrossAxisAlignment.stretch,
   children: [
     // Jarak penyesuaian setelah avatar
     Transform.translate(
       offset: Offset(0, -avatarOffset - 10), // Geser form ke atas agar menempel dengan avatar
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           
           // --- TAMBAHKAN INI (SizedBox) ---
           // Ubah angka 30.0 menjadi lebih besar jika ingin lebih ke bawah lagi
           const SizedBox(height: 50.0), 
           // --------------------------------

           // Username (Dapat diedit)
           _buildCustomTextField(
             controller: _nameController,
             label: 'Username',
             validator: (value) => value?.isEmpty ?? true ? 'Username tidak boleh kosong' : null,
           ),
           
           // ... widget lainnya (No Telepon, dll) ...
                        // No. Telepon
                        _buildCustomTextField(
                          controller: _phoneController,
                          label: 'No. Telepon',
                          keyboardType: TextInputType.phone,
                          validator: (value) => value?.isEmpty ?? true ? 'Nomor telepon tidak boleh kosong' : null,
                        ),

                        // Email (Dapat diedit, tetapi dengan peringatan saat save)
                        _buildCustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          readOnly: false, 
                        ),
                        
                        // Tanggal Lahir
                        _buildDateField(context: context),

                        // Tombol Simpan
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6f42c1), // Warna ungu gelap
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 25,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET SCREEN TENTANG APLIKASI (TIDAK BERUBAH)
// =========================================================================

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Wisata Lampung Xplore'), 
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo Aplikasi (Mengganti Icon dengan Image.asset)
            Image.asset(
              'assets/images.jpg', 
              width: 120, 
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                // Fallback jika gambar asset tidak ditemukan
                return Icon(
                  Icons.explore_outlined,
                  size: 80,
                  color: Colors.teal,
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Wisata Lampung Xplore', 
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versi 1.0.0',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            
            // Deskripsi diubah
            const Text(
              'Wisata Lampung Xplore adalah panduan interaktif Anda untuk menjelajahi '
              'keindahan tersembunyi dan destinasi populer di Lampung. Temukan tempat wisata '
              'alam, budaya, kuliner, dan aktivitas menarik lainnya. Aplikasi ini membantu Anda '
              'merencanakan perjalanan, melihat ulasan, dan berbagi pengalaman wisata Anda.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 40),

            // Informasi Kontak
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Informasi & Dukungan', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            const Divider(color: Colors.teal),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: Colors.teal),
              title: const Text('Email Dukungan'),
              subtitle: const Text('support@wisatalampungxplore.com'), 
              onTap: () {}, // Tambahkan logika launch URL mailto: jika diperlukan
            ),
            
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code, color: Colors.teal),
              title: const Text('Pengembang'),
              subtitle: const Text('Tim Xplore Lampung'), 
              onTap: () {},
            ),

            const SizedBox(height: 50),
            Text(
              '© 2024 Wisata Lampung Xplore', 
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}


// =========================================================================
// WIDGET SCREEN UTAMA: PROFIL PAGE (SUDAH DIPERBARUI - ATAS KOSONG)
// =========================================================================

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  static const double _maxWidth = 520;
  int _currentIndex = 3;
  User? _user;
  String? _address;
  // Variabel untuk data tambahan
  String? _phoneNumber;
  String? _birthDate;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        setState(() {
          _address = doc.data()?['address'] ?? '';
          _phoneNumber = doc.data()?['phoneNumber'] ?? ''; 
          _birthDate = doc.data()?['birthDate'] ?? '';     
        });
      }
    }
  }
  
  // Callback untuk refresh ProfilPage setelah EditProfileScreen selesai
  void _refreshProfileData() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
    _loadUserData();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/upload'); 
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/favorit');
        break;
      case 3:
        // already on profil
        break;
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
  
  Future<void> _deleteAccount() async {
    if (_user == null) return;
    
    // 1. Hapus data pengguna di Firestore terlebih dahulu
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).delete();
      _showMessage('Data pengguna di Firestore berhasil dihapus.');
    } catch (e) {
      _showMessage('Gagal menghapus data di Firestore: $e');
    }

    // 2. Hapus akun di Firebase Authentication
    try {
      await _user!.delete(); 

      if (!mounted) return;
      _showMessage('Akun berhasil dihapus. Sampai jumpa!');
      
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showMessage('Gagal menghapus akun: Silakan logout dan login kembali untuk mengonfirmasi tindakan.');
      } else {
        _showMessage('Gagal menghapus akun: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Terjadi kesalahan saat menghapus akun: $e');
      }
    }
  }

  void _showConfirmDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Akun', style: TextStyle(color: Colors.red)),
        content: const Text(
          'Apakah Anda yakin ingin menghapus akun Anda secara permanen? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus Permanen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = _user?.displayName ?? 'Pengguna';
    final email = _user?.email ?? 'Belum ada email';
    final photo = _user?.photoURL;

    final Function() navigateToChangePassword = () {
      if (_user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(user: _user!),
          ),
        );
      } else {
        _showMessage('Anda harus login untuk mengganti kata sandi.');
      }
    };
    
    final Function() navigateToEditProfile = () {
      if (_user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(
              user: _user!,
              initialAddress: _address,
              initialPhoneNumber: _phoneNumber, 
              initialBirthDate: _birthDate,     
              onProfileUpdated: _refreshProfileData,
            ),
          ),
        );
      } else {
        _showMessage('Anda harus login untuk mengedit profil.');
      }
    };

    final Function() navigateToAboutApp = () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AboutAppScreen(),
        ),
      );
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade400,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload_outlined), 
            activeIcon: Icon(Icons.cloud_upload), 
            label: "Upload", 
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: "Favorit",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- BAGIAN TOP APP BAR DIHAPUS TOTAL ---
                  // Area ini sekarang kosong, sehingga Profile Header naik ke atas.

                  // Profile Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF8e6fe8), 
                            Color(0xFF6f42c1) 
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 30, 
                        horizontal: 18,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar + Edit Icon
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                backgroundImage: photo != null
                                    ? NetworkImage(photo)
                                    : null,
                                child: photo == null
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey[600],
                                      )
                                    : null,
                              ),
                              // Ikon Edit di sebelah kanan avatar
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: navigateToEditProfile, 
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF6f42c1), width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: Color(0xFF6f42c1),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Name
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Email
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Option groups
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildCard(
                          title: 'Akun',
                          children: [
                            // EDIT PROFILE
                            ListTile(
                              leading: const Icon(
                                Icons.edit, 
                                color: Colors.teal,
                              ),
                              title: const Text('Edit Profile'), 
                              trailing: const Icon(Icons.chevron_right),
                              onTap: navigateToEditProfile, 
                            ),
                            const Divider(height: 1),
                            // GANTI KATA SANDI
                            ListTile(
                              leading: const Icon(
                                Icons.lock_open_outlined, 
                                color: Colors.orange,
                              ),
                              title: const Text('Ganti Kata Sandi'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: navigateToChangePassword, 
                            ),
                            const Divider(height: 1),
                            // HAPUS AKUN
                            ListTile(
                              leading: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              title: const Text('Hapus Akun'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _showConfirmDeleteAccountDialog, 
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _buildCard(
                          title: 'Lainnya',
                          children: [
                            ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text('Tentang Aplikasi'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: navigateToAboutApp, 
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.star_border),
                              title: const Text('Beri Rating'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showMessage('Beri Rating'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                              ),
                              title: const Text('Keluar'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _confirmLogout,
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // small footer
                        Text(
                          'Versi aplikasi 1.0.0',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 0),
          ...children,
        ],
      ),
    );
  }
}