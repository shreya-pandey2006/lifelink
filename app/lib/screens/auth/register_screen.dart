import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String _role = 'donor';
  String? _city;
  String? _bloodGroup;
  bool _agreed = false;
  bool _obscure = true;
  bool _groupError = false;
  bool _termsError = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Rebuild the strength bars while the user types.
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  int _strength(String p) {
    var s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[0-9]').hasMatch(p) && RegExp(r'[A-Za-z]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p) ||
        (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p))) {
      s++;
    }
    return s;
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    final needsGroup = _role == 'donor' && _bloodGroup == null;
    setState(() {
      _groupError = needsGroup;
      _termsError = !_agreed;
    });
    if (!formOk || needsGroup || !_agreed) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await context.read<AuthProvider>().register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          phone: _phone.text,
          city: _city!,
          role: _role,
          bloodGroup: _role == 'donor' ? _bloodGroup : null,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strength = _strength(_password.text);
    const labels = ['Too short', 'Weak', 'Medium', 'Strong', 'Very strong'];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const BrandLogo(size: 56),
                      const SizedBox(height: 12),
                      const Pill('FAST-RESPONSE NETWORK'),
                      const SizedBox(height: 12),
                      const Text('Create Your Account',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: kInk)),
                      const SizedBox(height: 6),
                      const Text(
                        'Join our donor and emergency network',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kMuted, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text('SELECT YOUR ROLE',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: kPrimaryDark)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        selected: _role == 'donor',
                        icon: Icons.volunteer_activism_outlined,
                        title: 'Blood Donor',
                        subtitle: 'Ready to save lives & receive alerts',
                        onTap: () => setState(() => _role = 'donor'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        selected: _role == 'requester',
                        icon: Icons.local_hospital_outlined,
                        title: 'Blood Requester',
                        subtitle: 'Find matching donors urgently',
                        onTap: () => setState(() => _role = 'requester'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const FieldLabel('Full Name'),
                TextFormField(
                  controller: _name,
                  decoration: fieldDecoration(
                      hint: 'e.g. Elena Rostova', icon: Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
                const FieldLabel('Email Address'),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: fieldDecoration(
                      hint: 'name@example.com', icon: Icons.mail_outline),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                const FieldLabel('Mobile Phone'),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: fieldDecoration(
                      hint: '98765 43210',
                      icon: Icons.phone_outlined,
                      prefixText: '+91  '),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Enter a valid phone number'
                      : null,
                ),
                const SizedBox(height: 16),
                const FieldLabel('Password'),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: fieldDecoration(
                    hint: 'At least 6 characters',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'At least 6 characters'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: i < strength
                                ? kPrimaryDark
                                : const Color(0xFFE6E1E8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(labels[strength],
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kPrimaryDark)),
                  ],
                ),
                const SizedBox(height: 16),
                const FieldLabel('Confirm Password'),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: fieldDecoration(
                      hint: 'Re-enter your password',
                      icon: Icons.lock_reset_outlined),
                  validator: (v) =>
                      v != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 16),
                const FieldLabel('City'),
                DropdownButtonFormField<String>(
                  initialValue: _city,
                  decoration: fieldDecoration(
                      hint: 'Select your city',
                      icon: Icons.location_on_outlined),
                  items: kCities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _city = v),
                  validator: (v) => v == null ? 'Select your city' : null,
                ),
                if (_role == 'donor') ...[
                  const SizedBox(height: 20),
                  _BloodGroupPicker(
                    selected: _bloodGroup,
                    showError: _groupError,
                    onSelect: (g) => setState(() {
                      _bloodGroup = g;
                      _groupError = false;
                    }),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      activeColor: kPrimaryDark,
                      onChanged: (v) => setState(() {
                        _agreed = v ?? false;
                        _termsError = false;
                      }),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy for this demo app.',
                          style: TextStyle(fontSize: 13, color: kInk),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_termsError)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 2),
                    child: Text('Please accept to continue',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Create Account',
                  icon: Icons.person_add_alt_1_outlined,
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                          style: TextStyle(color: kInk)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text('Log in',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: kPrimaryDark)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? kPrimaryDark : const Color(0xFFEDE7EA),
              width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: selected ? kPrimaryDark : const Color(0xFFF1EEF3),
                  child: Icon(icon,
                      size: 20, color: selected ? Colors.white : kMuted),
                ),
                if (selected)
                  const Pill('Active',
                      background: kPrimaryDark, foreground: Colors.white),
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: kMuted)),
          ],
        ),
      ),
    );
  }
}

class _BloodGroupPicker extends StatelessWidget {
  final String? selected;
  final bool showError;
  final ValueChanged<String> onSelect;

  const _BloodGroupPicker({
    required this.selected,
    required this.showError,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: showError ? Colors.red : kPrimaryDark, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop_outlined, color: kPrimaryDark, size: 20),
                  SizedBox(width: 6),
                  Text('Blood Group',
                      style: TextStyle(fontWeight: FontWeight.w800, color: kInk)),
                ],
              ),
              Pill('REQUIRED FOR DONORS',
                  background: kPrimaryDark, foreground: Colors.white),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Used to match you with patients who need your group.',
              style: TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.35,
            children: kBloodGroups.map((g) {
              final on = g == selected;
              return GestureDetector(
                onTap: () => onSelect(g),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? kPrimaryDark : const Color(0xFFF1EEF3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(g,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: on ? Colors.white : kInk)),
                ),
              );
            }).toList(),
          ),
          if (selected != null) ...[
            const SizedBox(height: 12),
            Text('Can donate to: ${kDonatesTo[selected]!.join(', ')}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryDark)),
          ],
          if (showError) ...[
            const SizedBox(height: 8),
            const Text('Select your blood group',
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}