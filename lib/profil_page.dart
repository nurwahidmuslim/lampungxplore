// profil_page_improved.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

// =========================================================================
// WIDGET SCREEN GANTI KATA SANDI 
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
// WIDGET SCREEN EDIT PROFIL 
// =========================================================================

class EditProfileScreen extends StatefulWidget {
  final User user;
  final String? initialAddress;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.initialAddress,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        String? photoURL = widget.user.photoURL;
        if (_selectedImage != null) {
          photoURL = await _uploadImage(_selectedImage!);
        }

        // Update Auth: Display Name & Photo URL
        await widget.user.updateDisplayName(_nameController.text);
        if (photoURL != null) {
          await widget.user.updatePhotoURL(photoURL);
        }

        // Update Email: Hanya beri pesan karena butuh re-auth
        if (_emailController.text != widget.user.email) {
          _showMessage('Untuk mengubah email, silakan hubungi support atau re-login.');
        }

        // Update Firestore: Address
        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
          'address': _addressController.text,
        }, SetOptions(merge: true));

        setState(() => _isLoading = false);
        widget.onProfileUpdated(); // Panggil callback untuk refresh ProfilPage
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    Color? color,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        validator: validator,
        style: TextStyle(fontSize: 16, color: color),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (widget.user.photoURL != null ? NetworkImage(widget.user.photoURL!) : null),
                      child: (_selectedImage == null && widget.user.photoURL == null)
                          ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),

              // Nama Pengguna
              _buildTextFormField(
                controller: _nameController,
                label: 'Nama Pengguna',
                icon: Icons.person_outline,
                validator: (value) => value?.isEmpty ?? true ? 'Nama tidak boleh kosong' : null,
              ),

              // Email (Read-only/Note)
              _buildTextFormField(
                controller: _emailController,
                label: 'Email (Tidak bisa diubah)',
                icon: Icons.email_outlined,
                readOnly: true,
                color: Colors.grey[500],
              ),
              
              // Alamat
              _buildTextFormField(
                controller: _addressController,
                label: 'Alamat',
                icon: Icons.location_on_outlined,
                validator: (value) => value?.isEmpty ?? true ? 'Alamat tidak boleh kosong' : null,
              ),

              const SizedBox(height: 30),

              // Tombol Simpan
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
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
                        'Simpan Perubahan',
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
// WIDGET SCREEN DETAIL AKUN 
// =========================================================================

class AccountDetailsScreen extends StatelessWidget {
  final User user;
  final String? address;

  const AccountDetailsScreen({
    super.key,
    required this.user,
    required this.address,
  });

  Widget _buildReadOnlyTextFormField({
    required String value,
    required String label,
    required IconData icon,
    String? helperText,
  }) {
    final controller = TextEditingController(text: value);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: true, // PENTING: Read Only
        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          suffixIcon: const Icon(Icons.lock, color: Colors.grey, size: 18), // Indikator Read-only
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200], // Warna latar belakang untuk Read-only
          helperText: helperText,
          helperStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = user.displayName ?? 'N/A';
    final email = user.email ?? 'N/A';
    final photo = user.photoURL;
    final joinDate = user.metadata.creationTime != null 
        ? 'Sejak ${user.metadata.creationTime!.day}/${user.metadata.creationTime!.month}/${user.metadata.creationTime!.year}'
        : 'Tidak diketahui';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Akun'),
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
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null
                  ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                  : null,
            ),
            
            const SizedBox(height: 10),
            Text(
              'Status Akun: Aktif',
              style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold),
            ),
            Text(
              joinDate,
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 30),

            // Nama Pengguna
            _buildReadOnlyTextFormField(
              value: username,
              label: 'Nama Pengguna',
              icon: Icons.person_outline,
              helperText: 'Nama yang terlihat oleh publik.',
            ),

            // Email
            _buildReadOnlyTextFormField(
              value: email,
              label: 'Email',
              icon: Icons.email_outlined,
              helperText: 'Digunakan untuk login dan notifikasi.',
            ),
            
            // Alamat
            _buildReadOnlyTextFormField(
              value: address ?? 'Belum ada alamat tersimpan',
              label: 'Alamat Tersimpan',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 30),

            // Keterangan
            Text(
              'Untuk mengubah detail ini, gunakan opsi "Edit Profil".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET SCREEN TENTANG APLIKASI (LAYAR PENUH)
// =========================================================================

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Wisata Lampung Xplore'), // Judul diubah
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
              'assets/images.jpg', // Ganti path sesuai struktur aset Anda
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
              'Wisata Lampung Xplore', // Nama aplikasi diubah
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
                'Informasi & Dukungan', // Judul diubah
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            const Divider(color: Colors.teal),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: Colors.teal),
              title: const Text('Email Dukungan'),
              subtitle: const Text('support@wisatalampungxplore.com'), // Email diubah
              onTap: () {}, // Tambahkan logika launch URL mailto: jika diperlukan
            ),
            
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code, color: Colors.teal),
              title: const Text('Pengembang'),
              subtitle: const Text('Tim Xplore Lampung'), // Pengembang diubah
              onTap: () {},
            ),

            const SizedBox(height: 50),
            Text(
              '© 2024 Wisata Lampung Xplore', // Hak cipta diubah
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}


