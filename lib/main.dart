import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ambil halaman terakhir
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
        // '/home': (context) => const HomePage(),
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
