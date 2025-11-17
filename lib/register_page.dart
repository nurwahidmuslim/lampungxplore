import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  late final AnimationController _logoController;
  late final Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveLastRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_route', route);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // 1. Buat akun di Firebase Auth (email/password)
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Simpan data tambahan di Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
        );

        // Simpan last route = /login dan arahkan ke login
        await _saveLastRoute('/login');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException catch (e) {
      final message = e.message ?? 'Terjadi kesalahan saat registrasi.';
      _showErrorDialog('Auth error: $message');
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Sign up / Sign in using Google (jika user baru, simpan ke Firestore)
  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      // Jika butuh clientId khusus untuk web, gunakan GoogleSignIn(clientId: '...') saat kIsWeb
      final googleSignIn = kIsWeb
          ? GoogleSignIn(
              // Optional: jika kamu tidak memakai meta-tag di index.html,
              // masukkan clientId di sini: clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
            )
          : GoogleSignIn();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // user cancelled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Google dibatalkan')),
          );
        }
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // jika pengguna baru, simpan data ke Firestore
      final additional = userCredential.additionalUserInfo;
      if (additional != null && additional.isNewUser) {
        final user = userCredential.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'name': user.displayName ?? '',
                'email': user.email ?? '',
                'photoUrl': user.photoURL ?? '',
                'role': 'user',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masuk dengan Google berhasil!')),
        );

        await _saveLastRoute('/home');
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      final message = e.message ?? 'Gagal login dengan Google.';
      if (mounted) _showErrorDialog('Error: $message');
    } catch (e) {
      if (mounted) _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -60,
          left: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final radius = BorderRadius.circular(20.0);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _logoAnimation,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: const Icon(
                Icons.travel_explore,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Buat Akun - Lampung Xplore',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Name
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              prefixIcon: const Icon(Icons.person, color: Colors.white70),
              labelText: 'Nama',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Nama lengkap',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Email
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              prefixIcon: const Icon(Icons.email, color: Colors.white70),
              labelText: 'Email',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'contoh@domain.com',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
              final email = v.trim();
              final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!regex.hasMatch(email)) return 'Masukkan email yang valid';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: _passwordController,
            style: const TextStyle(color: Colors.white),
            obscureText: _obscure,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              prefixIcon: const Icon(Icons.lock, color: Colors.white70),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              labelText: 'Password',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Minimal 6 karakter',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              if (v.length < 6) return 'Minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Register button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade800,
                elevation: 6,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Daftar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Or divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.18))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('atau', style: TextStyle(color: Colors.white70)),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.18))),
            ],
          ),

          const SizedBox(height: 12),

          // Google button (only social option now)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialButton(
                icon: Icons.g_mobiledata,
                label: 'Daftar / Masuk dengan Google',
                onTap: _loading ? () {} : _signInWithGoogle,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Sudah punya akun?",
                style: TextStyle(color: Colors.white70),
              ),
              TextButton(
                onPressed: () async {
                  await _saveLastRoute('/login');
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 28,
                ),
                child: _buildCard(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
