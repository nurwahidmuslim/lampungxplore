import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LampungXploreApp());
}

class LampungXploreApp extends StatelessWidget {
  const LampungXploreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lampung Xplore',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Roboto'),
      ),
      home: const LoginPage(),

      // Bungkus semua halaman dengan ResponsiveWrapper
      builder: (context, child) {
        return ResponsiveWrapper(child: child!);
      },
    );
  }
}

/// Wrapper supaya tampilan web tetap seperti mobile (max 480px)
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // warna whitespace kanan kiri
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(color: Colors.white, child: child),
        ),
      ),
    );
  }
}
