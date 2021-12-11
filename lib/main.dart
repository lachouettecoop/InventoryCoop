
import 'package:flutter/material.dart';

import 'package:inventory_coop/login.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme(
        primary: Color(0xFF445448),
        primaryVariant: Color(0xff3700b3),
        secondary: Color(0xff03dac6),
        secondaryVariant: Color(0xff018786),
        surface: Colors.white,
        background: Colors.white,
        error: Color(0xffb00020),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onBackground: Colors.black,
        onError: Colors.white,
        brightness: Brightness.light,
      )
    ),
    home: LoginWidget(),
  ));
}