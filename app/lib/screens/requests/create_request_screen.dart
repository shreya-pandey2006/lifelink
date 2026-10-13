import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';
const _groupHints = {
  'A+': 'Eligible','A-': 'Rare', 'B+': 'Eligible', 'B-': 'Rare', 'AB+': 'Universal Rec.', 'AB-': 'Crit. Rare',  'O+': 'High Need', 'O-': 'Universal',
};

const _urgencyIcons = {1: Icons.schedule, 2: Icons.warning_amber_rounded, 3: Icons.emergency};

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});
  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}
class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hospital = TextEditingController();
  String? _bloodGroup;
  String? _city;
  int _units = 1;
  int _urgency = 2;
  bool _groupError = false;
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final userCity = context.read<AuthProvider>().user?.city;
    if (userCity != null && kCities.contains(userCity)) _city = userCity;
  }
  @override
  void dispose() {
    _hospital.dispose();
    super.dispose();
  }

  String get _groupInfo {
    final g = _bloodGroup;
    if (g == null) return 'Select the blood group the patient needs.';
    if (g == 'O-') {
      return 'O- (Universal Donor) can be safely transfused to any emergency recipient.';
    }
    return 'Compatible donor groups: ${donorsFor(g).join(', ')}';
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _groupError = _bloodGroup == null);
    if (!formOk || _bloodGroup == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<RequestProvider>().create(
            bloodGroup: _bloodGroup!,
            units: _units,
            hospitalName: _hospital.text,
            city: _city!,
            urgency: _urgency,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Request posted. Matching donors are being alerted.')));
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackground, surfaceTintColor: Colors.transparent,
        title: const Text('Create Urgent Blood Request',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Form( key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bloodGroupCard(),
                const SizedBox(height: 16),
                _unitsCard(),
                const SizedBox(height: 16),
                _urgencyCard(),
                const SizedBox(height: 16),
                _facilityCard(),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 22),
                PrimaryButton( label: 'Submit Blood Request', icon: Icons.campaign_outlined, loading: _loading, onPressed: _submit ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => context.pop(),
                    child: const Text('Cancel',
                        style: TextStyle( color: kMuted, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bloodGroupCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Blood Group',
                  style: TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
              Pill('REQUIRED'),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8,crossAxisSpacing: 8, childAspectRatio: 0.95,
            children: kBloodGroups.map((g) {
              final on = g == _bloodGroup;
              return GestureDetector(
                onTap: () => setState(() {
                  _bloodGroup = g;
                  _groupError = false;
                }),
                child: Container(
                  decoration: BoxDecoration( color: on ? kPrimaryDark : const Color(0xFFF4F1F6), borderRadius: BorderRadius.circular(16) ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(g,
                          style: TextStyle( fontSize: 20, fontWeight: FontWeight.w800, color: on ? Colors.white : kInk)),
                      const SizedBox(height: 2),
                      Text(_groupHints[g]!, textAlign: TextAlign.center,
                          style: TextStyle( fontSize: 9, fontWeight: FontWeight.w600, color: on ? Colors.white70 : kMuted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF4F1F6), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: kPrimaryDark, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_groupInfo,
                      style: const TextStyle(fontSize: 12.5, color: kInk)),
                ),
              ],
            ),
          ),
          if (_groupError) ...[
            const SizedBox(height: 8),
            const Text('Select the blood group needed',
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
    );
  }
  Widget _unitsCard() {
    return AppCard(
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Units Required',
                    style: TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
                SizedBox(height: 2),
                Text('Standard whole blood bag (~450 ml)',
                    style: TextStyle(fontSize: 12, color: kMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: const Color(0xFFF1EEF3),
                borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                _RoundButton(
                  icon: Icons.remove, filled: false,
                  onTap: _units > 1 ? () => setState(() => _units--) : null,
                ),
                SizedBox( width: 38,
                  child: Center(
                    child: Text('$_units',
                        style: const TextStyle(
                            fontSize: 20,  fontWeight: FontWeight.w800, color: kInk)),
                  ),
                ),
                _RoundButton(
                  icon: Icons.add, filled: true,
                  onTap: _units < 10 ? () => setState(() => _units++) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _urgencyCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Urgency Level',
                  style: TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
              Text('Emergency Dispatch',
                  style: TextStyle( fontSize: 12, fontWeight: FontWeight.w700, color: kPrimaryDark)),
            ],
          ),
          const SizedBox(height: 12),
          for (final level in [1, 2, 3]) ...[
            _UrgencyTile(
              title: kUrgencyLabels[level]!, description: kUrgencyDescriptions[level]!, icon: _urgencyIcons[level]!, selected: _urgency == level,
              onTap: () => setState(() => _urgency = level),
            ),
            if (level != 3) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
  Widget _facilityCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_hospital_outlined, color: kPrimaryDark), SizedBox(width: 8),
              Text('Medical Facility & Destination',
                  style: TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
            ],
          ),
          const SizedBox(height: 16),
          const FieldLabel('Hospital / Clinic Name'),
          TextFormField(
            controller: _hospital, decoration: fieldDecoration(
                hint: 'e.g. City Medical Emergency Pavilion', icon: Icons.business_outlined),
            validator: (v) => (v == null || v.trim().isEmpty)  ? 'Enter the hospital name' : null,
          ),
          const SizedBox(height: 16), const FieldLabel('City'),
          DropdownButtonFormField<String>(
            initialValue: _city, decoration: fieldDecoration(
                hint: 'Select the city', icon: Icons.location_city_outlined),
            items: kCities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _city = v), validator: (v) => v == null ? 'Select a city' : null,
          ),
        ],
      ),
    );
  }
}
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;
  const _RoundButton({required this.icon, required this.filled, this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container( width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: filled ? (enabled ? kPrimary : kPrimarySoft) : Colors.white),
        child: Icon(icon, size: 20, color: filled ? Colors.white : (enabled ? kInk : const Color(0xFFBDBAC2))),
      ),
    );
  }
}

class _UrgencyTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _UrgencyTile({ required this.title, required this.description, required this.icon, required this.selected, required this.onTap });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14), decoration: BoxDecoration(
          color: selected ? kPrimarySoft : const Color(0xFFF4F1F6), borderRadius: BorderRadius.circular(18), border: Border.all( color: selected ? kPrimaryDark : Colors.transparent, width: 1.5) ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20, backgroundColor: selected ? kPrimaryDark : Colors.white,
              child: Icon(icon, size: 20, color: selected ? Colors.white : kMuted) ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle( fontSize: 15, fontWeight: FontWeight.w800, color: selected ? kPrimaryDark : kInk)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? kPrimaryDark : const Color(0xFFBDBAC2)),
          ],
        ),
      ),
    );
  }
}