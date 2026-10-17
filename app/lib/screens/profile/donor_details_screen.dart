import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/ui.dart';
class DonorDetailsScreen extends StatefulWidget {
  const DonorDetailsScreen({super.key});
  @override
  State<DonorDetailsScreen> createState() => _DonorDetailsScreenState();
}
class _DonorDetailsScreenState extends State<DonorDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _hemoglobin = TextEditingController();
  final _days = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final donor = context.read<DonorProvider>();
      if (!donor.loaded) await donor.load();
      if (!mounted) return;
      _age.text = donor.age?.toString() ?? '';
      _weight.text = donor.weight?.toString() ?? '';
      _hemoglobin.text = donor.hemoglobin?.toString() ?? '';
      _days.text = donor.daysSinceLastDonation?.toString() ?? '';
    });
  }
  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _hemoglobin.dispose();
    _days.dispose();
    super.dispose();
  }
  String? _number(String? v, double min, double max, String label) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Enter a number';
    if (n < min || n > max) return '$label must be between $min and $max';
    return null;
  }
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<DonorProvider>().saveHealth(
          age: int.parse(_age.text.trim()),
          weight: double.parse(_weight.text.trim().replaceAll(',', '.')),
          hemoglobin: double.parse(_hemoglobin.text.trim().replaceAll(',', '.')),
          daysSinceLastDonation: int.parse(_days.text.trim()),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Health details saved.')));
      context.pop();
    } else {
      setState(() => _error = error);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( backgroundColor: kBackground, surfaceTintColor: Colors.transparent,
        title: const Text('Donor Health Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
         child: SingleChildScrollView( padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Form( key: _formKey,
            child: Column( crossAxisAlignment: CrossAxisAlignment.start,
              children: [ Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration( color: kPrimarySoft, borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [ Icon(Icons.psychology_outlined, color: kPrimaryDark), SizedBox(width: 10),
                      Expanded(
                        child: Text( 'LifeLink\'s ML model uses these details to rank donors by how likely they are to respond. This is not a medical screening.',
                            style: TextStyle(fontSize: 13, color: kInk)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const FieldLabel('Age (years)'),
                TextFormField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: fieldDecoration(
                      hint: 'e.g. 25', icon: Icons.cake_outlined),
                  validator: (v) => _number(v, 16, 100, 'Age'),
                ),
                const SizedBox(height: 16),
                const FieldLabel('Weight (kg)'),
                TextFormField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: fieldDecoration( hint: 'e.g. 68', icon: Icons.monitor_weight_outlined),
                  validator: (v) => _number(v, 30, 250, 'Weight'),
                ),
                const SizedBox(height: 16),
                const FieldLabel('Hemoglobin (g/dL)'),
                TextFormField( controller: _hemoglobin,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: fieldDecoration( hint: 'e.g. 14.2', icon: Icons.water_drop_outlined),
                  validator: (v) => _number(v, 5, 22, 'Hemoglobin'),
                ),
                const SizedBox(height: 16),
                const FieldLabel('Days since your last donation'),
                TextFormField( controller: _days, keyboardType: TextInputType.number,
                  decoration: fieldDecoration( hint: 'e.g. 100 (use a large number if never)',
                      icon: Icons.event_outlined), validator: (v) => _number(v, 0, 20000, 'Days'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                PrimaryButton( label: 'Save Details', icon: Icons.save_outlined, loading: _saving, onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}