import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
                leading: const Icon(Icons.person), title: Text(user.name),
                subtitle: Text(user.role)),
            ListTile(leading: const Icon(Icons.email), title: Text(user.email)),
            ListTile(leading: const Icon(Icons.phone), title: Text(user.phone)),
            ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(user.city)),
            if (user.bloodGroup != null)
              ListTile(
                  leading: const Icon(Icons.bloodtype), title: Text('Blood group ${user.bloodGroup}')),
            const Spacer(),
            PrimaryButton(
              label: 'Log Out of LifeLink', icon: Icons.logout,
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
        ),
      ),
    );
  }
}