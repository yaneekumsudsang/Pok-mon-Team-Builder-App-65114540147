// lib/main.dart
import 'package:flutter/material.dart';
import 'home.dart'; // <-- ถ้าไฟล์อยู่ lib/pages/home.dart ให้เปลี่ยนเป็น: import 'pages/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DSSI Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      home: const HomePage(), // หน้า Home ที่คุณส่งมา
    );
  }
}
