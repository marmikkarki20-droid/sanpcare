import 'package:flutter/material.dart';

import '../app/care_scope.dart';
import '../core/navigation.dart';
import '../widgets/brand_logo.dart';
import 'admin_dashboard_screen.dart';
import 'staff_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final controller = CareScope.of(context);
    try {
      await controller.signIn(emailController.text, passwordController.text);
      if (!mounted) return;
      final destination = controller.isAdmin
          ? const AdminDashboardScreen()
          : const StaffDashboardScreen();
      await Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
    } catch (_) {
      if (!mounted) return;
      showSnack(context, controller.error ?? 'Invalid email or password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 780;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF4F6), Color(0xFFF7FAFB), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1040 : 440),
                child: isWide
                    ? Row(
                        children: [
                          const Expanded(flex: 6, child: _LoginBrandPanel()),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 5,
                            child: _LoginCard(
                              formKey: formKey,
                              emailController: emailController,
                              passwordController: passwordController,
                              obscurePassword: obscurePassword,
                              isBusy: controller.isBusy,
                              onTogglePassword: () => setState(
                                () => obscurePassword = !obscurePassword,
                              ),
                              onSubmit: submit,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: CareSnapWordmark()),
                          const SizedBox(height: 28),
                          _LoginCard(
                            formKey: formKey,
                            emailController: emailController,
                            passwordController: passwordController,
                            obscurePassword: obscurePassword,
                            isBusy: controller.isBusy,
                            onTogglePassword: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                            onSubmit: submit,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 520),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12313D), Color(0xFF0D5963)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24102B38),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CareSnapWordmark(light: true),
          const SizedBox(height: 130),
          const _PortalPreviewCard(),
          const SizedBox(height: 28),
          const Text(
            'Connected care, confidently coordinated.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 37,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'A secure workspace for support workers, clinical notes, incident follow-up, and care coordination.',
            style: TextStyle(
              color: Color(0xFFC7DDE4),
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LoginTrustPill(
                icon: Icons.verified_user_outlined,
                label: 'GPS verified',
              ),
              _LoginTrustPill(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Care records',
              ),
              _LoginTrustPill(
                icon: Icons.groups_2_outlined,
                label: 'Team oversight',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortalPreviewCard extends StatelessWidget {
  const _PortalPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Today\'s care view',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _PreviewStatus(label: 'On track'),
            ],
          ),
          SizedBox(height: 16),
          _PreviewLine(label: 'Shift coverage', value: '7:00 AM - 3:00 PM'),
          SizedBox(height: 10),
          _PreviewLine(label: 'Priority follow-up', value: '1 open item'),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PreviewStatus extends StatelessWidget {
  const _PreviewStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1A73A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF12313D),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoginTrustPill extends StatelessWidget {
  const _LoginTrustPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isBusy,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isBusy;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shadowColor: const Color(0x14102B38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDCE8EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AutofillGroup(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF12313D),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to access the staff or administration portal.',
                  style: TextStyle(
                    color: Color(0xFF607783),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDCE8EC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_person_outlined,
                        size: 20,
                        color: Color(0xFF087C89),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Secure portal access',
                          style: TextStyle(
                            color: Color(0xFF12313D),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline),
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Email is required';
                    if (!email.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSubmit(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: onTogglePassword,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Password is required'
                      : null,
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: isBusy ? null : onSubmit,
                  icon: isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
