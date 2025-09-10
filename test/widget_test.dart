import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampungxplore/main.dart';

void main() {
  testWidgets('LoginPage tampil dengan benar', (WidgetTester tester) async {
    // Build app dengan initialRoute /login
    await tester.pumpWidget(const LampungXploreApp(initialRoute: '/login'));

    // Cek judul ada
    expect(find.text('Lampung Xplore'), findsOneWidget);

    // Cek ada TextField Email
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);

    // Cek ada TextField Password
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

    // Cek ada tombol Login
    expect(find.text('Login'), findsOneWidget);
  });
}
