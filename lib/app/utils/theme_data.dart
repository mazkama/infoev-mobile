import 'package:flutter/material.dart';

final ThemeData appThemeData = ThemeData(
  primarySwatch: Colors.purple,
  brightness: Brightness.light,
  fontFamily: 'Poppins',
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w900,
      color: Colors.white,
      fontSize: 20,
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.purple[700],
    foregroundColor: Colors.white,
  ),
);
