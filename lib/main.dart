import 'package:flutter/material.dart';
import 'package:inventory_coop/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xFF445448),
      ),
      home: LoginWidget(),
    );
  }
}
