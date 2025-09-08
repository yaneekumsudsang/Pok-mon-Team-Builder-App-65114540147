import 'package:flutter/material.dart';
import 'package:myapp/page/select.dart';
import 'package:myapp/page/home.dart';
import 'package:myapp/page/detail.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // ✅ กำหนดหน้าแรก
      initialRoute: '/',
      routes: {
        '/': (context) => const SelectPage(),   // หน้าแรก
        '/home': (context) => const MyHomePage(title: 'Flutter Demo Home Page'),
        '/detail': (context) => const Detail(),
      },
    );
  }
}
