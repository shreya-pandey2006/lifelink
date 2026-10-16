import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final donor = context.watch<DonorProvider>();
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: kBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: kPrimarySoft,
                      child: Text(
                        user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kPrimaryDark),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kInk),
                          ),
                          const SizedBox(height: 2),
                          Pill(user.role.toUpperCase(),
                              background: kPrimarySoft, foreground: kPrimaryDark),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEDE7EA)),
                const SizedBox(height: 12),
                _infoRow(Icons.email_outlined, 'Email', user.email),
                _infoRow(Icons.phone_outlined, 'Phone', user.phone.isEmpty ? 'Not set' : user.phone),
                _infoRow(Icons.location_city_outlined, 'City', user.city),
                if (user.bloodGroup != null)
                  _infoRow(Icons.bloodtype_outlined, 'Blood Group', user.bloodGroup!),
              ],
            ),
          ),
          if (user.isDonor) ...[
            const SizedBox(height: 20),
            _SectionTitle('ML HEALTH PROFILE', trailing: 'Edit', onTrailingTap: () {
              _showMlDetailsDialog(context, donor);
            }),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      _metricTile('Age', donor.age != null ? '${donor.age} yrs' : 'Not set'),
                      _metricTile('Weight', donor.weightKg != null ? '${donor.weightKg} kg' : 'Not set'),
                      _metricTile('Hemoglobin', donor.hemoglobinGDl != null ? '${donor.hemoglobinGDl} g/dL' : 'Not set'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEDE7EA)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Donations Recorded', style: TextStyle(fontSize: 13, color: kMuted)),
                      Text('${donor.totalDonations}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kInk)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle('MY RESPONSES', trailing: 'View', onTrailingTap: () {
              _showMyResponsesSheet(context);
            }),
            const SizedBox(height: 8),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_outlined, color: kPrimaryDark),
                title: const Text('Donation Response History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('View blood requests you accepted or declined', style: TextStyle(fontSize: 12, color: kMuted)),
                trailing: const Icon(Icons.chevron_right, color: kMuted),
                onTap: () => _showMyResponsesSheet(context),
              ),
            ),
          ],
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Log Out of LifeLink',
            icon: Icons.logout,
            onPressed: () {
              context.read<RequestProvider>().clear();
              context.read<AlertProvider>().clear();
              context.read<DonorProvider>().clear();
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kMuted),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: kMuted)),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk))),
        ],
      ),
    );
  }

  static Widget _metricTile(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kInk)),
        ],
      ),
    );
  }

  static void _showMlDetailsDialog(BuildContext context, DonorProvider donor) {
    final ageController = TextEditingController(text: donor.age?.toString() ?? '');
    final weightController = TextEditingController(text: donor.weightKg?.toString() ?? '');
    final hemoController = TextEditingController(text: donor.hemoglobinGDl?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Donor ML Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age (18 - 100)'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 18 || n > 100) return 'Must be between 18 and 100';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid weight in kg';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: hemoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Hemoglobin (g/dL)'),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid hemoglobin level';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final age = int.parse(ageController.text.trim());
              final weight = double.parse(weightController.text.trim());
              final hemo = double.parse(hemoController.text.trim());
              final error = await donor.saveMlDetails(age: age, weightKg: weight, hemoglobinGDl: hemo);
              if (ctx.mounted) Navigator.pop(ctx);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ML details updated!')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static void _showMyResponsesSheet(BuildContext context) {
    context.read<DonorProvider>().loadMyResponses();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _MyResponsesSheet(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  const _SectionTitle(this.title, {this.trailing, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: kMuted)),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(trailing!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kPrimaryDark)),
          ),
      ],
    );
  }
}

class _MyResponsesSheet extends StatelessWidget {
  const _MyResponsesSheet();

  @override
  Widget build(BuildContext context) {
    final donor = context.watch<DonorProvider>();
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDFDAE0), borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Text('My Request Responses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
          const SizedBox(height: 4),
          const Text('History of requests you accepted or declined', style: TextStyle(fontSize: 13, color: kMuted)),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEDE7EA)),
          const SizedBox(height: 12),
          Expanded(
            child: donor.loadingResponses
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : donor.myResponses.isEmpty
                    ? const Center(child: Text('No request responses recorded yet.', style: TextStyle(color: kMuted)))
                    : ListView.separated(
                        itemCount: donor.myResponses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final r = donor.myResponses[i];
                          return AppCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: r.isAccepted ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                  child: Icon(
                                    r.isAccepted ? Icons.check : Icons.close,
                                    color: r.isAccepted ? const Color(0xFF2E7D32) : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('${r.bloodGroup} • ${r.units} units', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                          const Spacer(),
                                          Pill(
                                            r.status.toUpperCase(),
                                            background: r.isAccepted ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                            foreground: r.isAccepted ? const Color(0xFF2E7D32) : Colors.red,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text('${r.city} • Request: ${r.requestStatus}', style: const TextStyle(fontSize: 12, color: kMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
