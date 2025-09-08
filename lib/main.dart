import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'controllers/team_controller.dart';
import 'pages/home_page.dart';
import 'pages/select_page.dart';
import 'pages/team_preview_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();               
  Get.put(TeamController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pokémon Team Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      initialRoute: '/',
      getPages: [
        // ถ้า analyzer งอแง ให้เอา const ออกได้ (HomePage())
        GetPage(name: '/', page: () => const HomePage()),
        GetPage(name: '/select', page: () => const SelectPage()),
        GetPage(name: '/preview', page: () => const TeamPreviewPage()),
      ],
    );
  }
}
