import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                const BrandLogo(size: 46),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LifeLink',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: kPrimaryDark)),
                      Text('HOME DASHBOARD',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                              color: kMuted)),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: kPrimarySoft,
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: kPrimaryDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Hello, ${user.name}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(height: 14),
            if (user.isDonor)
              AppCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: kPrimarySoft,
                      child: Icon(Icons.volunteer_activism_outlined,
                          color: kPrimaryDark),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('You are ready to help',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                              'Urgent requests in ${user.city} will appear in your Requests tab.',
                              style: const TextStyle(
                                  fontSize: 13, color: kMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const _UrgentBanner(),
            // Day 4: stats, priority dispatches and the compatibility check.
          ],
        ),
      ),
    );
  }
}

class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD42A40), Color(0xFFA50F2D)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x33A50F2D), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Pill('INSTANT MEDICAL BROADCAST',
              background: Colors.white24, foreground: Colors.white),
          const SizedBox(height: 14),
          const Text('Need Blood Urgently?',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 6),
          const Text(
            'Broadcast a request to matching donors in your city, within a minute.',
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => context.push('/request/new'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kPrimaryDark,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.add_circle),
              label: const Text('Create Urgent Request',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}