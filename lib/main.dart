// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Halaman-app
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'favorit_page.dart';
// berita_page.dart dihapus karena kita mengganti tab Berita menjadi Upload iklan
import 'profil_page.dart';

// fitur upload iklan (ganti tab Berita)
import 'ad_create_page.dart';

// Admin & guard
import 'admin_page.dart';
import 'widgets/admin_gate.dart';

// Category page (generik untuk semua kategori)
import 'category_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase dengan pengecekan agar tidak terjadi duplicate-app
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Ambil halaman terakhir yang dibuka (default ke /login)
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
        // core pages
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/favorit': (context) => const FavoritPage(),
        // '/berita' dihapus — fitur Berita digantikan Upload iklan
        '/upload': (context) => const AdCreatePage(),
        '/profil': (context) => const ProfilPage(),
        '/admin': (context) => const AdminGate(adminPage: AdminPage()),

        // kategori routes — semua mengarah ke CategoryPage generik
        '/category/alam': (context) => const CategoryPage(
          categoryKey: 'alam',
          title: 'Alam',
          icon: Icons.park_outlined,
        ),
        '/category/religi': (context) => const CategoryPage(
          categoryKey: 'religi',
          title: 'Religi',
          icon: Icons.account_balance_outlined,
        ),
        '/category/pantai': (context) => const CategoryPage(
          categoryKey: 'pantai',
          title: 'Pantai',
          icon: Icons.beach_access_outlined,
        ),
        '/category/gunung': (context) => const CategoryPage(
          categoryKey: 'gunung',
          title: 'Gunung',
          icon: Icons.filter_hdr_outlined,
        ),
        '/category/budaya': (context) => const CategoryPage(
          categoryKey: 'budaya',
          title: 'Budaya',
          icon: Icons.museum_outlined,
        ),
        '/category/sejarah': (context) => const CategoryPage(
          categoryKey: 'sejarah',
          title: 'Sejarah',
          icon: Icons.landscape_outlined,
        ),
        '/category/kuliner': (context) => const CategoryPage(
          categoryKey: 'kuliner',
          title: 'Kuliner',
          icon: Icons.restaurant_outlined,
        ),
        '/category/penginapan': (context) => const CategoryPage(
          categoryKey: 'penginapan',
          title: 'Penginapan',
          icon: Icons.hotel_outlined,
        ),
      },

      // Simpan route terakhir
      navigatorObservers: [RouteObserverWithSave()],

      // Wrapper agar layout Web tetap seperti Mobile
      builder: (context, child) {
        return ResponsiveWrapper(child: child);
      },
    );
  }
}

/// Observer — menyimpan route terakhir ke SharedPreferences
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
    // hanya simpan jika route memiliki nama (named route)
    final name = route.settings.name;
    if (name == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_route', name);
    } catch (_) {
      // ignore storage errors (tidak mengganggu UX)
    }
  }
}

/// Agar tampilan web dibuat seperti mode mobile (max width 480px)
class ResponsiveWrapper extends StatelessWidget {
  final Widget? child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // jika child null (sangat jarang), tampilkan kosong agar tidak crash
    if (child == null) return const SizedBox.shrink();

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
