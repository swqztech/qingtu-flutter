import 'package:flutter/material.dart';

import 'screens/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QingtuApp());
}

class QingtuApp extends StatelessWidget {
  const QingtuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '轻图',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Microsoft YaHei UI',
      ),
      home: const QingtuHomePage(),
    );
  }
}