// =========================================================================
// WIDGET SCREEN UTAMA: PROFIL PAGE
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
        });
      }
    }
  }
  
  // Callback untuk refresh ProfilPage setelah EditProfileScreen selesai
  void _refreshProfileData() {
    // Memuat ulang data dari Firebase setelah perubahan di layar Edit Profil
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
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
  
  // BARU: Method untuk menghapus akun pengguna (dipanggil setelah konfirmasi)
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
      // Peringatan: Operasi ini membutuhkan re-authentication baru-baru ini.
      await _user!.delete(); 

      if (!mounted) return;
      _showMessage('Akun berhasil dihapus. Sampai jumpa!');
      
      // Navigasi ke halaman login setelah berhasil dihapus
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

  // BARU: Method untuk menampilkan dialog konfirmasi penghapusan akun
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

    // Fungsi navigasi ke Ganti Kata Sandi
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
    
    // Fungsi navigasi ke Edit Profil
    final Function() navigateToEditProfile = () {
      if (_user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(
              user: _user!,
              initialAddress: _address,
              onProfileUpdated: _refreshProfileData,
            ),
          ),
        );
      } else {
        _showMessage('Anda harus login untuk mengedit profil.');
      }
    };

    // Fungsi navigasi ke Detail Akun
    final Function() navigateToAccountDetails = () {
      if (_user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountDetailsScreen(
              user: _user!,
              address: _address,
            ),
          ),
        );
      } else {
        _showMessage('Anda harus login untuk melihat detail akun.');
      }
    };
    
    // Fungsi navigasi ke Tentang Aplikasi (Full Screen)
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
        selectedItemColor: Colors.teal[700],
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
                  // Top App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          child: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.menu, color: Colors.grey[800]),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.explore,
                              color: Colors.teal[600],
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/profil'),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.purple[50],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.purple[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Profile Header with nicer styling
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.teal.shade600, Colors.teal.shade400],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 18,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 3,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white,
                              backgroundImage: photo != null
                                  ? NetworkImage(photo)
                                  : null,
                              child: photo == null
                                  ? Icon(
                                      Icons.person,
                                      size: 44,
                                      color: Colors.teal[600],
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // name + email + edit button
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_address != null && _address!.isNotEmpty)
                                  Text(
                                    _address!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: navigateToEditProfile, // MENGGUNAKAN FUNGSI BARU
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Edit Profil'),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.teal[700],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: navigateToChangePassword, // MENGGUNAKAN FUNGSI BARU
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text('Ganti Kata Sandi'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                            ListTile(
                              leading: const Icon(
                                Icons.person_outline,
                                color: Colors.teal,
                              ),
                              title: const Text('Detail Akun'),
                              subtitle: const Text('Lihat informasi akun anda'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: navigateToAccountDetails, // Navigasi ke layar Detail Akun
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.lock_outline,
                                color: Colors.orange,
                              ),
                              title: const Text('Ganti Kata Sandi'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: navigateToChangePassword, 
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              title: const Text('Hapus Akun'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _showConfirmDeleteAccountDialog, // <-- Memanggil dialog konfirmasi
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
                              onTap: navigateToAboutApp, // Navigasi ke layar Tentang Aplikasi
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