import 'package:flutter/material.dart';

import '../app/care_scope.dart';
import '../core/navigation.dart';
import '../widgets/app_scaffold.dart';

class AdminCreateStaffScreen extends StatefulWidget {
  const AdminCreateStaffScreen({super.key});

  @override
  State<AdminCreateStaffScreen> createState() => _AdminCreateStaffScreenState();
}

class _AdminCreateStaffScreenState extends State<AdminCreateStaffScreen> {
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final positionController = TextEditingController(
    text: 'Disability Support Worker',
  );
  bool obscurePassword = true;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    positionController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final controller = CareScope.of(context);
    try {
      final staff = await controller.createStaffAccount(
        fullName: fullNameController.text,
        email: emailController.text,
        password: passwordController.text,
        position: positionController.text,
      );
      if (!mounted) return;
      showSnack(context, '${staff.email} can now log in as staff.');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      showSnack(context, controller.error ?? 'Could not create staff login.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    return AppScaffold(
      title: 'Create staff login',
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff credentials',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set up secure access for a new care team member.',
                      style: TextStyle(color: Color(0xFF536E7A)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: fullNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge_outlined),
                        labelText: 'Full name',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.mail_outline),
                        labelText: 'Staff email',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email is required';
                        if (!email.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        labelText: 'Temporary password',
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final password = value ?? '';
                        if (password.isEmpty) return 'Password is required';
                        if (password.length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: positionController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.work_outline),
                        labelText: 'Position',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.isBusy ? null : submit,
              icon: controller.isBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Create staff login'),
            ),
          ],
        ),
      ),
    );
  }
}
