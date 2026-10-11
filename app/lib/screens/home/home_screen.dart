import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('LifeLink')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${user.name}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(height: 4),
            Text(
              user.isDonor
                  ? 'Donor in ${user.city}'
                  : 'Requester in ${user.city}',
              style: const TextStyle(color: kMuted),
            ),
          ],
        ),
      ),
    );
  }
}