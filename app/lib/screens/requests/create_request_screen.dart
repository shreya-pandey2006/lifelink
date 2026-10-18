import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/location_service.dart';
import '../../services/ml_service.dart';
import '../../widgets/location_card.dart';
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
  LatLng? _pin;
  bool _locating = false;
  bool _includePatient = false;
  final _patientAge = TextEditingController();
  final _patientWeight = TextEditingController();
  String _patientGender = 'Male';
  String _patientHealthIssue = 'Accident / Trauma';
  final _patientHemoglobin = TextEditingController();
  final _patientRequiredHours = TextEditingController(text: '4');
  bool _patientBleeding = true;
  final bool _patientTransfusions = false;
  bool _predictingUrgency = false;
  String? _predictedAiBadge;

  Future<void> _runAiPrediction() async {
    final ageVal = int.tryParse(_patientAge.text.trim());
    final weightVal =
        double.tryParse(_patientWeight.text.trim().replaceAll(',', '.'));
    final hbVal =
        double.tryParse(_patientHemoglobin.text.trim().replaceAll(',', '.'));
    final hrsVal = int.tryParse(_patientRequiredHours.text.trim());

    if (ageVal == null ||
        weightVal == null ||
        _bloodGroup == null ||
        _city == null) {
      _toast(
          'Please select blood group, city, age, and weight to run AI assessment.');
      return;
    }

    setState(() {
      _predictingUrgency = true;
      _predictedAiBadge = null;
    });

    final res = await MlService.instance.predictUrgency(
      age: ageVal,
      gender: _patientGender.toLowerCase(),
      weightKg: weightVal,
      bloodGroup: _bloodGroup!,
      city: _city!,
      healthIssue: _patientHealthIssue,
      hemoglobinGDl: hbVal,
      unitsRequired: _units,
      requiredWithinHours: hrsVal,
      activeBleeding: _patientBleeding,
      previousTransfusions: _patientTransfusions,
    );

    if (!mounted) return;
    setState(() => _predictingUrgency = false);

    if (res != null && res.predictedUrgency != null) {
      final p = res.predictedUrgency!.toLowerCase();
      setState(() {
        _predictedAiBadge = res.predictedUrgency!.toUpperCase();
        if (p == 'emergency') {
          _urgency = 3;
        } else if (p == 'urgent') {
          _urgency = 2;
        } else {
          _urgency = 1;
        }
      });
      _toast('AI assessed urgency: ${_predictedAiBadge!}');
    } else {
      _toast(
          'AI service unavailable right now. Urgency can be selected manually.');
    }
  }

  @override
  void initState() {
    super.initState();
    final userCity = context.read<AuthProvider>().user?.city;
    if (userCity != null && kCities.contains(userCity)) _city = userCity;
  }

  @override
  void dispose() {
    _hospital.dispose();
    _patientAge.dispose();
    _patientWeight.dispose();
    _patientHemoglobin.dispose();
    _patientRequiredHours.dispose();
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

  Future<void> _chooseOnMap() async {
    final result = await context.push<LatLng>(
      '/pick-location',
      extra: {'pin': _pin, 'city': _city},
    );
    if (result != null && mounted) setState(() => _pin = result);
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      final pos = await LocationService.currentPosition();
      if (mounted) setState(() => _pin = LatLng(pos.latitude, pos.longitude));
    } on LocationException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not read your location. Try again.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _groupError = _bloodGroup == null);
    if (!formOk || _bloodGroup == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    Map<String, dynamic>? patientData;
    if (_includePatient) {
      final ageVal = int.tryParse(_patientAge.text.trim());
      final weightVal =
          double.tryParse(_patientWeight.text.trim().replaceAll(',', '.'));
      final hbVal =
          double.tryParse(_patientHemoglobin.text.trim().replaceAll(',', '.'));
      final hrsVal = int.tryParse(_patientRequiredHours.text.trim());
      patientData = {
        'age': ?ageVal,
        'gender': _patientGender,
        'weightKg': ?weightVal,
        'healthIssue': _patientHealthIssue,
        'hemoglobinGDl': ?hbVal,
        'requiredWithinHours': ?hrsVal,
        'activeBleeding': _patientBleeding,
        'previousTransfusions': _patientTransfusions,
      };
    }

    try {
      final req = await context.read<RequestProvider>().create(
            bloodGroup: _bloodGroup!,
            units: _units,
            hospitalName: _hospital.text,
            city: _city!,
            urgency: _urgency,
            patient: patientData,
            lat: _pin?.latitude,
            lng: _pin?.longitude,
          );
      if (!mounted) return;
      final msg = req.predictedUrgency != null
          ? 'Request posted. AI predicted urgency: ${req.predictedUrgency}. Donors are being notified.'
          : 'Request posted. Matching donors are being alerted.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
        backgroundColor: kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Create Urgent Blood Request',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Form(
            key: _formKey,
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
                const SizedBox(height: 16),
                _patientCard(),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.red))
                ],
                const SizedBox(height: 22),
                PrimaryButton(
                    label: 'Submit Blood Request',
                    icon: Icons.campaign_outlined,
                    loading: _loading,
                    onPressed: _submit),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => context.pop(),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: kMuted, fontWeight: FontWeight.w700)),
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
      child: Column( crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Blood Group', style: TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
              Pill('REQUIRED'),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count( crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8,crossAxisSpacing: 8, childAspectRatio: 0.95,
            children: kBloodGroups.map((g) {
              final on = g == _bloodGroup;
              return GestureDetector(
                onTap: () => setState(() {
                  _bloodGroup = g;
                  _groupError = false;
                }),
                child: Container( decoration: BoxDecoration( color: on ? kPrimaryDark : const Color(0xFFF4F1F6), borderRadius: BorderRadius.circular(16) ),
                  child: Column( mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(g, style: TextStyle( fontSize: 20, fontWeight: FontWeight.w800, color: on ? Colors.white : kInk)),
                      const SizedBox(height: 2),
                      Text(_groupHints[g]!, textAlign: TextAlign.center, style: TextStyle( fontSize: 9, fontWeight: FontWeight.w600, color: on ? Colors.white70 : kMuted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container( padding: const EdgeInsets.all(12),
            decoration: BoxDecoration( color: const Color(0xFFF4F1F6), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: kPrimaryDark, size: 20), const SizedBox(width: 10),
                Expanded(
                  child: Text(_groupInfo, style: const TextStyle(fontSize: 12.5, color: kInk)),
                ),
              ],
            ),
          ),
          if (_groupError) ...[
            const SizedBox(height: 8),
             const Text('Select the blood group needed', style: TextStyle(color: Colors.red, fontSize: 12)),
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
                Text('Units Required', style: TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
                SizedBox(height: 2),
                Text('Standard whole blood bag (~450 ml)', style: TextStyle(fontSize: 12, color: kMuted)),
              ],
            ),
          ),
          Container( padding: const EdgeInsets.all(4),
            decoration: BoxDecoration( color: const Color(0xFFF1EEF3), borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                _RoundButton( icon: Icons.remove, filled: false, onTap: _units > 1 ? () => setState(() => _units--) : null),
                SizedBox( width: 38,
                  child: Center( child: Text('$_units', style: const TextStyle( fontSize: 20,  fontWeight: FontWeight.w800, color: kInk)) )),
                _RoundButton( icon: Icons.add, filled: true, onTap: _units < 10 ? () => setState(() => _units++) : null),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _urgencyCard() {
    return AppCard(
      child: Column( crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Urgency Level', style: TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
              Text('Emergency Dispatch', style: TextStyle( fontSize: 12, fontWeight: FontWeight.w700, color: kPrimaryDark)),
            ],
          ),
          const SizedBox(height: 12),
          for (final level in [1, 2, 3]) ...[
            _UrgencyTile( title: kUrgencyLabels[level]!, description: kUrgencyDescriptions[level]!, icon: _urgencyIcons[level]!, selected: _urgency == level,
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
      child: Column( crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_hospital_outlined, color: kPrimaryDark), SizedBox(width: 8),
              Text('Medical Facility & Destination', style: TextStyle( fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
            ],
          ),
          const SizedBox(height: 16), const FieldLabel('Hospital / Clinic Name'),
          TextFormField( controller: _hospital, decoration: fieldDecoration( hint: 'e.g. City Medical Emergency Pavilion', icon: Icons.business_outlined),
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
          const SizedBox(height: 16), const FieldLabel('Hospital Location (recommended)'),
          LocationCard( pin: _pin, busy: _locating, onChooseOnMap: _chooseOnMap, onUseGps: _useGps ),
        ],
      ),
    );
  }

  Widget _patientCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: kPrimaryDark),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('AI Urgency Assessment (Optional)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kInk)),
              ),
              Switch(
                value: _includePatient,
                onChanged: (v) => setState(() => _includePatient = v),
              ),
            ],
          ),
          if (_includePatient) ...[
            const SizedBox(height: 12),
            const Text(
              'Add patient clinical parameters to run the backend ML urgency prediction model.',
              style: TextStyle(fontSize: 12, color: kMuted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Patient Age'),
                      TextFormField(
                        controller: _patientAge,
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration(
                            hint: 'e.g. 34', icon: Icons.cake_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Weight (kg)'),
                      TextFormField(
                        controller: _patientWeight,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: fieldDecoration(
                            hint: 'e.g. 72.5',
                            icon: Icons.monitor_weight_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const FieldLabel('Patient Gender'),
            DropdownButtonFormField<String>(
              initialValue: _patientGender,
              decoration: fieldDecoration(icon: Icons.person_outline),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _patientGender = v ?? 'Male'),
            ),
            const SizedBox(height: 12),
            const FieldLabel('Primary Health Issue / Diagnosis'),
            DropdownButtonFormField<String>(
              initialValue: _patientHealthIssue,
              decoration: fieldDecoration(icon: Icons.medical_services_outlined),
              items: const [
                DropdownMenuItem(
                    value: 'Accident / Trauma',
                    child: Text('Accident / Trauma')),
                DropdownMenuItem(value: 'Surgery', child: Text('Surgery')),
                DropdownMenuItem(
                    value: 'Anemia / Dengue', child: Text('Anemia / Dengue')),
                DropdownMenuItem(
                    value: 'Cancer Care', child: Text('Cancer Care')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) =>
                  setState(() => _patientHealthIssue = v ?? 'Accident / Trauma'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Hemoglobin (g/dL)'),
                      TextFormField(
                        controller: _patientHemoglobin,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: fieldDecoration(
                            hint: 'e.g. 9.2', icon: Icons.water_drop_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Needed Within (Hours)'),
                      TextFormField(
                        controller: _patientRequiredHours,
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration(
                            hint: 'e.g. 4', icon: Icons.timer_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active bleeding present',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: _patientBleeding,
              onChanged: (v) => setState(() => _patientBleeding = v ?? false),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: _predictingUrgency
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kPrimary),
                      )
                    : const Icon(Icons.auto_awesome,
                        size: 18, color: kPrimary),
                label: Text(
                  _predictingUrgency
                      ? 'Analyzing with AI...'
                      : (_predictedAiBadge != null
                          ? 'AI Assessed: $_predictedAiBadge'
                          : 'Assess Urgency with AI'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: kPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kPrimary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _predictingUrgency ? null : _runAiPrediction,
              ),
            ),
          ],
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
        decoration: BoxDecoration( shape: BoxShape.circle, color: filled ? (enabled ? kPrimary : kPrimarySoft) : Colors.white),
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
            CircleAvatar( radius: 20, backgroundColor: selected ? kPrimaryDark : Colors.white,
              child: Icon(icon, size: 20, color: selected ? Colors.white : kMuted) ),
            const SizedBox(width: 12),
            Expanded(
              child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle( fontSize: 15, fontWeight: FontWeight.w800, color: selected ? kPrimaryDark : kInk)),
                  const SizedBox(height: 2), Text(description, style: const TextStyle(fontSize: 12, color: kMuted)),
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