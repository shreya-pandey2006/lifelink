import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _asDonor = true;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true;  _error = null; });
    final error = await context.read<AuthProvider>().login(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form( key: _formKey,
              child: Column(
                children: [
                  const BrandLogo(size: 84), const SizedBox(height: 14),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('LifeLink', style: TextStyle( fontSize: 30, fontWeight: FontWeight.w800, color: kInk)),
                      SizedBox(width: 6), CircleAvatar(radius: 4, backgroundColor: kPrimary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Every Drop Connects a Life.', style: TextStyle(fontSize: 15, color: kMuted)),
                  const SizedBox(height: 12),
                  const Pill('SECURE SIGN-IN', background: Color(0xFFF1EEF3), foreground: kMuted),
                  const SizedBox(height: 20),
                  _RoleToggle( asDonor: _asDonor, onChanged: (v) => setState(() => _asDonor = v) ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: kPrimarySoft, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.volunteer_activism_outlined,
                                  color: kPrimaryDark),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text( _asDonor
                                      ? 'Welcome back, lifesaver. Sign in to view urgent nearby requests.'
                                      : 'Welcome back. Sign in to post and track urgent blood requests.',
                                  style: const TextStyle(fontSize: 13, color: kInk),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const FieldLabel('Email Address', trailing: 'Hospital or Personal'),
                        TextFormField(
                          controller: _email, keyboardType: TextInputType.emailAddress,
                          decoration: fieldDecoration( hint: 'name@example.com',icon: Icons.mail_outline),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Password',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
                            GestureDetector(
                              onTap: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text( 'Password reset is not available in this demo.'))),
                              child: const Text('Forgot password?',
                                  style: TextStyle(fontSize: 13,fontWeight: FontWeight.w700, color: kPrimaryDark)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField( controller: _password, obscureText: _obscure,
                          decoration: fieldDecoration( hint: 'Enter your password', icon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon( _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: kMuted),
                              onPressed: () =>  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)  ? 'At least 6 characters' : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 20),
                        PrimaryButton( label: 'Login to LifeLink', icon: Icons.arrow_forward, loading: _loading, onPressed: _submit ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap( alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: kInk)),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: const Text('Register as Donor or Requester',
                            style: TextStyle( fontWeight: FontWeight.w800, color: kPrimaryDark)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  final bool asDonor;
  final ValueChanged<bool> onChanged;
  const _RoleToggle({required this.asDonor, required this.onChanged});
  Widget _segment(String label, bool selected, VoidCallback onTap, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: selected ? const [BoxShadow(color: Color(0x14000000), blurRadius: 8)]  : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? kPrimaryDark : kMuted),
              const SizedBox(width: 6),
              Text(label,
              style: TextStyle( fontWeight: FontWeight.w700, color: selected ? kPrimaryDark : kMuted)),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration( color: const Color(0xFFEFEBF0), borderRadius: BorderRadius.circular(34)),
      child: Row(
        children: [
          _segment('Donor', asDonor, () => onChanged(true), Icons.water_drop),
          _segment('Hospital / Requester', !asDonor, () => onChanged(false),
              Icons.local_hospital_outlined),
        ],
      ),
    );
  }
}