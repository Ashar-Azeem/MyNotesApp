import 'package:flutter/material.dart';

const MaterialColor primary = MaterialColor(_primaryPrimaryValue, <int, Color>{
  50: Color(0xFFF2F0F8),
  100: Color(0xFFDFDAEC),
  200: Color(0xFFCAC1E0),
  300: Color(0xFFB5A8D4),
  400: Color(0xFFA596CA),
  500: Color(_primaryPrimaryValue),
  600: Color(0xFF8D7BBB),
  700: Color(0xFF8270B3),
  800: Color(0xFF7866AB),
  900: Color(0xFF67539E),
});
const int _primaryPrimaryValue = 0xFF9583C1;

const MaterialColor primaryAccent =
    MaterialColor(_primaryAccentValue, <int, Color>{
  100: Color(0xFFFFFFFF),
  200: Color(_primaryAccentValue),
  400: Color(0xFFB59CFF),
  700: Color(0xFFA282FF),
});
const int _primaryAccentValue = 0xFFDBCFFF;
