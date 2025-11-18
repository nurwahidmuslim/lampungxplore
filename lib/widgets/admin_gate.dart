// lib/widgets/admin_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../login_page.dart';

class AdminGate extends StatelessWidget {
  final Widget adminPage; // instance AdminPage()

  const AdminGate({super.key, required this.adminPage});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) {
          // Belum login => tampilkan LoginPage
          return const LoginPage();
        }

        // Sudah login => cek role
        return FutureBuilder<String?>(
          future: AuthService.fetchRoleForUid(user.uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnap.data;
            if (role == 'admin') {
              // akses diizinkan
              return adminPage;
            }

            // bukan admin
            return Scaffold(
              appBar: AppBar(title: const Text('Akses Ditolak')),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Anda tidak memiliki izin untuk mengakses halaman ini.',
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                      child: const Text('Kembali ke Beranda'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
