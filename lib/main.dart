// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Halaman-app
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'favorit_page.dart';
import 'berita_page.dart';
import 'profil_page.dart';

// Admin & guard
import 'admin_page.dart';
import 'widgets/admin_gate.dart';

Future<void> connectToEmulators() async {
  // Hanya sambungkan ke emulator ketika running di web (localhost).
  if (!kIsWeb) return;

  const host = 'localhost';
  const firestorePort = 8080;
  const authPort = 9099;
  const functionsPort = 5001;

  // Firestore emulator
  FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);

  // Auth emulator
  FirebaseAuth.instance.useAuthEmulator(host, authPort);

  // Functions emulator
  FirebaseFunctions.instance.useFunctionsEmulator(host, functionsPort);

  // optional debug log
  // ignore: avoid_print
  print('Connected to Firebase emulators on $host');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Jika web (localhost), hubungkan ke emulator sebelum runApp.
  await connectToEmulators();

  // Ambil halaman terakhir (default ke /login)
  final prefs = await SharedPreferences.getInstance();
  final lastRoute = prefs.getString('last_route') ?? '/login';

  runApp(LampungXploreApp(initialRoute: lastRoute));
}

class LampungXploreApp extends StatelessWidget {
  final String initialRoute;
  const LampungXploreApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lampung Xplore',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Roboto'),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/favorit': (context) => const FavoritPage(),
        '/berita': (context) => const BeritaPage(),
        '/profil': (context) => const ProfilPage(),
        '/admin': (context) => const AdminGate(adminPage: AdminPage()),
      },

      // simpan route terakhir setiap kali pindah halaman
      navigatorObservers: [RouteObserverWithSave()],

      // Bungkus semua halaman dengan ResponsiveWrapper
      builder: (context, child) {
        return ResponsiveWrapper(child: child!);
      },
    );
  }
}

/// Observer untuk simpan route terakhir
class RouteObserverWithSave extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    _save(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null) _save(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _save(Route route) async {
    if (route.settings.name != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_route', route.settings.name!);
    }
  }
}

/// Wrapper supaya tampilan web tetap seperti mobile (max 480px)
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(color: Colors.white, child: child),
        ),
      ),
    );
  }
}
