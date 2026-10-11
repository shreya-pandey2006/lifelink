import 'package:flutter/material.dart';
const kPrimary = Color(0xFFD42A40);
const kPrimaryDark = Color(0xFFA50F2D); 
const kPrimarySoft = Color(0xFFFDE7EA); 
const kBackground = Color(0xFFFBF8FD); 
const kInk = Color(0xFF1B1B1F);
const kMuted = Color(0xFF6E6E78); 
const kAmber = Color(0xFFB7791F); 
const kAmberSoft = Color(0xFFFFE6C2);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kPrimary).copyWith(
    primary: kPrimary, onPrimary: Colors.white, surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme, scaffoldBackgroundColor: kBackground,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white, indicatorColor: kPrimarySoft, labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: states.contains(WidgetState.selected) ? kPrimaryDark : kMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData( color: states.contains(WidgetState.selected) ? kPrimaryDark : kMuted,
        ),
      ),
    ),
  );
}