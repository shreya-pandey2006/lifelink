import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/ui.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(size: 96),
            SizedBox(height: 16),
            Text('LifeLink',
                style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800, color: kInk)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: kPrimary),
          ],
        ),
      ),
    );
  }
}