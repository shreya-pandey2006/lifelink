import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/city_search_field.dart';
import '../../widgets/ui.dart';

const _groupHints = {
  'A+': 'Eligible',
  'A-': 'Rare',
  'B+': 'Eligible',
  'B-': 'Rare',
  'AB+': 'Universal Rec.',
  'AB-': 'Crit. Rare',
  'O+': 'Universal',
  'O-': 'Universal',
};

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  int _currentStep = 0;

  // Step 1: Basic Email & Password
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  // Step 2: Role & Contact
  String _role = 'donor';
  final _phone = TextEditingController();
  String? _city;
  bool _cityError = false;

  // Step 3: Blood Group & Terms
  String? _bloodGroup;
  bool _agreed = false;
  bool _groupError = false;
  bool _termsError = false;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextFromStep1() {
    final ok = _formKeyStep1.currentState?.validate() ?? false;
    if (ok) {
      _goToStep(1);
    }
  }

  void _nextFromStep2() {
    final formOk = _formKeyStep2.currentState?.validate() ?? false;
    final cityOk = _city != null && _city!.trim().isNotEmpty;
    setState(() => _cityError = !cityOk);

    if (formOk && cityOk) {
      _goToStep(2);
    }
  }

  Future<void> _submit() async {
    final needsGroup = _role == 'donor' && _bloodGroup == null;
    setState(() {
      _groupError = needsGroup;
      _termsError = !_agreed;
    });

    if (needsGroup || !_agreed) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final cleanPhone = _phone.text.replaceAll(RegExp(r'[\s\-()]'), '');
    final phoneToSend =
        cleanPhone.startsWith('+') ? cleanPhone : '+91$cleanPhone';

    final error = await context.read<AuthProvider>().register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          phone: phoneToSend,
          city: _city!.trim(),
          role: _role,
          bloodGroup: _bloodGroup,
        );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _goToStep(_currentStep - 1);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: kInk, size: 20),
                  onPressed: () => _goToStep(_currentStep - 1),
                )
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: kInk, size: 22),
                  onPressed: () => context.go('/login'),
                ),
          title: Text(
            'Step ${_currentStep + 1} of 3',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: kMuted),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _stepProgress(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepProgress() {
    return Column(
      children: [
        Row(
          children: [
            _StepPill(
              number: 1,
              title: 'Account',
              state: _currentStep == 0
                  ? _PillState.active
                  : (_currentStep > 0
                      ? _PillState.completed
                      : _PillState.inactive),
            ),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color:
                    _currentStep >= 1 ? kPrimaryDark : const Color(0xFFE6E1E8),
              ),
            ),
            _StepPill(
              number: 2,
              title: 'Role & Phone',
              state: _currentStep == 1
                  ? _PillState.active
                  : (_currentStep > 1
                      ? _PillState.completed
                      : _PillState.inactive),
            ),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color:
                    _currentStep >= 2 ? kPrimaryDark : const Color(0xFFE6E1E8),
              ),
            ),
            _StepPill(
              number: 3,
              title: 'Blood Group',
              state: _currentStep == 2
                  ? _PillState.active
                  : _PillState.inactive,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            minHeight: 4,
            backgroundColor: const Color(0xFFE6E1E8),
            color: kPrimaryDark,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SCREEN 1: Basic Email and Password related things
  // ===========================================================================
  Widget _buildStep1() {
    final strength = _strength(_password.text);
    const labels = ['Too short', 'Weak', 'Medium', 'Strong', 'Very strong'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const BrandLogo(size: 52),
                  const SizedBox(height: 10),
                  const Pill('FAST-RESPONSE NETWORK'),
                  const SizedBox(height: 10),
                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter your basic credentials to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const FieldLabel('Full Legal Name'),
            TextFormField(
              controller: _name,
              decoration: fieldDecoration(
                hint: 'e.g. Elena Rostova',
                icon: Icons.person_outline,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your full name';
                if (v.trim().length < 2) return 'Name must be at least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const FieldLabel('Email Address'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: fieldDecoration(
                hint: 'elena.donor@lifelink.org',
                icon: Icons.mail_outline,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email address';
                final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
                return null;
              },
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
                    color: kMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
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
                Text(
                  labels[strength],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kPrimaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const FieldLabel('Confirm Password'),
            TextFormField(
              controller: _confirm,
              obscureText: _obscureConfirm,
              decoration: fieldDecoration(
                hint: 'Re-enter your password',
                icon: Icons.lock_reset_outlined,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: kMuted,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v != _password.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Continue to Role & Contact',
              icon: Icons.arrow_forward_rounded,
              onPressed: _nextFromStep1,
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
                            fontWeight: FontWeight.w800, color: kPrimaryDark)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 2: Role like donor or requester and phone no.
  // ===========================================================================
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: _formKeyStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Role',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kInk,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose whether you want to save lives or request emergency blood',
              style: TextStyle(color: kMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    selected: _role == 'donor',
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Blood Donor',
                    subtitle: 'Ready to save lives & receive alerts',
                    tag: 'High Demand',
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
                    tag: 'Verified Access',
                    onTap: () => setState(() => _role = 'requester'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const FieldLabel('Mobile Phone'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EEF3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sms_outlined, size: 12, color: kPrimaryDark),
                      SizedBox(width: 4),
                      Text('SMS Alerts',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryDark)),
                    ],
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: fieldDecoration(
                hint: '98765 43210',
                icon: Icons.phone_outlined,
                prefixText: '+91  ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your phone number';
                final clean = v.replaceAll(RegExp(r'[\s\-()]'), '');
                if (clean.length < 10) return 'Enter a valid 10-digit phone number';
                return null;
              },
            ),
            const SizedBox(height: 18),
            const FieldLabel('Dispatch Region / City'),
            CitySearchField(
              initialValue: _city,
              hintText: 'Search or enter your city (e.g. Delhi, Pune, Kolkata)',
              icon: Icons.location_on_outlined,
              onChanged: (v) => setState(() {
                _city = v;
                _cityError = false;
              }),
            ),
            if (_cityError) ...[
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('Please select or enter your city',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 30),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _goToStep(0),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(54, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFFEDE7EA)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: kInk),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Continue to Blood Info',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _nextFromStep2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 3: Blood group related information
  // ===========================================================================
  Widget _buildStep3() {
    final isDonor = _role == 'donor';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDonor ? 'Select Your Blood Group' : 'Blood Profile (Optional)',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isDonor
                ? 'Crucial for matching you immediately to life-threatening emergencies'
                : 'Choose your personal blood group or leave open to request for patients',
            style: const TextStyle(color: kMuted, fontSize: 13.5),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _groupError ? Colors.red : kPrimaryDark,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop_outlined,
                            color: kPrimaryDark, size: 20),
                        SizedBox(width: 6),
                        Text('Blood Group',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: kInk)),
                      ],
                    ),
                    Pill(
                      isDonor ? 'CRITICAL FOR DONORS' : 'OPTIONAL FOR REQUESTER',
                      background: isDonor ? kPrimaryDark : const Color(0xFFF1EEF3),
                      foreground: isDonor ? Colors.white : kMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isDonor
                      ? 'Essential for urgent automated patient cross-matching.'
                      : 'You can create requests for any blood group regardless of your personal group.',
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.95,
                  children: kBloodGroups.map((g) {
                    final on = g == _bloodGroup;
                    final hint = _groupHints[g] ?? '';
                    return GestureDetector(
                      onTap: () => setState(() {
                        _bloodGroup = g;
                        _groupError = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: on ? kPrimaryDark : const Color(0xFFF4F1F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: on ? kPrimaryDark : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              g,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: on ? Colors.white : kInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: on ? Colors.white70 : kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_bloodGroup != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: kPrimaryDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Compatible with: ${kDonatesTo[_bloodGroup]?.join(', ') ?? '-'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_groupError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Please select your blood group to register as a donor',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
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
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'I agree to the Terms of Service and verified Medical Privacy Policy for emergency triage.',
                    style: TextStyle(fontSize: 12.5, color: kInk),
                  ),
                ),
              ),
            ],
          ),
          if (_termsError)
            const Padding(
              padding: EdgeInsets.only(left: 12, top: 2),
              child: Text(
                'Please accept the terms to complete registration',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _goToStep(1),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(54, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: Color(0xFFEDE7EA)),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: kInk),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Create Account',
                  icon: Icons.check_circle_outline,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _PillState { active, completed, inactive }

class _StepPill extends StatelessWidget {
  final int number;
  final String title;
  final _PillState state;

  const _StepPill({
    required this.number,
    required this.title,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = state == _PillState.active;
    final isDone = state == _PillState.completed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isActive || isDone)
                ? kPrimaryDark
                : const Color(0xFFF1EEF3),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : kMuted,
                  ),
                ),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? kPrimaryDark : kMuted,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
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
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kPrimaryDark.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      selected ? kPrimaryDark : const Color(0xFFF1EEF3),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected ? Colors.white : kMuted,
                  ),
                ),
                if (selected)
                  const Pill(
                    'Active',
                    background: kPrimaryDark,
                    foreground: Colors.white,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kInk,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, color: kMuted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  selected ? Icons.bolt : Icons.verified_outlined,
                  size: 13,
                  color: selected ? kPrimaryDark : kMuted,
                ),
                const SizedBox(width: 3),
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? kPrimaryDark : kMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}